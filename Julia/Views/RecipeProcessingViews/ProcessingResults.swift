import SwiftUI
import SwiftData

struct ProcessingResults: View {
  @Environment(\.dismiss) private var dismiss

  @ObservedObject var processingState: RecipeProcessingState
  @Binding var recipeData: RecipeData
  var saveRecipe: () -> Bool
  
  @State var showDismissAlert: Bool = false
  @State var selectedTab = 0


  var body: some View {
    NavigationStack {
      TabView(selection: $selectedTab) {
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
          Label("Raw", systemImage: "text.quote")
        }
        .tag(1)
        
        ProcessingResultsReconstructedText(
          reconstructedText: recipeData.reconstructedText
        )
        .tabItem {
          Label("Reconstructed", systemImage: "text.badge.checkmark")
        }
        .tag(2)
        
        ProcessingResultsClassifiedText(
          recipeData: $recipeData,
          saveProcessingResults: saveProcessingResults
        )
        .tabItem {
          Label("Classified", systemImage: "sparkles")
        }
        .tag(3)
      }
      .onAppear() {
        // Auto-save processing results to UserDefaults for recovery
        saveProcessingResults()
      }
      
      .navigationTitle(!recipeData.title.isEmpty ? recipeData.title : "Process Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .alert("Unsaved Recipe", isPresented: $showDismissAlert) {
        Button("Discard Changes", role: .destructive) {
          dismiss()
        }
        Button("Save", role: .none) {
          saveRecipe()
        }
        Button("Cancel", role: .cancel) {
          showDismissAlert = false
        }
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
        // Actions
//        ToolbarItem(placement: .primaryAction) {
//          Menu {
//            // Dynamic copy button based on current tab
//            switch selectedTab {
//              
//            case 1: // Raw Text tab
//              Button("Copy Raw Text") {
//                UIPasteboard.general.string = processingState.recognizedText.joined(separator: "\n")
//              }
//              
//            case 2: // Reconstructed Text tab
//              Button("Copy Reconstructed Text") {
////                let recipeText = [
////                  "# \(recipeData.title)",
////                  "",
////                  "## Ingredients",
////                  recipeData.ingredients.joined(separator: "\n"),
////                  "",
////                  "## Instructions",
////                  recipeData.instructions.joined(separator: "\n")
////                ].joined(separator: "\n")
//                
//                UIPasteboard.general.string = recipeData.reconstructedText.reconstructedLines.joined(separator: "\n")
//              }
//              
//              if !recipeData.reconstructedText.title.isEmpty {
//                Button("Copy Detected Title") {
//                  UIPasteboard.general.string = recipeData.reconstructedText.title
//                }
//              }
//              
//              if !recipeData.reconstructedText.artifacts.isEmpty {
//                Button("Copy Artifacts") {
//                  UIPasteboard.general.string = recipeData.reconstructedText.artifacts.joined(separator: "\n")
//                }
//              }
//              
//            case 3: // Classified Text tab
//              Button("Copy All Classified Lines") {
//                let classifiedText = recipeData.classifiedLines.map { line, type, confidence in
//                  "[\(type.rawValue.uppercased())] (\(String(format: "%.2f", confidence))): \(line)"
//                }.joined(separator: "\n")
//                
//                UIPasteboard.general.string = classifiedText
//              }
//              
//              Button("Copy Only Used Lines") {
//                let usedLines = recipeData.classifiedLines
//                  .filter { _, _, confidence in confidence >= RecipeProcessor.confidenceThreshold }
//                  .map { line, type, confidence in
//                    "[\(type.rawValue.uppercased())] (\(String(format: "%.2f", confidence))): \(line)"
//                  }
//                  .joined(separator: "\n")
//                
//                UIPasteboard.general.string = usedLines
//              }
//              
//            default:
//              Button("Copy Raw OCR Text") {
//                UIPasteboard.general.string = processingState.recognizedText.joined(separator: "\n")
//              }
//            }
//            
//          } label: {
//            Image(systemName: "ellipsis")
//              .font(.system(size: 14))
//              .foregroundColor(.blue)
//              .padding(12)
//              .frame(width: 30, height: 30)
//              .background(Color(red: 0.85, green: 0.92, blue: 1.0))
//              .clipShape(Circle())
//              .transition(.opacity)
//          }
//        }
      }
      
    }
    .onDisappear {
      // Move to RecipeProcessor?
      UserDefaults.standard.removeObject(forKey: "latestRecipeProcessingResults")
      
      // Reset processing state
      processingState.reset()
      recipeData.reset()
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
    let saveRecipe: () -> Bool = { return true }

    init() {
      // Configure your mock state with sample data
      let state = RecipeProcessingState()
      state.recognizedText = ["Line 1", "Line 2", "Line 3"]
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
        recipeData: $mockRecipeData,
        saveRecipe:saveRecipe
      )
    }
  }
  
  return PreviewWrapper()
}
