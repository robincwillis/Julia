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
@Observable
@MainActor
class RecipeProcessor {
  // Set confidence threshold for classification
  static let confidenceThreshold: Double = 0.65

  // Consolidated state
  var processingState = RecipeProcessingState()
  var recipeData = RecipeData()

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
    processingState.processingStage = .notStarted

    processingState.showProcessingSheet = true
    processingState.showResultsSheet = false
  }

  func work() {
    processingState.processingStage = .processing
  }

  func complete() {
    processingState.processingStage = .completed
    processingState.showProcessingSheet = false

    Task {
      try? await Task.sleep(for: .milliseconds(300))
      processingState.showResultsSheet = true
    }

    onCompletion?(recipeData)
  }

  func fail(error: String) {
    processingState.processingStage = .error
    processingState.errorMessage = error
    processingState.statusMessage = ""

    onError?(error)
  }

  // Process image input
  func processImage(_ image: UIImage) {
    start()
    processingState.image = image

    Task {
      do {
        try await Task.sleep(for: .milliseconds(200))
        work()
        let recognizedText = try await extractTextFromImage(image)
        try await Task.sleep(for: .milliseconds(750))
        let reconstructedText = try await reconstructText(recognizedText)
        try await Task.sleep(for: .milliseconds(750))
        let classifiedText = try await classifyText(reconstructedText.reconstructedLines)
        try await Task.sleep(for: .milliseconds(750))
        updateRecipeData(recognizedText, reconstructedText, classifiedText)
        try await Task.sleep(for: .milliseconds(750))
        complete()
      } catch {
        handleError(error.localizedDescription)
      }
    }
  }

  // Process text input
  func processText(_ text: String) {
    start()
    processingState.text = text

    Task {
      do {
        try await Task.sleep(for: .milliseconds(200))
        work()
        let recognizedText = try await extractTextFromText(text)
        try await Task.sleep(for: .milliseconds(750))
        let reconstructedText = try await reconstructText(recognizedText)
        try await Task.sleep(for: .milliseconds(750))
        let classifiedText = try await classifyText(reconstructedText.reconstructedLines)
        try await Task.sleep(for: .milliseconds(750))
        updateRecipeData(recognizedText, reconstructedText, classifiedText)
        try await Task.sleep(for: .milliseconds(750))
        complete()
      } catch {
        handleError(error.localizedDescription)
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
    processingState.statusMessage = "AI is Extracting text..."

    // Work in Progress, not being used in pipeline yet...
    let recipeLayoutAnalyizer = RecipeLayoutAnalyzer()
    let recognizedTextGroups = try await recipeLayoutAnalyizer.analyzeTextGroups(from: image)

    for (index, group) in recognizedTextGroups.enumerated() {
      print("Group \(index + 1):")
      for line in group {
        print("  \(line)")
      }
    }

    let recognizedText = await TextRecognitionService.shared.recognizeText(from: image)

    processingState.recognizedText = recognizedText

    if recognizedText.isEmpty {
      throw ProcessingError.noTextDetected
    }

    return recognizedText
  }

  // Text from text extraction task
  private func extractTextFromText(_ text: String) async throws -> [String] {
    processingState.statusMessage = "AI is extracting text..."

    let recognizedText = text.components(separatedBy: .newlines)

    processingState.recognizedText = recognizedText

    if recognizedText.isEmpty {
      throw ProcessingError.noTextDetected
    }

    return recognizedText
  }

  // Text reconstruction task
  private func reconstructText(_ textLines: [String]) async throws -> ProcessingTextResult {
    processingState.statusMessage = "AI is reconstructing text..."

    let filteredText = textLines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    if filteredText.isEmpty {
      throw ProcessingError.emptyContent
    }

    return await RecipeTextReconstructor.reconstructTextAsync(filteredText)
  }

  // Text classification task
  private func classifyText(_ reconstructedLines: [String]) async throws -> ClassificationResult {
    processingState.isClassifying = true
    processingState.statusMessage = "AI is classifying recipe..."

    let classifier = RecipeTextClassifier(confidenceThreshold: Self.confidenceThreshold)
    return await classifier.processRecipeTextAsync(reconstructedLines)
  }

  // Update recipe data with processing results
  private func updateRecipeData(_ raw: [String], _ reconstructed: ProcessingTextResult, _ classified: ClassificationResult) {
    // Store raw Text
    recipeData.rawText = raw
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
  sectionTitles: [String],
  ingredients: [String],
  instructions: [String],
  summary: [String],
  servings: [String],
  timings: [String],
  notes: [String],
  source: [String],
  skipped: [(String, RecipeLineType, Double)],
  classified: [(String, RecipeLineType, Double)]
)

// Add async methods to the service classes for consistent usage patterns
extension RecipeTextReconstructor {
  static func reconstructTextAsync(_ lines: [String]) async -> ProcessingTextResult {
    await Task.detached(priority: .userInitiated) {
      reconstructText(from: lines)
    }.value
  }
}

extension RecipeTextClassifier {
  func processRecipeTextAsync(_ text: [String]) async -> ClassificationResult {
    let classifier = self
    return await Task.detached(priority: .userInitiated) {
      classifier.processRecipeText(text)
    }.value
  }
}
