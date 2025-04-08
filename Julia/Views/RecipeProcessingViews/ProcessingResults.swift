import SwiftUI
import SwiftData

struct ProcessingResults: View {
  @ObservedObject var processingState: RecipeProcessingState
  @Binding var recipeData: RecipeData
  

  
  var body: some View {
    TabView(selection: $processingState.selectedTab) {
      ProcessingResultsRecipe(
        recipeData: $recipeData,
        saveProcessingResults: saveProcessingResults
      )
      .tabItem {
        Label("Recipe", systemImage: "fork.knife")
      }
      .tag(0)
      
      ProcessingResultsRawText(
        recognizedText: processingState.recognizedText
      )
      .tabItem {
        Label("Raw Text", systemImage: "text.quote")
      }
      .tag(1)
      
      ProcessingResultsReconstructedText(
        reconstructedText: recipeData.reconstructedText
      )
      .tabItem {
        Label("Reconstructed Text", systemImage: "text.badge.checkmark")
      }
      .tag(2)
      
      ProcessingResultsClassifiedText(
        recipeData: $recipeData,
        saveProcessingResults: saveProcessingResults
      )
      .tabItem {
        Label("Classified Text", systemImage: "sparkles")
      }
      .tag(3)
    }
    .onAppear() {
      // Auto-save processing results to UserDefaults for recovery
      saveProcessingResults()
    }
    // .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
    .toolbar {
      // Actions
      ToolbarItem(placement: .primaryAction) {
        Menu {
          // Dynamic copy button based on current tab
          switch processingState.selectedTab {
          case 0: // Recipe tab
            Button("Copy Recipe as Text") {
              let recipeText = [
                "# \(recipeData.title)",
                "",
                "## Ingredients",
                recipeData.ingredients.joined(separator: "\n"),
                "",
                "## Instructions",
                recipeData.instructions.joined(separator: "\n")
              ].joined(separator: "\n")
              
              UIPasteboard.general.string = recipeText
            }
            
          case 1: // Raw Text tab
            Button("Copy Raw OCR Text") {
              UIPasteboard.general.string = processingState.recognizedText.joined(separator: "\n")
            }
            
          case 2: // Reconstructed Text tab
            Button("Copy Reconstructed Text") {
              UIPasteboard.general.string = recipeData.reconstructedText.reconstructedLines.joined(separator: "\n")
            }
            
            if !recipeData.reconstructedText.title.isEmpty {
              Button("Copy Detected Title") {
                UIPasteboard.general.string = recipeData.reconstructedText.title
              }
            }
            
            if !recipeData.reconstructedText.artifacts.isEmpty {
              Button("Copy Artifacts") {
                UIPasteboard.general.string = recipeData.reconstructedText.artifacts.joined(separator: "\n")
              }
            }
            
          case 3: // Classified Text tab
            Button("Copy All Classified Lines") {
              let classifiedText = recipeData.classifiedLines.map { line, type, confidence in
                "[\(type.rawValue.uppercased())] (\(String(format: "%.2f", confidence))): \(line)"
              }.joined(separator: "\n")
              
              UIPasteboard.general.string = classifiedText
            }
            
            Button("Copy Only Used Lines") {
              let usedLines = recipeData.classifiedLines
                .filter { _, _, confidence in confidence >= RecipeProcessingView.confidenceThreshold }
                .map { line, type, confidence in
                  "[\(type.rawValue.uppercased())] (\(String(format: "%.2f", confidence))): \(line)"
                }
                .joined(separator: "\n")
              
              UIPasteboard.general.string = usedLines
            }
            
          default:
            Button("Copy Raw OCR Text") {
              UIPasteboard.general.string = processingState.recognizedText.joined(separator: "\n")
            }
          }
          
          Button("Re-classify Text") {
            // Add re-classification function here or emit an event
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 14))
            .foregroundColor(.blue)
            .padding(12)
            .frame(width: 30, height: 30)
            .background(Color(red: 0.85, green: 0.92, blue: 1.0))
            .clipShape(Circle())
            .transition(.opacity)
        }
      }
    }
  }
  
  private func saveProcessingResults() {
    // Create a dictionary to store all the processing results
    let processingData: [String: Any] = [
      "rawText": processingState.recognizedText,
      "reconstructedText": recipeData.reconstructedText.reconstructedLines,
      "reconstructedTitle": recipeData.reconstructedText.title,
      "reconstructedArtifacts": recipeData.reconstructedText.artifacts,
      "title": recipeData.title,
      "ingredients": recipeData.ingredients,
      "instructions": recipeData.instructions,
      "timestamp": Date().timeIntervalSince1970
    ]
    
    // Save to UserDefaults
    UserDefaults.standard.set(processingData, forKey: "latestRecipeProcessingResults")
  }
}

#Preview {
  struct PreviewWrapper: View {
    @StateObject var mockProcessingState = RecipeProcessingState()
    @State var mockRecipeData = RecipeData()
    
    init() {
      // Configure your mock state with sample data
      let state = RecipeProcessingState()
      state.recognizedText = ["Line 1", "Line 2", "Line 3"]
      state.selectedTab = 0
      state.processingStage = .completed
      _mockProcessingState = StateObject(wrappedValue: state)
      
      // Set up mock recipe data
      var data = RecipeData()
      data.title = "Sample Recipe"
      data.ingredients = ["2 cups flour", "1 cup sugar", "3 eggs"]
      data.instructions = ["Mix dry ingredients", "Add eggs", "Bake at 350°F for 30 minutes"]
      // Use the typealias defined in RecipeProcessing.swift to avoid ambiguity
      data.reconstructedText = TextReconstructorResult(
        title: "Sample Recipe",
        reconstructedLines: ["2 cups flour", "1 cup sugar", "3 eggs", "Mix dry ingredients", "Add eggs"],
        artifacts: ["350°F"]
      )
      _mockRecipeData = State(initialValue: data)
    }
    
    var body: some View {
      ProcessingResults(
        processingState: mockProcessingState,
        recipeData: $mockRecipeData
      )
    }
  }
  
  return PreviewWrapper()
}
