import SwiftUI
import UIKit

// AppStorage for persisting processing state
class RecipeProcessingState: ObservableObject {
    @Published var image: UIImage?
    @Published var recognizedText: [String] = []
    @Published var processingStage: ProcessingStage = .notStarted
    @Published var selectedTab = 0
    
    enum ProcessingStage {
        case notStarted
        case processing
        case completed
    }
    
    func reset() {
        image = nil
        recognizedText = []
        processingStage = .notStarted
        selectedTab = 0
    }
}