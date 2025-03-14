//
//  RecipeDetails.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData
import UIKit

struct RecipeDetails: View {
  @Bindable var recipe: Recipe
  
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) var context
  @Environment(\.editMode) private var editMode
  
  private var isEditing: Bool {
    return editMode?.wrappedValue.isEditing ?? false
  }
  
  var ingredientLocation: IngredientLocation = .recipe
  
  @State private var showDeleteConfirmation = false
  @State private var selectedIngredient: Ingredient?
  @State private var showIngredientEditor = false
  @State private var selectedIngredients: Set<Ingredient> = []
  @State private var showRawTextSheet = false
  
  @FocusState private var isTextFieldFocused: Bool
  @FocusState private var focusedInstructionField: Int?
  
  let debug = false
  
  var rawTextString: String {
    recipe.rawText?.joined(separator: "\n") ?? ""
  }
  
  var body: some View {
    ZStack {
      if (isEditing) {
        Form {
          // Edit Summary Section
          RecipeEditSummarySection(
            title: $recipe.title,
            summary: $recipe.summary,
            isTextFieldFocused: _isTextFieldFocused
          )
          
          // Ingredients section
          RecipeEditIngredientsSection(
            ingredients: $recipe.ingredients,
            sections: $recipe.sections,
            selectedIngredient: $selectedIngredient,
            showIngredientEditor: $showIngredientEditor,
            isTextFieldFocused: _isTextFieldFocused
          )
          
          // Instructions section
          RecipeEditInstructionsSection(
            instructions: $recipe.instructions,
            isTextFieldFocused: _isTextFieldFocused,
            focusedInstructionField: _focusedInstructionField
          )
        }
        .background(Color(.secondarySystemBackground))
        .listStyle(.insetGrouped)
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        
      } else {
        ScrollView(.vertical, showsIndicators: true) {
          VStack(alignment: .leading, spacing: 12) {
            // Title and Summary Section
            RecipeSummarySection(
              recipe: recipe
            )
            
            // Ingredients Section with selectable ingredients
            RecipeIngredientsSection(
              recipe: recipe,
              selectableBinding: selectableBinding(for:),
              toggleSelection: toggleSelection(for:)
            )
            
            // Additional Ingredient Sections
            if !recipe.sections.isEmpty {
              IngredientSectionList(
                sections: recipe.sections,
                selectableBinding: selectableBinding(for:),
                toggleSelection: toggleSelection(for:)
              )
            }
            
            // Instructions Section
            RecipeInstructionsSection(
              recipe: recipe
            )
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.large)
        .edgesIgnoringSafeArea(.bottom)
        .toolbar {
// Not working well
//          ToolbarItem(placement: .principal) {
//            Text(recipe.title)
//              .font(.largeTitle)
//              .fontWeight(.bold)
//              .lineLimit(nil) // Remove line limit
//              .fixedSize(horizontal: false, vertical: true) // Enable wrapping
//              .multilineTextAlignment(.center) // Optional: center align if desired
//          }
         if !selectedIngredients.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
              Menu {
                Button(action: addSelectedToGroceryList) {
                  Label("Add to Grocery List", systemImage: "cart.fill.badge.plus")
                }
                Button(action: selectAll) {
                  Label("Select All", systemImage: "checklist.checked")
                }
                Button(action: clearSelection) {
                  Label("Clear Selection", systemImage: "xmark.circle")
                }
              } label: {
                Text("\(selectedIngredients.count) selected")
                  .foregroundColor(.white)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 6)
                  .background(Color.blue)
                  .cornerRadius(8)
              }
            }
          }
        }
      }
      FloatingBottomSheet(
        isPresented: $showIngredientEditor,
        showHideTabBar : false
      ) {
        IngredientEditor(
          ingredientLocation: ingredientLocation,
          ingredient: $selectedIngredient,
          showBottomSheet: $showIngredientEditor
        )
      }.onChange(of: showIngredientEditor) {
        // Remove selectedIngredient if sheet is dismissed
        if(showIngredientEditor == false) {
          // Check if the selected ingredient exists and has an empty name
          if let ingredient = selectedIngredient, ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deleteIngredient(ingredient)
          }
          selectedIngredient = nil
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        if isEditing {
          Menu {
            Button("Show Raw Text", systemImage: "text.quote") {
              showRawTextSheet = true
            }
            Button("Delete Recipe", systemImage: "trash", role: .destructive) {
              showDeleteConfirmation = true
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
              .font(.system(size: 14))
              .foregroundColor(.blue)
              .padding(12)
              .frame(width: 30, height: 30)
              .background(Color(red: 0.85, green: 0.92, blue: 1.0))
              .clipShape(Circle())
              .animation(.snappy, value: isEditing)
              .transition(.opacity)
          }
        }
      }
      // Edit/Done button (right side)
      ToolbarItem(placement: .navigationBarTrailing) {
        // Custom EditButton to handle confirmation before exiting edit mode
        Group {
          if isEditing {
            Button("Done") {
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
                      isPresented: $showDeleteConfirmation,
                      titleVisibility: .visible
    ) {
      Button("Delete Recipe", role: .destructive) {
        deleteRecipe()
      }
    }
    // Add this onChange modifier to your view
    .onChange(of: focusedInstructionField) { oldValue, newValue in
      if newValue != nil {
        // When instruction field gets focus, unfocus the text field
        isTextFieldFocused = false
      }
    }
    
    // And vice versa if needed
    .onChange(of: isTextFieldFocused) { oldValue, newValue in
      if newValue == true {
        // When text field gets focus, unfocus the instruction field
        focusedInstructionField = nil
      }
    }
    .onAppear {
      NotificationCenter.default.post(name: .hideTabBar, object: nil)
    }
    .onDisappear {
      NotificationCenter.default.post(name: .showTabBar, object: nil)
      // If leaving while in edit mode, exit edit mode
      if editMode?.wrappedValue.isEditing == true {
        editMode?.wrappedValue = .inactive
      }
    }
    .sheet(isPresented: $showRawTextSheet) {
      ScrollView {
        RecipeRawTextSection(recipe: recipe)
      }
      .presentationDetents([.medium, .large])
      .padding()
    }
    .background(.background.secondary)
    
  }

  private func deleteIngredient (_ ingredient: Ingredient) {
    // Remove from recipe if needed
    if let recipe = ingredient.recipe {
      recipe.ingredients.removeAll(where: { $0.id == ingredient.id })
    }
    
    // Remove from section if needed
    if let section = ingredient.section {
      section.ingredients.removeAll(where: { $0.id == ingredient.id })
    }
    
    // Delete from context
    context.delete(ingredient)
    
    do {
      try context.save()
    } catch {
      print("Error deleting empty ingredient: \(error)")
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
    showDeleteConfirmation = false
    dismiss()
  }
  
  // Ingredient Selection Methods
  
  // Create a binding for the selectable modifier
  private func selectableBinding(for ingredient: Ingredient) -> Binding<Bool> {
    Binding(
      get: { selectedIngredients.contains(ingredient) },
      set: { isSelected in
        if isSelected {
          selectedIngredients.insert(ingredient)
        } else {
          selectedIngredients.remove(ingredient)
        }
      }
    )
  }
  
  // Toggle selection for an ingredient
  private func toggleSelection(for ingredient: Ingredient) {
    if selectedIngredients.contains(ingredient) {
      selectedIngredients.remove(ingredient)
    } else {
      selectedIngredients.insert(ingredient)
    }
  }
  
  // Add selected ingredients to grocery list
  private func addSelectedToGroceryList() {
    for ingredient in selectedIngredients {
      // Create a copy of the ingredient for the grocery list
      let groceryItem = Ingredient(
        name: ingredient.name,
        location: .grocery,  // Change location to grocery
        quantity: ingredient.quantity,
        unit: ingredient.unit?.rawValue,
        comment: ingredient.comment
      )
      
      // Add to context
      context.insert(groceryItem)
    }
    
    // Save changes
    do {
      try context.save()
      
      // Clear selection
      clearSelection()
    } catch {
      print("Error saving grocery items: \(error)")
    }
  }
  
  // Clear the current selection
  private func clearSelection() {
    selectedIngredients.removeAll()
  }
  private func selectAll() {
    // Get all unsectioned ingredients
    let unsectionedIngredients = recipe.ingredients.filter { $0.section == nil }
    
    // Add all unsectioned ingredients to selection
    for ingredient in unsectionedIngredients {
      selectedIngredients.insert(ingredient)
    }
    
    // Add all sectioned ingredients to selection
    for section in recipe.sections {
      for ingredient in section.ingredients {
        selectedIngredients.insert(ingredient)
      }
    }
  }
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
