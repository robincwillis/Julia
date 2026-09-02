//
//  ChefChatView.swift
//  Julia
//

import SwiftUI
import PhotosUI
import FoundationModels

// MARK: - Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var text: String

    enum Role { case user, assistant }

    var attributedText: AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
}

// MARK: - Chat View

struct ChefChatView: View {
    var recipe: Recipe? = nil
    @Binding var selectedImage: UIImage?
    @Binding var selectedText: String?
    @Binding var extractedRecipeData: RecipeData?

    init(
        recipe: Recipe? = nil,
        selectedImage: Binding<UIImage?> = .constant(nil),
        selectedText: Binding<String?> = .constant(nil),
        extractedRecipeData: Binding<RecipeData?> = .constant(nil)
    ) {
        self.recipe = recipe
        self._selectedImage = selectedImage
        self._selectedText = selectedText
        self._extractedRecipeData = extractedRecipeData
    }

    // Chat state
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isStreaming = false
    @State private var session: LanguageModelSession? = nil
    @State private var isAvailable = true
    @State private var streamingTask: Task<Void, Never>? = nil

    // FAB state
    @State private var isFABExpanded = false
    @State private var isFABLoading = false

    // Local URL import processor (handles URL → ProcessingResults within this view)
    @State private var localRecipeProcessor = RecipeProcessor()
    @State private var localExtractedData: RecipeData? = nil

    // Import sheet state
    @State private var showScanInstruction = false
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var showRecipeURLImport = false
    @State private var showRecipeTextImport = false
    @State private var photosPickerItem: PhotosPickerItem?

    // First-use gates
    @AppStorage("hasSeenJuliaSuggestions") private var hasSeenSuggestions = false
    @AppStorage("hasSeenScanInstruction") private var hasSeenScanInstruction = false

    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // MARK: - Computed

    private var showImportOptions: Bool { recipe == nil }
    private var hasMessages: Bool { !messages.isEmpty }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if hasMessages {
                    messageList
                    if showImportOptions {
                        importChipRow
                    }
                } else {
                    emptyState
                }

