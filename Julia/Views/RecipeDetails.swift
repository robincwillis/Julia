//
//  RecipeDetails.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData

// Import section views
import UIKit

// Import notification names from NavigationView
// extension is declared there

struct RecipeDetails: View {
  let recipe: Recipe
  
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) var context
  @Environment(\.editMode) private var editMode
  
  private var isEditing: Bool {
    return editMode?.wrappedValue.isEditing ?? false
  }
  
  // Check if there are unsaved changes
  private var hasUnsavedChanges: Bool {
    // Compare edited values with original recipe
    return editedTitle != recipe.title ||
           editedSummary != (recipe.summary ?? "") ||
           editedInstructions != recipe.instructions ||
           !compareIngredients()
  }
  
  // Helper to compare ingredients and sections
  private func compareIngredients() -> Bool {
    if editedSections.isEmpty && recipe.sections.isEmpty {
      // Compare just ingredients
      return editedIngredients.count == recipe.ingredients.count
    } else if editedSections.count != recipe.sections.count {
      return false
    }
    
    // Basic check - could be more detailed if needed
    return true
  }
  
  @State private var showingDeleteConfirmation = false
  @State private var showCancelConfirmation = false
  @State private var shouldSaveChanges = true
  
  // Edited recipe properties
  @State private var editedTitle = ""
  @State private var editedSummary = ""
  @State private var editedInstructions: [String] = []
  @State private var editedIngredients: [Ingredient] = []
  @State private var editedSections: [IngredientSection] = []
  @FocusState private var isTextFieldFocused: Bool
  
  var rawTextString: String {
    recipe.rawText?.joined(separator: "\n") ?? ""
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        // Title and Summary Section
        RecipeTitleSection(
          recipe: recipe,
          isEditing: isEditing,
          editedTitle: $editedTitle, 
          editedSummary: $editedSummary,
          isTextFieldFocused: _isTextFieldFocused
        )
        
        // Ingredients Section
        RecipeIngredientsSection(
          recipe: recipe,
          isEditing: isEditing,
          editedIngredients: $editedIngredients,
          editedSections: $editedSections,
          selectedIngredient: $selectedIngredient,
          showingIngredientEditor: $showingIngredientEditor,
          isTextFieldFocused: _isTextFieldFocused
        )
        
        // Instructions Section
        RecipeInstructionsSection(
          recipe: recipe,
          editedInstructions: $editedInstructions,
          isTextFieldFocused: _isTextFieldFocused
        )
        
        // Raw text section (only shown in display mode)
        if !isEditing {
          RecipeRawTextSection(recipe: recipe)
        }
        
        Spacer()
      }
      .padding()
    }
    .navigationTitle(isEditing ? "" : recipe.title)
    .navigationBarTitleDisplayMode(.large)

    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        if isEditing {
          Menu {
            Button("Cancel", systemImage: "xmark") {
              cancelEditing()
            }
            Button("Delete Recipe", systemImage: "trash", role: .destructive) {
              showingDeleteConfirmation = true
            }
            Button("Clear All Recipes", systemImage: "clear", role: .destructive) {
              do {
                try context.delete(model: Recipe.self)
              } catch {
                print(error.localizedDescription)
              }
            }
          } label: {
            Image(systemName: "ellipsis")
              .rotationEffect(.degrees(90))
              .foregroundColor(.blue)
              .frame(width: 40, height: 40)
              .background(.tertiary)
              .clipShape(Circle())
          }
        }
      }
      // Edit/Done button (right side)
      ToolbarItem(placement: .navigationBarTrailing) {
        // Custom EditButton to handle confirmation before exiting edit mode
        Group {
          if isEditing {
            Button("Done") {
              // We want to save changes when tapping Done
              shouldSaveChanges = true
              editMode?.wrappedValue = .inactive
            }
          } else {
            Button("Edit") {
              editMode?.wrappedValue = .active
            }
          }
        }
      }
    }
    .confirmationDialog("Are you sure?",
                      isPresented: $showingDeleteConfirmation,
                      titleVisibility: .visible
    ) {
      Button("Delete Recipe", role: .destructive) {
        deleteRecipe()
      }
    }
    .confirmationDialog("Discard changes?",
                      isPresented: $showCancelConfirmation,
                      titleVisibility: .visible
    ) {
      Button("Discard Changes", role: .destructive) {
        shouldSaveChanges = false
        editMode?.wrappedValue = .inactive
      }
      Button("Keep Editing", role: .cancel) { }
    } message: {
      Text("You have unsaved changes that will be lost")
    }
    .sheet(isPresented: $showingIngredientEditor) {
      if let selectedIngredient = selectedIngredient {
        EditIngredient(ingredient: .constant(selectedIngredient))
      }
    }
    .onAppear {
      NotificationCenter.default.post(name: .hideTabBar, object: nil)
    }
    .onDisappear {
      NotificationCenter.default.post(name: .showTabBar, object: nil)
    }
    .onChange(of: editMode?.wrappedValue) { oldValue, newValue in
      if newValue?.isEditing == true && (oldValue?.isEditing == false || oldValue?.isEditing == nil) {
        // Entering edit mode
        prepareForEditing()
      } else if newValue?.isEditing == false && oldValue?.isEditing == true {
        // Exiting edit mode
        if shouldSaveChanges {
          saveChanges()
        } else {
          // If we explicitly set shouldSaveChanges to false, don't save
          shouldSaveChanges = true  // Reset for next time
        }
      }
    }
  }
  
  // MARK: - Edit Mode Functions
  
  private func prepareForEditing() {
    editedTitle = recipe.title
    editedSummary = recipe.summary ?? ""
    editedInstructions = recipe.instructions
    
    // Deep copy ingredients and sections for editing
    editedIngredients = recipe.ingredients
    
    // Deep copy sections
    editedSections = recipe.sections.map { section in
      let newSection = IngredientSection(id: section.id, name: section.name, position: section.position)
      newSection.ingredients = section.ingredients
      return newSection
    }
    
    // Sort sections by position
    editedSections.sort { $0.position < $1.position }
    
    // Print debugging information
    print("Preparing for editing:")
    print("- Title: \(editedTitle)")
    print("- Instructions: \(editedInstructions.count)")
    print("- Ingredients: \(editedIngredients.count)")
    print("- Sections: \(editedSections.count)")
  }
  
  private func saveChanges() {
    // Update the recipe with edited values
    recipe.title = editedTitle
    recipe.summary = editedSummary.isEmpty ? nil : editedSummary
    recipe.instructions = editedInstructions
    
    if editedSections.isEmpty {
      recipe.ingredients = editedIngredients
      recipe.sections = []
    } else {
      // Ensure positions are sequential
      for (index, section) in editedSections.enumerated() {
        section.position = index
      }
      
      recipe.sections = editedSections
      recipe.ingredients = editedSections.flatMap { $0.ingredients }
    }
    
    // Save changes to context
    do {
      try context.save()
    } catch {
      print("Error saving recipe changes: \(error)")
    }
  }
  
  private func cancelEditing() {
    // Called when user wants to cancel editing
    if hasUnsavedChanges {
      showCancelConfirmation = true
    } else {
      // No changes to lose, just exit edit mode
      shouldSaveChanges = false
      editMode?.wrappedValue = .inactive
    }
  }
  
  private func deleteRecipe() {
    context.delete(recipe)
    
    // We need to handle potential errors when changes are saved
    do {
      try context.save()
    } catch {
      print("Error deleting recipe: \(error)")
    }

    showingDeleteConfirmation = false
    dismiss()
  }
  
  // MARK: - State for Ingredient Editor
  @State private var selectedIngredient: Ingredient?
  @State private var showingIngredientEditor = false
  
  // Ingredient and section functions moved to RecipeIngredientsSection
  
  // Instruction functions moved to RecipeInstructionsSection
}

#Preview {
  let container = DataController.previewContainer
  let fetchDescriptor = FetchDescriptor<Recipe>()
  
  let previewRecipe: Recipe
  
  do {
    let recipes = try container.mainContext.fetch(fetchDescriptor)
    if let firstRecipe = recipes.first {
      previewRecipe = firstRecipe
    } else {
      // Fallback if no recipes found
      previewRecipe = Recipe(
        title: "Sample Recipe",
        summary: "A delicious sample recipe",
        ingredients: [],
        instructions: ["Step 1: Mix ingredients", "Step 2: Cook thoroughly"],
        sections: [],
        rawText: []
      )
    }
  } catch {
    print("Error fetching recipes: \(error)")
    // Error fallback
    previewRecipe = Recipe(
      title: "Sample Recipe",
      summary: "A delicious sample recipe",
      ingredients: [],
      instructions: ["Step 1: Mix ingredients", "Step 2: Cook thoroughly"],
      sections: [],
      rawText: []
    )
  }
  
  return NavigationStack {
    RecipeDetails(recipe: previewRecipe)
      .modelContainer(container)
  }

}
