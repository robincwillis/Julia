//
//  ProcessingResultsRecipe.swift
//  Julia
//
//  Created by Robin Willis on 3/16/25.
//

import SwiftUI

struct ProcessingResultsRecipe: View {
  @Binding var recipeData: RecipeData
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
      
      if !recipeData.summary.isEmpty {
        Section("Summary") {
          ForEach(0..<recipeData.summary.count, id: \.self) { index in
            TextEditor(text: Binding(
              get: { recipeData.summary[index] },
              set: {
                recipeData.summary[index] = $0
                hasUnsavedChanges = true
                saveProcessingResults()
              }
            ))
            .frame(height: 150)
            .submitLabel(.done)
          }
        }
      }
      
      if !recipeData.timings.isEmpty {
        Section("Timings") {
          ForEach(0..<recipeData.timings.count, id: \.self) { index in
            TextField("Timing", text: Binding(
              get: { recipeData.timings[index] },
              set: {
                recipeData.timings[index] = $0
                hasUnsavedChanges = true
                saveProcessingResults()
              }
            ))
            .submitLabel(.done)
          }
        }
      }
      
      if !recipeData.servings.isEmpty {
        Section("Servings") {
          ForEach(0..<recipeData.servings.count, id: \.self) { index in
            TextField("Servings", text: Binding(
              get: { recipeData.servings[index] },
              set: {
                recipeData.servings[index] = $0
                hasUnsavedChanges = true
                saveProcessingResults()
              }
            ))
            .submitLabel(.done)
          }
        }
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
      
      if !recipeData.notes.isEmpty {
        Section("Notes") {
          ForEach(0..<recipeData.notes.count, id: \.self) { index in
            TextField("Note", text: Binding(
              get: { recipeData.notes[index] },
              set: {
                recipeData.notes[index] = $0
                hasUnsavedChanges = true
                saveProcessingResults()
              }
            ))
            .submitLabel(.done)
          }
        }
      }
      
      if recipeData.source != nil || recipeData.website != nil || recipeData.author != nil {
        Section("Source") {
          if let source = recipeData.source {
            TextField("Source", text: Binding(
              get: { source },
              set: {
                recipeData.source = $0
                hasUnsavedChanges = true
                saveProcessingResults()
              }
            ))
            .submitLabel(.done)
          }
          
          if let website = recipeData.website {
            TextField("Website", text: Binding(
              get: { website },
              set: {
                recipeData.website = $0
                hasUnsavedChanges = true
                saveProcessingResults()
              }
            ))
            .submitLabel(.done)
          }
          
          if let author = recipeData.author {
            TextField("Author", text: Binding(
              get: { author },
              set: {
                recipeData.author = $0
                hasUnsavedChanges = true
                saveProcessingResults()
              }
            ))
            .submitLabel(.done)
          }
        }
      }
    }
    .scrollContentBackground(.hidden)
    .background(Color.app.backgroundSecondary)
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State var mockRecipeData = RecipeData()
    let saveProcessingResults: () -> Void
    init() {
      self.saveProcessingResults = {
        print("Mock save processing results called")
      }
      var data = RecipeData()
      data.title = "Sample Recipe"
      data.summary = ["Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."]
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
