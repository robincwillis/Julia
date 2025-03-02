//
//  RecipeProcessingView.swift
//  Julia
//
//  Created by Claude on 3/2/25.
//

import SwiftUI
import SwiftData
import Vision

struct RecipeProcessingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @StateObject private var processingState = RecipeProcessingState()
    @State private var title: String = ""
    @State private var ingredients: [String] = []
    @State private var instructions: [String] = []
    @State private var classifier = RecipeTextClassifier()
    @State private var isClassifying = false
    @State private var showingRawText = false
    
    init(image: UIImage) {
        // Set the image in the processing state
        _processingState = StateObject(wrappedValue: {
            let state = RecipeProcessingState()
            state.image = image
            state.processingStage = .processing
            return state
        }())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if processingState.processingStage == .processing && processingState.recognizedText.isEmpty {
                        processingView
                    } else if !processingState.recognizedText.isEmpty {
                        resultView
                    }
                }
                
                if showingRawText {
                    rawTextDebugView
                        .transition(.move(edge: .bottom))
                }
            }
            .onAppear {
                if processingState.processingStage == .processing && processingState.recognizedText.isEmpty {
                    processImage()
                }
            }
            .navigationTitle("Process Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if !title.isEmpty || !ingredients.isEmpty || !instructions.isEmpty {
                        Button("Save") {
                            saveRecipe()
                        }
                    } else if !processingState.recognizedText.isEmpty && !isClassifying {
                        Button("Classify") {
                            classifyText()
                        }
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    if processingState.recognizedText.isNotEmpty {
                        Button(showingRawText ? "Hide Raw Text" : "Show Raw Text") {
                            withAnimation {
                                showingRawText.toggle()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            if let image = processingState.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
            }
            
            ProgressView("Extracting text from image...")
                .padding()
        }
    }
    
    private var resultView: some View {
        VStack {
            if isClassifying {
                ProgressView("Classifying recipe text...")
                    .padding()
            } else {
                TabView(selection: $processingState.selectedTab) {
                    // Tab 1: Classification results
                    VStack {
                        List {
                            Section("Recipe Title") {
                                TextField("Title", text: $title)
                                    .font(.headline)
                            }
                            
                            Section("Ingredients") {
                                ForEach(0..<ingredients.count, id: \.self) { index in
                                    TextField("Ingredient \(index + 1)", text: Binding(
                                        get: { ingredients[index] },
                                        set: { ingredients[index] = $0 }
                                    ))
                                }
                                
                                Button("Add Ingredient") {
                                    ingredients.append("")
                                }
                            }
                            
                            Section("Instructions") {
                                ForEach(0..<instructions.count, id: \.self) { index in
                                    TextField("Step \(index + 1)", text: Binding(
                                        get: { instructions[index] },
                                        set: { instructions[index] = $0 }
                                    ))
                                }
                                
                                Button("Add Instruction") {
                                    instructions.append("")
                                }
                            }
                        }
                    }
                    .tabItem {
                        Label("Recipe", systemImage: "fork.knife")
                    }
                    .tag(0)
                    
                    // Tab 2: Edit raw text
                    VStack {
                        List {
                            Section("Edit Recognition") {
                                ForEach(0..<processingState.recognizedText.count, id: \.self) { index in
                                    TextField("Line \(index + 1)", text: Binding(
                                        get: { processingState.recognizedText[index] },
                                        set: { processingState.recognizedText[index] = $0 }
                                    ))
                                }
                            }
                        }
                        
                        Button("Re-classify Text") {
                            classifyText()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .tabItem {
                        Label("Edit Text", systemImage: "text.quote")
                    }
                    .tag(1)
                }
            }
        }
    }
    
    private var rawTextDebugView: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        showingRawText = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(processingState.recognizedText, id: \.self) { line in
                        Text(line)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 300)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding()
    }
    
    private func processImage() {
        guard let image = processingState.image else {
            return
        }
        
        // Start OCR processing
        Task {
            let recognizedText = await TextRecognitionService.shared.recognizeText(from: image)
            await MainActor.run {
                processingState.recognizedText = recognizedText
                processingState.processingStage = .completed
                
                // Auto-classify if we have text
                if !recognizedText.isEmpty {
                    classifyText()
                }
            }
        }
    }
    
    private func classifyText() {
        // Skip empty lines
        let filteredText = processingState.recognizedText.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        isClassifying = true
        
        // Process on background thread
        Task {
            let processed = await classifier.processRecipeTextAsync(filteredText)
            
            // Update UI on main thread
            await MainActor.run {
                title = processed.title
                ingredients = processed.ingredients
                instructions = processed.instructions
                isClassifying = false
            }
        }
    }
    
    private func saveRecipe() {
        let recipe = Recipe(
            title: title,
            ingredients: [],
            instructions: instructions,
            rawText: processingState.recognizedText
        )
        
        // Add ingredients
        for ingredientText in ingredients {
            if let ingredient = IngredientParser.fromString(input: ingredientText, location: .recipe) {
                recipe.ingredients.append(ingredient)
            }
        }
        
        // Save to context
        context.insert(recipe)
        
        dismiss()
    }
}

// Make classifier work async
extension RecipeTextClassifier {
    func processRecipeTextAsync(_ text: [String]) async -> (title: String, ingredients: [String], instructions: [String]) {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let result = self.processRecipeText(text)
                continuation.resume(returning: result)
            }
        }
    }
}

// Helper extension
extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

#Preview {
    let image = UIImage(named: "julia") ?? UIImage()
    
    return RecipeProcessingView(image: image)
        .modelContainer(DataController.previewContainer)
}