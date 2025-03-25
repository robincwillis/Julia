import SwiftUI
import SwiftData
import Vision
import Foundation

// Create a typealias for the result structure to avoid ambiguity
typealias ProcessingTextResult = TextReconstructorResult

struct RecipeProcessingView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  
  // Make this static so it can be used in property initializers
  static let confidenceThreshold: Double = 0.65
  
  @StateObject private var processingState = RecipeProcessingState()
  
  // Consolidate all state variables related to recipe data
  @State private var recipeData = RecipeData()
  @State private var isClassifying = false
  @State private var showDismissAlert = false
  
  // Centralize all recipe data in a single struct for easier management
  // TODO Move to Models
  struct RecipeData {
    var title: String = ""
    var ingredients: [String] = []
    var instructions: [String] = []
    var summary: [String] = []
    var timings: [String] = []
    var servings: [String] = []
    var reconstructedText = ProcessingTextResult(title: "", reconstructedLines: [], artifacts: [])
    var classifiedLines: [(String, RecipeLineType, Double)] = []
    var skippedLines: [(String, RecipeLineType, Double)] = []
    
    mutating func reset() {
      title = ""
      ingredients = []
      instructions = []
      summary = []
      timings = []
      servings = []
      reconstructedText = ProcessingTextResult(title: "", reconstructedLines: [], artifacts: [])
      classifiedLines = []
      skippedLines = []
    }
  }
  
  init(image: UIImage?, text: String?) {
    // Create and configure the processing state based on input
    _processingState = StateObject(wrappedValue: {
      let state = RecipeProcessingState()
      state.reset()
      
      if let image = image {
        state.image = image
        state.processingStage = .processing
      } else if let text = text {
        state.text = text
        state.processingStage = .processing
      } else {
        state.processingStage = .error
      }
      
      // Clear any saved processing results
      UserDefaults.standard.removeObject(forKey: "latestRecipeProcessingResults")
      return state
    }())
  }
  
  var body: some View {
    NavigationStack {
      VStack {
        switch processingState.processingStage {
        case .processing:
          if processingState.image != nil {
            ProcessingImage(image: processingState.image!, isClassifying: $isClassifying)
          } else if processingState.text != nil {
            ProcessingText(isClassifying: $isClassifying)
          }
          
        case .error:
          ProcessingError(processingState: processingState)
          
        case .completed, .notStarted:
          ProcessingResults(
            processingState: processingState,
            recipeData: $recipeData
          )
        }
      }
      .onAppear {
        startProcessing()
      }
      .onDisappear {
        UserDefaults.standard.removeObject(forKey: "latestRecipeProcessingResults")
        
        // Reset processing state
        processingState.reset()
        recipeData.reset()

      }
      .navigationTitle("Process Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .alert("Unsaved Recipe", isPresented: $showDismissAlert) {
        Button("Discard Changes", role: .destructive) {
          dismiss()
        }
        Button("Save Recipe", role: .none) {
          saveRecipe()
        }
        Button("Cancel", role: .cancel) { }
      } message: {
        Text("You have an unsaved recipe. What would you like to do?")
      }
      .toolbar {
        // Cancel with confirmation if needed
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            if !recipeData.title.isEmpty || !recipeData.ingredients.isEmpty || !recipeData.instructions.isEmpty {
              showDismissAlert = true
            } else {
              dismiss()
            }
          }
        }
        
        // Primary - Save
        ToolbarItem(placement: .primaryAction) {
          if !recipeData.title.isEmpty || !recipeData.ingredients.isEmpty || !recipeData.instructions.isEmpty {
            Button("Save") {
              saveRecipe()
            }
          }
        }
      }
    }
  }
  
  // Start the appropriate processing pipeline based on input
  private func startProcessing() {
    if processingState.processingStage == .processing && processingState.recognizedText.isEmpty {
      if let image = processingState.image {
        Task {
          await processImage(image)
        }
      } else if let text = processingState.text {
        Task {
          await processText(text)
        }
      } else {
        processingState.processingStage = .error
      }
    }
  }
  
  // Consistent async method for text processing
  private func processText(_ text: String) async {
    let recognizedText = text.components(separatedBy: .newlines)
    
    await MainActor.run {
      processingState.recognizedText = recognizedText
      processingState.processingStage = .completed
      
      if !recognizedText.isEmpty {
        Task {
          await classifyText(recognizedText)
        }
      }
    }
  }
  
  // Consistent async method for image processing
  private func processImage(_ image: UIImage) async {
    let recognizedText = await TextRecognitionService.shared.recognizeText(from: image)
    
    await MainActor.run {
      processingState.recognizedText = recognizedText
      
      if !recognizedText.isEmpty {
        processingState.processingStage = .completed
        recipeData.reset()
        
        Task {
          await classifyText(recognizedText)
        }
      } else {
        processingState.processingStage = .error
      }
    }
  }
  
  // Centralized async method for text classification
  private func classifyText(_ text: [String]) async {
    // Skip empty lines
    let filteredText = text.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    await MainActor.run {
      isClassifying = true
    }
    
    // Step 1: Reconstruct the text
    let reconstructed = await RecipeTextReconstructor.reconstructTextAsync(filteredText)
    
    // Step 2: Classify the reconstructed text
    let classifier = RecipeTextClassifier(confidenceThreshold: Self.confidenceThreshold)
    let classified = await classifier.processRecipeTextAsync(reconstructed.reconstructedLines)
    
    // Update UI on main thread
    await MainActor.run {
      recipeData.reconstructedText = reconstructed
      
      // Use title from reconstructor if available, otherwise use the one from classifier
      recipeData.title = !reconstructed.title.isEmpty ? reconstructed.title : classified.title
      recipeData.ingredients = classified.ingredients
      recipeData.instructions = classified.instructions
      recipeData.summary = classified.summary
      recipeData.timings = classified.timings
      recipeData.skippedLines = classified.skipped
      recipeData.classifiedLines = classified.classified
      
      isClassifying = false
    }
  }
  
  private func saveRecipe() {
    // Create a Recipe with all required fields
    let recipe = Recipe(
      id: UUID().uuidString,
      title: recipeData.title,
      summary: nil,
      ingredients: [],
      instructions: recipeData.instructions,
      sections: [],
      servings: nil,
      timings: [],
      notes: [],
      rawText: processingState.recognizedText,
      source: nil
    )
    
    // Add ingredients
    for ingredientText in recipeData.ingredients {
      if let ingredient = IngredientParser.fromString(input: ingredientText, location: .recipe) {
        recipe.ingredients.append(ingredient)
      }
    }
    
    // Save to context
    context.insert(recipe)
    
    // Remove from UserDefaults since we've saved properly
    UserDefaults.standard.removeObject(forKey: "latestRecipeProcessingResults")
    
    dismiss()
  }
}

// Add async methods to the service classes for consistent usage patterns
extension RecipeTextReconstructor {
  static func reconstructTextAsync(_ lines: [String]) async -> ProcessingTextResult {
    return await withCheckedContinuation { continuation in
      Task.detached {
        let result = reconstructText(from: lines)
        continuation.resume(returning: result)
      }
    }
  }
}

extension RecipeTextClassifier {
  func processRecipeTextAsync(_ text: [String]) async -> (title: String, ingredients: [String], instructions: [String], summary: [String], servings: [String], timings: [String], skipped: [(String, RecipeLineType, Double)], classified: [(String, RecipeLineType, Double)]) {
    return await withCheckedContinuation { continuation in
      Task.detached {
        let result = self.processRecipeText(text)
        continuation.resume(returning: result)
      }
    }
  }
}

#Preview {
  // Reset the container to avoid conflicts
  //DataController.resetPreviewContainer()
  
  let image = UIImage(named: "julia") ?? UIImage()
  
  return RecipeProcessingView(image: image, text: nil)
    .modelContainer(DataController.previewContainer)
}
