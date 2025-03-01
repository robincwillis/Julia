//
//  ProcessOCRView.swift
//  Julia
//
//  Created by Claude on 3/1/25.
//

import SwiftUI
import SwiftData

struct ProcessOCRView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var rawText: [String]
    @State private var title: String = ""
    @State private var ingredients: [String] = []
    @State private var instructions: [String] = []
    @State private var classifier = RecipeTextClassifier()
    @State private var isClassifying = false
    @State private var showingPreview = false
    
    init(ocrText: [String]) {
        _rawText = State(initialValue: ocrText)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isClassifying {
                    ProgressView("Classifying recipe text...")
                        .padding()
                } else {
                    List {
                        Section("Recipe Text") {
                            ForEach(0..<rawText.count, id: \.self) { index in
                                TextField("Line \(index + 1)", text: Binding(
                                    get: { rawText[index] },
                                    set: { rawText[index] = $0 }
                                ))
                            }
                        }
                        
                        if !title.isEmpty || !ingredients.isEmpty || !instructions.isEmpty {
                            Section("Classification Results") {
                                if !title.isEmpty {
                                    Text("Title: \(title)")
                                        .font(.headline)
                                }
                                
                                if !ingredients.isEmpty {
                                    DisclosureGroup("Ingredients (\(ingredients.count))") {
                                        ForEach(ingredients, id: \.self) { ingredient in
                                            Text(ingredient)
                                        }
                                    }
                                }
                                
                                if !instructions.isEmpty {
                                    DisclosureGroup("Instructions (\(instructions.count))") {
                                        ForEach(instructions, id: \.self) { instruction in
                                            Text(instruction)
                                        }
                                    }
                                }
                            }
                        }
                    }
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
                    } else {
                        Button("Classify") {
                            classifyText()
                        }
                    }
                }
                
                if !title.isEmpty || !ingredients.isEmpty || !instructions.isEmpty {
                    ToolbarItem(placement: .secondaryAction) {
                        Button("Reset") {
                            title = ""
                            ingredients = []
                            instructions = []
                        }
                    }
                }
            }
        }
    }
    
    private func classifyText() {
        // Skip empty lines
        let filteredText = rawText.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        isClassifying = true
        
        // Process on background thread
        DispatchQueue.global().async {
            let processed = classifier.processRecipeText(filteredText)
            
            // Update UI on main thread
            DispatchQueue.main.async {
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
            rawText: rawText
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

#Preview {
    let sampleText = [
        "Classic Pancakes",
        "2 cups all-purpose flour",
        "2 tablespoons sugar",
        "1 teaspoon baking powder",
        "1/2 teaspoon salt",
        "2 eggs",
        "1 3/4 cups milk",
        "1/4 cup vegetable oil",
        "Mix dry ingredients in a large bowl.",
        "Beat eggs, milk and oil in another bowl.",
        "Stir wet ingredients into dry ingredients.",
        "Pour batter onto hot griddle.",
        "Flip when bubbles form on surface.",
        "Cook until golden brown."
    ]
    
    return ProcessOCRView(ocrText: sampleText)
        .modelContainer(DataController.previewContainer)
}