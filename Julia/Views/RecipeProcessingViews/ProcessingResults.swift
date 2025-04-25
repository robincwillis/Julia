import SwiftUI
import SwiftData

struct ProcessingResults: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.debugMode) private var debugMode
  
  @ObservedObject var processingState: RecipeProcessingState
  @Binding var recipeData: RecipeData
  var saveRecipe: () -> Bool
  
  @State var showDismissAlert: Bool = false
  @State var selectedTab = 0
  
  
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
      }
    }
    .alert("Unsaved Recipe", isPresented: $showDismissAlert) {
      Button("Discard Changes", role: .destructive) {
        dismiss()
      }
      Button("Save", role: .none) {
        saveRecipe()
      }
      .tint(Color.app.danger)
      Button("Cancel", role: .cancel) {
        showDismissAlert = false
      }
    } message: {
      Text("You have an unsaved recipe. What would you like to do?")
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
      data.ingredients = ["2 cups flour", "1 cup sugar", "3 eggs", "2 cups flour", "1 cup sugar", "3 eggs"]
      data.instructions = ["Mix dry ingredients", "Add eggs", "Bake at 350°F for 30 minutes", "Mix dry ingredients", "Add eggs", "Bake at 350°F for 30 minutes"]
      // Use the typealias defined in RecipeProcessing.swift to avoid ambiguity
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
      .previewDisplayName("Debug Mode On")
      
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
