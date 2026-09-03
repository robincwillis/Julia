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

  // Recipe auto-saved on import; replaced if the user saves an edited version
  private var autoSavedRecipe: Recipe?

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
    autoSavedRecipe = nil
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
        let reconstructedText = try await reconstructText(recognizedText)
        let classifiedText = try await classifyText(reconstructedText.reconstructedLines)
        updateRecipeData(recognizedText, reconstructedText, classifiedText)
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
        let reconstructedText = try await reconstructText(recognizedText)
        let classifiedText = try await classifyText(reconstructedText.reconstructedLines)
        updateRecipeData(recognizedText, reconstructedText, classifiedText)
        complete()
      } catch {
        handleError(error.localizedDescription)
      }
    }
  }

  // Process existing recipe data (pre-extracted, no processing phase needed).
  // Pass immediatePresentation: true when called from a sheet's onDismiss — the
  // previous sheet is already fully gone so we can present the results sheet right away.
  // The default 650ms delay covers the case where a fullScreenCover is still animating out.
  func processData(_ data: RecipeData, immediatePresentation: Bool = false) {
    processingState.reset()
    recipeData = data
    autoSave()
    processingState.processingStage = .completed
    if immediatePresentation {
      processingState.showResultsSheet = true
    } else {
      Task {
        try? await Task.sleep(for: .milliseconds(650))
        processingState.showResultsSheet = true
      }
    }
  }

  /// Imports a URL with no view attached — used by the share extension, where
  /// there is no `RecipeURLImportView` to host the scraper and show its phase
  /// labels. Progress is reported through `processingState` so the floating
  /// status sheet covers it, the same as an image or text import.
  func importSharedURL(_ urlString: String) {
    start()

    Task {
      work()
      processingState.statusMessage = "Fetching recipe from the web..."

      let scraper = RecipeWebScraper()
      do {
        let data = try await scraper.scrape(urlString: urlString)
        recipeData = data
        processingState.recognizedText = data.rawText
        autoSave()
        complete()
      } catch {
        handleError(error.localizedDescription)
      }
    }
  }

  /// Text arriving from the share extension. Thin wrapper for symmetry with
  /// `importSharedURL`, so callers do not need to know which entry point the
  /// pipeline uses for each payload kind.
  func importSharedText(_ text: String) {
    processText(text)
  }

  // Persist the imported recipe immediately so it's kept even if the
  // review sheet is dismissed without an explicit save
  private func autoSave() {
    guard let context = modelContext else { return }

    let recipe = recipeData.convertToSwiftDataModel()
    context.insert(recipe)
    autoSavedRecipe = recipe
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

    return try await FoundationModelsRecipeClassifier().classify(reconstructedLines)
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

    // Replace the auto-saved copy with the reviewed version to avoid duplicates
    if let autoSaved = autoSavedRecipe {
      context.delete(autoSaved)
      autoSavedRecipe = nil
    }

    // Snapshot current data
    let data = recipeData

    // Build and insert the recipe synchronously so we can save immediately
    let recipe = data.convertToSwiftDataModel()
    context.insert(recipe)
    try? context.save()

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

// Async wrapper for the text reconstructor (pure heuristic, no ML needed)
extension RecipeTextReconstructor {
  static func reconstructTextAsync(_ lines: [String]) async -> ProcessingTextResult {
    await Task.detached(priority: .userInitiated) {
      reconstructText(from: lines)
    }.value
  }
}
