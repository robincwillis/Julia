import SwiftUI
import SwiftData

struct ProcessingResults: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.debugMode) private var debugMode
  
  var processingState: RecipeProcessingState
  @Binding var recipeData: RecipeData
  var saveRecipe: () -> Bool
  
  @State var showDismissAlert: Bool = false
  @State var selectedTab = 0
  @State private var isSaved = false
  
  
  var body: some View {
    NavigationStack {
      VStack {
        Group {
          if debugMode {
            TabView(selection: $selectedTab) {
              ProcessingResultsRecipe(
                recipeData: $recipeData,
                saveProcessingResults: saveProcessingResults
              )
              .tag(0)
              .tabItem {
                Label("Recipe", systemImage: "fork.knife")
                  .padding(.top, 12)
              }
              
              
              ProcessingResultsRawText(
                recognizedText: processingState.recognizedText
              )
              .tag(1)
              .tabItem {
                Label("Raw", systemImage: "text.quote")
              }
              
              
              ProcessingResultsReconstructedText(
                reconstructedText: recipeData.reconstructedText
              )
              .tag(2)
              .tabItem {
                Label("Reconstructed", systemImage: "text.badge.checkmark")
              }
              
              
              ProcessingResultsClassifiedText(
                recipeData: $recipeData,
                saveProcessingResults: saveProcessingResults
              )
              .tag(3)
              .tabItem {
                Label("Classified", systemImage: "sparkles")
              }
              
            }
          } else {
            ProcessingResultsRecipe(
              recipeData: $recipeData,
              saveProcessingResults: saveProcessingResults
            )
          }
        }
      }
      .navigationTitle(!recipeData.title.isEmpty ? recipeData.title : "Process Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(isSaved ? "Done" : "Cancel") {
            if isSaved {
              dismiss()
            } else if !recipeData.title.isEmpty || !recipeData.ingredients.isEmpty || !recipeData.instructions.isEmpty {
              showDismissAlert = true
            } else {
              dismiss()
            }
          }
          .foregroundStyle(isSaved ? Color.app.primary : .secondary)
        }

        ToolbarItem(placement: .primaryAction) {
          if !recipeData.title.isEmpty || !recipeData.ingredients.isEmpty || !recipeData.instructions.isEmpty {
            Button(isSaved ? "Saved ✓" : "Save") {
              if saveRecipe() {
                isSaved = true
              }
            }
            .foregroundStyle(isSaved ? .secondary : Color.app.primary)
            .disabled(isSaved)
          }
        }
      }
    }
    .alert("Unsaved Recipe", isPresented: $showDismissAlert) {
      Button("Discard", role: .destructive) {
        dismiss()
      }
      Button("Save & Continue") {
        if saveRecipe() { isSaved = true }
      }
      Button("Cancel", role: .cancel) {
        showDismissAlert = false
      }
    } message: {
      Text("Save this recipe before closing?")
    }
    .onAppear() {
      // Auto-save processing results to UserDefaults for recovery
      saveProcessingResults()
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
    @State var mockProcessingState = RecipeProcessingState()
    @State var mockRecipeData = RecipeData()
    let saveRecipe: () -> Bool = { return true }

    init() {
      var data = RecipeData()
      data.title = "Sample Recipe"
      data.ingredients = ["2 cups flour", "1 cup sugar", "3 eggs"]
      data.instructions = ["Mix dry ingredients", "Add eggs", "Bake at 350°F for 30 minutes"]
      data.reconstructedText = TextReconstructorResult(
        title: "Sample Recipe",
        reconstructedLines: ["2 cups flour", "1 cup sugar", "3 eggs", "Mix dry ingredients", "Add eggs"],
        artifacts: ["350°F"]
      )
      _mockRecipeData = State(initialValue: data)
    }
    
    var body: some View {
      
      // Debug Mode On Preview
      ProcessingResults(
        processingState: mockProcessingState,
        recipeData: $mockRecipeData,
        saveRecipe: saveRecipe
      )
      .environment(\.debugMode, true)
      
      // Debug Mode Off Preview
      //        ProcessingResults(
      //          processingState: mockProcessingState,
      //          recipeData: $mockRecipeData,
      //          saveRecipe: saveRecipe
      //        )
      //        .environment(\.debugMode, false)
      //        .previewDisplayName("Debug Mode Off")
      
    }
  }
  
  return PreviewWrapper()
}
