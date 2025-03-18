//
//  ProcessingResultsRecipe.swift
//  Julia
//
//  Created by Robin Willis on 3/16/25.
//

import SwiftUI

struct ProcessingResultsRecipe: View {
  @Binding var recipeData: RecipeProcessingView.RecipeData
  let saveProcessingResults: () -> Void
  @State private var hasUnsavedChanges = false

  var body: some View {
    Form {
      Section("Recipe Title") {
        TextField("Title", text: Binding(
          get: { recipeData.title },
          set: {
            recipeData.title = $0
            hasUnsavedChanges = true
            saveProcessingResults()
          }
        ))
        .font(.headline)
        .submitLabel(.done)
      }
      
      Section("Ingredients") {
        ForEach(0..<recipeData.ingredients.count, id: \.self) { index in
          TextField("Ingredient \(index + 1)", text: Binding(
            get: { recipeData.ingredients[index] },
            set: {
              recipeData.ingredients[index] = $0
              hasUnsavedChanges = true
              saveProcessingResults()
            }
          ))
          .submitLabel(.done)
        }
      }
      
      Section("Instructions") {
        ForEach(0..<recipeData.instructions.count, id: \.self) { index in
          TextField("Step \(index + 1)", text: Binding(
            get: { recipeData.instructions[index] },
            set: {
              recipeData.instructions[index] = $0
              hasUnsavedChanges = true
              saveProcessingResults()
            }
          ))
          .submitLabel(.done)
        }
      }
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State var mockRecipeData = RecipeProcessingView.RecipeData()
    let saveProcessingResults: () -> Void
    init() {
      self.saveProcessingResults = {
        print("Mock save processing results called")
      }
      var data = RecipeProcessingView.RecipeData()
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
      ProcessingResultsRecipe(
        recipeData: $mockRecipeData,
        saveProcessingResults: saveProcessingResults
      )
    }
  }
  return PreviewWrapper()
}
