import SwiftUI

@Observable
@MainActor
class RecipeProcessingState {

  // Input state
  var image: UIImage?
  var text: String?
  var recognizedText: [String] = []

  // Processing state
  var processingStage: ProcessingStage = .notStarted

  var isClassifying = false

  var statusMessage = ""
  var errorMessage = ""

  // UI state
  var showProcessingSheet = false
  var showResultsSheet = false

  enum ProcessingStage: String {
    case notStarted = "Warming Up"
    case processing = "Processing"
    case completed = "Complete"
    case error = "Error"
  }

  // Computed properties with getters and setters
  var isProcessing: Bool {
    get {
      processingStage == .processing
    }
    set {
      if newValue {
        processingStage = .processing
      }
    }
  }

  var processingFailed: Bool {
    get {
      processingStage == .error
    }
    set {
      if newValue {
        processingStage = .error
      }
    }
  }

  var processingComplete: Bool {
    get {
      processingStage == .completed
    }
    set {
      if newValue {
        processingStage = .completed
      }
    }
  }

  func reset() {
    // Reset input state
    image = nil
    text = nil
    recognizedText = []

    // Reset processing state
    processingStage = .notStarted
    isClassifying = false
    statusMessage = ""
    errorMessage = ""

    // Reset UI state
    showProcessingSheet = false
    showResultsSheet = false
  }
}