                inputBar
            }

            // FAB items overlay (Dot lives in inputBar; items float above it)
            if showImportOptions {
                importFABItems
            }
        }
        .sheet(isPresented: $showScanInstruction) {
            ScanInstructionView(
                onOpenCamera: {
                    hasSeenScanInstruction = true
                    showScanInstruction = false
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(400))
                        showCamera = true
                    }
                },
                onDismiss: { showScanInstruction = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showCamera) {
            Camera(image: $selectedImage, isPresented: $showCamera) { image in
                selectedImage = image
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photosPickerItem, matching: .images)
        .sheet(isPresented: $showRecipeURLImport, onDismiss: {
            if let data = localExtractedData {
                localRecipeProcessor.processData(data, immediatePresentation: true)
            }
        }) {
            RecipeURLImportView(extractedRecipeData: $localExtractedData)
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showRecipeTextImport) {
            RecipeTextImportView(recipeText: $selectedText)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $localRecipeProcessor.processingState.showResultsSheet, onDismiss: {
            localExtractedData = nil
        }) {
            ProcessingResults(
                processingState: localRecipeProcessor.processingState,
                recipeData: $localRecipeProcessor.recipeData,
                saveRecipe: localRecipeProcessor.saveRecipe
            )
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
        }
        .onChange(of: photosPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { selectedImage = image }
                }
            }
        }
        .onChange(of: inputText) { _, newText in
            if !newText.isEmpty && isFABExpanded {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isFABExpanded = false
                }
            }
        }
        .onChange(of: isInputFocused) { _, focused in
            if focused && isFABExpanded {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isFABExpanded = false
                }
            }
        }
        .onChange(of: selectedImage) { _, v in if v != nil { dismiss() } }
        .onChange(of: selectedText) { _, v in if v != nil { dismiss() } }
        .onChange(of: extractedRecipeData) { _, v in if v != nil { dismiss() } }
        .onAppear {
            setupSession()
            localRecipeProcessor.setModelContext(context)
            if showImportOptions {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(200))
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isFABExpanded = true
                    }
                }
            }
        }
        .onDisappear { streamingTask?.cancel() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.app.primary)
                    .frame(width: 30, height: 30)
                    .background(.regularMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(capabilityDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 32)

            if isAvailable && !hasSeenSuggestions {
                Spacer(minLength: 20)
                firstUseSuggestions
            }

            Spacer()
            // Reserve space so content isn't behind the FAB
            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var capabilityDescription: String {
        isAvailable
            ? "Ask me anything about cooking, or use the menu to import a recipe."
            : "Import a recipe using the menu below, or enable Apple Intelligence in Settings to unlock chat."
    }

    // MARK: - First-Use Suggestions

    private var firstUseSuggestions: some View {
        VStack(alignment: .center, spacing: 8) {
            ForEach([
                "Add pasta carbonara ingredients",
                "Create a chicken stir fry recipe",
                "What temp for medium-rare steak?"
            ], id: \.self) { text in
                Button {
                    hasSeenSuggestions = true
                    inputText = text
                    sendMessage()
                } label: {
                    Text(text)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(.fill.tertiary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 40)
    }

    // MARK: - Import FAB Items (Dot trigger lives in inputBar)

    private var importFABItems: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 14) {
                    fabItem(icon: "text.quote", label: "Text", delay: 0.15) { showRecipeTextImport = true }
                    fabItem(icon: "globe", label: "Website", delay: 0.10) { showRecipeURLImport = true }
                    fabItem(icon: "photo.on.rectangle", label: "Photos", delay: 0.05) { showPhotosPicker = true }
                    fabItem(icon: "camera.fill", label: "Camera", delay: 0.0) { openCamera() }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 84)
            }
        }
    }

    private func fabItem(icon: String, label: String, delay: Double, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(Color.app.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .contentShape(Rectangle())

            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.app.primary)
                .frame(width: 44, height: 44)
                .background(.fill.secondary, in: Circle())
        }
        .opacity(isFABExpanded ? 1 : 0)
        .offset(x: isFABExpanded ? 0 : 32)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.75)
            .delay(isFABExpanded ? delay : 0),
            value: isFABExpanded
        )
        .allowsHitTesting(isFABExpanded)
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isFABExpanded = false
            }
            action()
        }
    }

    // MARK: - Import Chip Row (above input when messages exist)

    private var importChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                importChip(icon: "camera", label: "Camera", action: { openCamera() })
                importChip(icon: "photo.on.rectangle", label: "Photos", action: { showPhotosPicker = true })
                importChip(icon: "globe", label: "Website", action: { showRecipeURLImport = true })
                importChip(icon: "text.quote", label: "Text", action: { showRecipeTextImport = true })
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func importChip(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(.subheadline)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.fill.secondary, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if let recipe, !hasMessages {
                        recipeContextBanner(recipe)
                    }
                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            isStreaming: isStreaming && message.id == messages.last?.id
                        )
                    }
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .onChange(of: messages.last?.text) {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Recipe Context Banner

    private func recipeContextBanner(_ recipe: Recipe) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "book.closed")
                .font(.caption)
            Text(recipe.title)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.fill.tertiary, in: Capsule())
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .center, spacing: 10) {
            TextField(
                isAvailable ? "Message Julia…" : "Requires Apple Intelligence",
                text: $inputText,
                axis: .vertical
            )
            .focused($isInputFocused)
            .lineLimit(1...5)
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(.fill.secondary, in: RoundedRectangle(cornerRadius: 30))
            .frame(minHeight: 60)
            .disabled(!isAvailable)

            // Single CTA: Dot (import) when idle, arrow when typing, stop when streaming
            ZStack {
                if isStreaming {
                    Button(action: stopStreaming) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.app.primary)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                } else if showImportOptions && inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Dot(isLoading: $isFABLoading, isExpanded: $isFABExpanded)
                        .onTapGesture {
                            guard !isFABLoading else { return }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                isFABExpanded.toggle()
                            }
                        }
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                } else {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(canSend ? Color.app.primary : Color.secondary.opacity(0.3))
                            .shadow(color: canSend ? Color.app.primary.opacity(0.5) : .clear, radius: 8, x: 0, y: 3)
                            .shadow(color: canSend ? Color.app.primary.opacity(0.2) : .clear, radius: 16, x: 0, y: 5)
                    }
                    .disabled(!canSend)
                    .buttonStyle(.plain)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .frame(width: 60, height: 60)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: inputText.isEmpty)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isStreaming)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Logic

    private func openCamera() {
        if hasSeenScanInstruction {
            showCamera = true
        } else {
            showScanInstruction = true
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isAvailable
    }

    private func setupSession() {
        guard SystemLanguageModel.default.availability == .available else {
            isAvailable = false
            return
        }

        let baseInstructions = """
            You are Julia, a knowledgeable cooking assistant. Keep responses concise and direct. \
            Use the addToGroceryList tool when the user asks to add ingredients or build a shopping list. \
            Use the createRecipe tool when the user asks to create or generate a recipe. \
            DO NOT invent data not requested. Use specific numbers for temperatures, times, and ratios.
            """

        let tools: [any Tool] = [
            AddToGroceryListTool(context: context),
            CreateRecipeTool(context: context)
        ]

        if let recipe {
            session = LanguageModelSession(tools: tools) {
                "\(baseInstructions)\n\nContext: The user is viewing this recipe:\n\(buildRecipeContext(recipe))"
            }
        } else {
            session = LanguageModelSession(tools: tools) { baseInstructions }
        }
    }

    private func buildRecipeContext(_ recipe: Recipe) -> String {
        var lines: [String] = ["Recipe: \(recipe.title)"]

        if let servings = recipe.servings {
            lines.append("Servings: \(servings)")
        }

        let ingredients = recipe.ingredients.sorted { $0.position < $1.position }
        if !ingredients.isEmpty {
            lines.append("Ingredients:")
            for ing in ingredients {
                var parts: [String] = []
                if let qty = ing.quantity {
                    parts.append(formatQuantity(qty))
                }
                if let unit = ing.unit {
                    parts.append(unit.displayName)
                }
                parts.append(ing.name)
                if let comment = ing.comment, !comment.isEmpty {
                    parts.append("(\(comment))")
                }
                lines.append("- " + parts.joined(separator: " "))
            }
        }

        let steps = recipe.instructions.sorted { $0.position < $1.position }
        if !steps.isEmpty {
            lines.append("Instructions:")
            for (i, step) in steps.enumerated() {
                lines.append("\(i + 1). \(step.value)")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func formatQuantity(_ qty: Double) -> String {
        qty == qty.rounded() ? String(Int(qty)) : String(format: "%.2g", qty)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let session else { return }

        if !hasSeenSuggestions { hasSeenSuggestions = true }
        isInputFocused = false
        inputText = ""
        messages.append(ChatMessage(role: .user, text: text))
        messages.append(ChatMessage(role: .assistant, text: ""))
        let replyIndex = messages.count - 1
        isStreaming = true

        streamingTask = Task {
            do {
                let stream = session.streamResponse(to: text)
                for try await partial in stream {
                    messages[replyIndex].text = partial.content
                }
            } catch {
                messages[replyIndex].text = error.localizedDescription
            }
            isStreaming = false
        }
    }

    private func stopStreaming() {
        streamingTask?.cancel()
        isStreaming = false
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    let isStreaming: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.role == .user { Spacer(minLength: 48) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 2) {
                if message.role == .assistant && message.text.isEmpty && isStreaming {
                    ChatTypingDot()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.fill.secondary, in: BubbleShape(role: message.role))
                } else {
                    Text(message.role == .assistant ? message.attributedText : AttributedString(message.text))
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubbleBackground, in: BubbleShape(role: message.role))
                        .foregroundStyle(message.role == .user ? .white : .primary)
                }
            }

            if message.role == .assistant { Spacer(minLength: 48) }
        }
    }

    private var bubbleBackground: some ShapeStyle {
        message.role == .user ? AnyShapeStyle(.blue) : AnyShapeStyle(.fill.secondary)
    }
}

// MARK: - Supporting Views

private struct BubbleShape: Shape {
    let role: ChatMessage.Role

    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: 18)
    }
}

private struct ChatTypingDot: View {
    @State private var isLoading = false
    @State private var isExpanded = false

    var body: some View {
        Dot(isLoading: $isLoading, isExpanded: $isExpanded)
            .scaleEffect(0.45)
            .frame(width: 27, height: 27)
            .onAppear { isLoading = true }
            .onDisappear { isLoading = false }
    }
}

#Preview {
    ChefChatView()
}
