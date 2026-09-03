import SwiftUI

struct RecipeURLImportView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var extractedRecipeData: RecipeData?

    @State private var scraper = RecipeWebScraper()
    @State private var urlText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    @FocusState private var isUrlTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    if isLoading {
                        loadingContent
                    } else {
                        inputForm
                    }
                }
            }
            .background(Color.app.backgroundSecondary)
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                if !isLoading {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Import") { startImport() }
                            .foregroundStyle(urlText.isEmpty ? Color.app.primary.opacity(0.4) : Color.app.primary)
                            .disabled(urlText.isEmpty)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
        .onAppear {
            isUrlTextFieldFocused = true
        }
    }

    // MARK: - Subviews

    private var inputForm: some View {
        Form {
            Section(header: Text("Recipe URL")) {
                TextField("Enter Recipe URL to import", text: $urlText)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isUrlTextFieldFocused)
                    .onSubmit { isUrlTextFieldFocused = false }

                Button(action: startImport) {
                    Label("Import", systemImage: "sparkles")
                }
                .foregroundStyle(urlText.isEmpty ? Color.app.primary.opacity(0.4) : Color.app.primary)
                .disabled(urlText.isEmpty)
            }
        }
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack(spacing: 8) {
                    Spacer()
                    Button("Paste") {
                        if let clipboardString = UIPasteboard.general.string {
                            urlText = clipboardString
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.blue)
                    .clipShape(Capsule())
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            Loader(isLoading: .constant(true))

            if scraper.phase != .idle && scraper.phase != .done {
                Text(phaseLabel(for: scraper.phase))
                    .font(.headline)
                    .padding(.top, 6)
                    .transition(.opacity)
                    .id(scraper.phase) // forces re-transition on phase change
                    .animation(.easeInOut(duration: 0.3), value: scraper.phase)

                if !scraper.statusMessage.isEmpty {
                    Text(scraper.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: scraper.statusMessage)
                }
            }

            Button("Cancel") {
                scraper.cancel()
                isLoading = false
            }
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func phaseLabel(for phase: WebScrapePhase) -> String {
        switch phase {
        case .browser: return "Fetching page…"
        case .parsing: return "Reading recipe…"
        case .ai:      return "Parsing with AI…"
        default:       return ""
        }
    }

    // MARK: - Actions

    private func startImport() {
        guard !urlText.isEmpty else { return }
        isUrlTextFieldFocused = false
        isLoading = true

        Task {
            do {
                let recipeData = try await scraper.scrape(urlString: urlText)
                await MainActor.run {
                    extractedRecipeData = recipeData
                    isLoading = false
                    dismiss()
                }
            } catch is CancellationError {
                await MainActor.run { isLoading = false }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var extractedRecipeData: RecipeData?

        var body: some View {
            RecipeURLImportView(extractedRecipeData: $extractedRecipeData)
                .modelContainer(DataController.previewContainer)
        }
    }

    return PreviewWrapper()
}
