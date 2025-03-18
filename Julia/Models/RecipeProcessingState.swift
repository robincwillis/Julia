import SwiftUI
import UIKit

// AppStorage for persisting processing state
class RecipeProcessingState: ObservableObject {
    @Published var image: UIImage?
    @Published var text: String?
    @Published var recognizedText: [String] = []
    @Published var processingStage: ProcessingStage = .notStarted
    @Published var selectedTab = 0
    
    enum ProcessingStage {
        case notStarted
        case processing
        case completed
        case error
    }
    
    func reset() {
        image = nil
        text = nil
        recognizedText = []
        processingStage = .notStarted
        selectedTab = 0
    }
}
