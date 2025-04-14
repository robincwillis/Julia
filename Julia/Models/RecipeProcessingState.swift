import SwiftUI
import UIKit

class RecipeProcessingState: ObservableObject {
  
  // Input state
  @Published var image: UIImage?
  @Published var text: String?
  @Published var recognizedText: [String] = []
  
  // Processing state
  @Published var processingStage: ProcessingStage = .notStarted
  
  @Published var isClassifying = false
  
  @Published var statusMessage = ""
  @Published var errorMessage = ""
  
  // UI state
  @Published var showProcessingSheet = false
  @Published var showResultsSheet = false
  
  enum ProcessingStage: String {
    case notStarted = "Warming Up"
    case processing = "Processing Recipe"
    case completed = "Processing Complete"
    case error = "Processing Error"
  }
  
  // Computed properties with getters and setters
  var isProcessing: Bool {
    get {
      return processingStage == .processing
    }
    set {
      if newValue {
        processingStage = .processing
      }
    }
  }
  
  var processingFailed: Bool {
    get {
      return processingStage == .error
    }
    set {
      if newValue {
        processingStage = .error
      }
    }
  }
  
  var processingComplete: Bool {
    get {
      return processingStage == .completed
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
