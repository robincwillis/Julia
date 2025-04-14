//
//  RecipeProcessor.swift
//  Julia
//
//  Created by Robin Willis on 4/9/25.
//

import SwiftUI
import SwiftData
import Vision
import Foundation

/// Manages recipe processing workflow and state
class RecipeProcessor: ObservableObject {
  // Set confidence threshold for classification
  static let confidenceThreshold: Double = 0.65
  
  // Consolidated state
  @Published var processingState = RecipeProcessingState()
  @Published var recipeData = RecipeData()
  
  // Reference to model context for saving
  private var modelContext: ModelContext?
  
  // Completion handler
  var onCompletion: ((RecipeData) -> Void)?
  var onError: ((String) -> Void)?
  
  // Initialize with different input sources
  init(modelContext: ModelContext? = nil) {
    self.modelContext = modelContext
  }
  
  func setModelContext(_ context: ModelContext) {
    self.modelContext = context
  }
  
  // Manage State
  func start() {
    processingState.reset()
    recipeData.reset()
    processingState.processingStage = .processing
    
    processingState.showProcessingSheet = true
    processingState.showResultsSheet = false
  }
  
  func complete() {
    processingState.processingStage = .completed
    
    self.processingState.showProcessingSheet = false
    self.processingState.showResultsSheet = true
    self.onCompletion?(self.recipeData)
  }
  
  func fail(error: String) {
    processingState.processingStage = .error
    processingState.errorMessage = error
    processingState.statusMessage = ""
    
    processingState.showProcessingSheet = true
    processingState.showResultsSheet = false
    
    onError?(error)
  }
  
  // Process image input
  func processImage(_ image: UIImage) {
    start()
    processingState.image = image
    
    Task {
      do {
        let recognizedText = try await extractTextFromImage(image)
        try await Task.sleep(nanoseconds: 500_000_000)
        let reconstructedText = try await reconstructText(recognizedText)
        try await Task.sleep(nanoseconds: 500_000_000)
        let classifiedText = try await classifyText(reconstructedText.reconstructedLines)
        try await Task.sleep(nanoseconds: 500_000_000)
        await updateRecipeData(reconstructedText, classifiedText)
        try await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
          complete()
        }
      } catch {
        await MainActor.run {
          handleError(error.localizedDescription)
        }
      }
    }
  }
  
  // Process text input
  func processText(_ text: String) {
    start()
    processingState.text = text
    
    Task {
      do {
        let recognizedText = try await extractTextFromText(text)
        try await Task.sleep(nanoseconds: 500_000_000)
        let reconstructedText = try await reconstructText(recognizedText)
        try await Task.sleep(nanoseconds: 500_000_000)
        let classifiedText = try await classifyText(reconstructedText.reconstructedLines)
        try await Task.sleep(nanoseconds: 500_000_000)
        await updateRecipeData(reconstructedText, classifiedText)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
          complete()
        }
      } catch {
        await MainActor.run {
          handleError(error.localizedDescription)
        }
      }
    }
  }
  
  // Process existing recipe data
  func processData(_ data: RecipeData) {
    start()
    recipeData = data
    complete()
  }
  
  // Text from image extraction task
  private func extractTextFromImage(_ image: UIImage) async throws -> [String] {
    await MainActor.run {
      processingState.statusMessage = "AI is Extracting text from image..."
    }
    
    let recognizedText = await TextRecognitionService.shared.recognizeText(from: image)
    
    // Update UI on main thread
    await MainActor.run {
      processingState.recognizedText = recognizedText
    }
    
    if recognizedText.isEmpty {
      throw ProcessingError.noTextDetected
    }
    
    return recognizedText
  }
  
  // Text from text extraction task (I know, weird)
  private func extractTextFromText(_ text: String) async throws -> [String] {
    await MainActor.run {
      processingState.statusMessage = "AI is Extracting text..."
    }
    
    let recognizedText = text.components(separatedBy: .newlines)
    
    // Update UI on main thread
    await MainActor.run {
      processingState.recognizedText = recognizedText
    }
    
    if recognizedText.isEmpty {
      throw ProcessingError.noTextDetected
    }
    
    return recognizedText
  }
  
  // Text reconstruction task
  private func reconstructText(_ textLines: [String]) async throws -> ProcessingTextResult {
    await MainActor.run {
      processingState.statusMessage = "AI is Reconstructing text..."
    }
    
    let filteredText = textLines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    if filteredText.isEmpty {
      throw ProcessingError.emptyContent
    }
    
    // Run reconstructor
    let reconstructed = await RecipeTextReconstructor.reconstructTextAsync(filteredText)
    return reconstructed
  }
  
  // Text classification task
  private func classifyText(_ reconstructedLines: [String]) async throws -> ClassificationResult {
    await MainActor.run {
      processingState.isClassifying = true
      processingState.statusMessage = "AI is classifying recipe content..."
    }
    
    let classifier = RecipeTextClassifier(confidenceThreshold: Self.confidenceThreshold)
    let classification = await classifier.processRecipeTextAsync(reconstructedLines)
    
    return classification
  }
  
  // Update recipe data with processing results
  private func updateRecipeData(_ reconstructed: ProcessingTextResult, _ classified: ClassificationResult) async {
    await MainActor.run {
      processingState.statusMessage = "AI is Finalizing the details..."
      
      // Store reconstructed text
      recipeData.reconstructedText = reconstructed
      
      // Use title from reconstructor if available, otherwise use the one from classifier
      recipeData.title = !reconstructed.title.isEmpty ? reconstructed.title : classified.title
      
      // Store classification results
      recipeData.ingredients = classified.ingredients
      recipeData.instructions = classified.instructions
      recipeData.summary = classified.summary
      recipeData.timings = classified.timings
      recipeData.servings = classified.servings
      recipeData.skippedLines = classified.skipped
      recipeData.classifiedLines = classified.classified
      
      processingState.isClassifying = false
    }
  }
  
  // Error handling
  private func handleError(_ message: String) {
    fail(error: message)
  }
  
  // Save the recipe to the data store
  func saveRecipe() -> Bool {
    guard let context = modelContext else {
      processingState.errorMessage = "Cannot save recipe: database context unavailable"
      return false
    }
    
    // Create recipe from data
    let recipe = recipeData.convertToSwiftDataModel()
    
    // Save to context
    context.insert(recipe)
    
    // Clear processing data
    processingState.reset()
    recipeData.reset()
    
    return true
  }
  
  // Custom error types for processing
  enum ProcessingError: Error, LocalizedError {
    case noTextDetected
    case emptyContent
    case classificationFailed
    
    var errorDescription: String? {
      switch self {
      case .noTextDetected:
        return "No text was detected in the image"
      case .emptyContent:
        return "The content is empty after filtering"
      case .classificationFailed:
        return "Failed to classify the recipe content"
      }
    }
  }
}

// Type alias for classification result
typealias ClassificationResult = (
  title: String,
  ingredients: [String],
  instructions: [String],
  summary: [String],
  servings: [String],
  timings: [String],
  skipped: [(String, RecipeLineType, Double)],
  classified: [(String, RecipeLineType, Double)]
)

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
  func processRecipeTextAsync(_ text: [String]) async -> ClassificationResult {
    return await withCheckedContinuation { continuation in
      Task.detached {
        let result = self.processRecipeText(text)
        continuation.resume(returning: result)
      }
    }
  }
}
