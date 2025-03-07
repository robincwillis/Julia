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
  
  @State private var showingDeleteConfirmation = false
  @State private var selectedIngredient: Ingredient?
  @State private var showingIngredientEditor = false
  @State private var selectedIngredients: Set<Ingredient> = []
  
  @FocusState private var isTextFieldFocused: Bool
  
  let debug = false
  
  var rawTextString: String {
    recipe.rawText?.joined(separator: "\n") ?? ""
  }
  
  var body: some View {
    ZStack {
      if (isEditing) {
        Form {
          // Title and Summary
          Section {
            TextField("Recipe Title", text: $recipe.title)
              .font(.title)
              .focused($isTextFieldFocused)
              .submitLabel(.done)
            
            TextField("Recipe summary", text: Binding(
                get: { recipe.summary ?? "" },
                set: { recipe.summary = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(3...6)
            .focused($isTextFieldFocused)
            .submitLabel(.done)
          }
          
          // Ingredients section
          Section(header: Text("Ingredients")) {
            if recipe.ingredients.isEmpty {
              Text("No ingredients added")
                .foregroundColor(.gray)
            } else {
              ForEach(recipe.ingredients) { ingredient in
                HStack {
                  Text(ingredient.name)
                  Spacer()
                  Button(action: {
                    selectedIngredient = ingredient
                    showingIngredientEditor = true
                  }) {
                    Image(systemName: "pencil")
                      .foregroundColor(.blue)
                  }
                }
              }
              .onDelete { indices in
                recipe.ingredients.remove(atOffsets: indices)
              }
              .onMove { from, to in
                recipe.ingredients.move(fromOffsets: from, toOffset: to)
              }
            }
            
            Button(action: {
              let newIngredient = Ingredient(name: "New Ingredient", location: .recipe)
              recipe.ingredients.append(newIngredient)
              selectedIngredient = newIngredient
              showingIngredientEditor = true
            }) {
              Label("Add Ingredient", systemImage: "plus")
                .foregroundColor(.blue)
            }
          }
          
          // Instructions section
          Section(header: Text("Instructions")) {
            if recipe.instructions.isEmpty {
              Text("No instructions added")
                .foregroundColor(.gray)
            } else {
              ForEach(Array(recipe.instructions.enumerated()), id: \.element) { index, _ in
                TextField("Step \(index + 1)", text: $recipe.instructions[index], axis: .vertical)
                  .focused($isTextFieldFocused)
              }
              .onDelete { indices in
                recipe.instructions.remove(atOffsets: indices)
              }
              .onMove { from, to in
                recipe.instructions.move(fromOffsets: from, toOffset: to)
              }
            }
            
            Button(action: {
              recipe.instructions.append("New step")
            }) {
              Label("Add Step", systemImage: "plus")
                .foregroundColor(.blue)
            }
          }
        }
        .background(Color(.secondarySystemBackground))
        .listStyle(.insetGrouped)
        
      } else {
        ScrollView(.vertical, showsIndicators: true) {
          VStack(alignment: .leading, spacing: 8) {
            // Title and Summary Section
            RecipeTitleSection(
              recipe: recipe
            )
            
            // Ingredients Section with selectable ingredients
            VStack(alignment: .leading, spacing: 16) {
              Text("Ingredients")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 8)
              
              if recipe.ingredients.isEmpty && recipe.sections.isEmpty {
                Text("No ingredients available")
                  .foregroundColor(.gray)
                  .padding(.vertical, 8)
              } else {
                // Display unsectioned ingredients first
                let unsectionedIngredients = recipe.ingredients.filter { $0.section == nil }
                if !unsectionedIngredients.isEmpty {
                  VStack(alignment: .leading, spacing: 8) {
                    ForEach(unsectionedIngredients) { ingredient in
                      IngredientRow(ingredient: ingredient, padding: 3)
                        .selectable(selected: selectableBinding(for: ingredient))
                        .contentShape(Rectangle())
                        .onTapGesture {
                          toggleSelection(for: ingredient)
                        }
                    }
                  }
                  .padding(.bottom, 8)
                }
                
                // Display sections
                ForEach(recipe.sections.sorted(by: { $0.position < $1.position })) { section in
                  VStack(alignment: .leading, spacing: 8) {
                    Text(section.name)
                      .font(.subheadline)
                      .fontWeight(.semibold)
                      .foregroundColor(.secondary)
                      .padding(.top, 8)
                      .padding(.bottom, 4)
                    
                    if section.ingredients.isEmpty {
                      Text("No ingredients in this section")
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                        .padding(.leading, 8)
                    } else {
                      ForEach(section.ingredients) { ingredient in
                        IngredientRow(ingredient: ingredient, padding: 3)
                          .selectable(selected: selectableBinding(for: ingredient))
                          .contentShape(Rectangle())
                          .onTapGesture {
                            toggleSelection(for: ingredient)
                          }
                      }
                    }
                  }
                  .padding(.bottom, 8)
                }
              }
            }
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            
            // Instructions Section
            RecipeInstructionsSection(
              recipe: recipe
            )
          }
          .padding(16)
        }
        .background(Color(.white))
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          if !selectedIngredients.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
              Menu {
                Button(action: addSelectedToGroceryList) {
                  Label("Add to Grocery List", systemImage: "cart.fill.badge.plus")
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
      FloatingBottomSheet(isPresented: $showingIngredientEditor) {
        IngredientEditorView(
          ingredient: $selectedIngredient,
          showBottomSheet: $showingIngredientEditor
        )
      }.onChange(of: showingIngredientEditor) {
        // Remove selectedIngredient if sheet is dismissed
        if(showingIngredientEditor == false) {
          selectedIngredient = nil
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        if isEditing {
          Menu {
            Button("Show Raw Text", systemImage: "xmark") {
              // TODO Move to Sheet
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
              //.font(.system(size: 14))
              .foregroundColor(.blue)
              .padding(12)
              .frame(width: 40, height: 40)
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
                      isPresented: $showingDeleteConfirmation,
                      titleVisibility: .visible
    ) {
      Button("Delete Recipe", role: .destructive) {
        deleteRecipe()
      }
    }
    .sheet(isPresented: $showingIngredientEditor) {

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
//    .onChange(of: editMode?.wrappedValue) { oldValue, newValue in
//      if newValue?.isEditing == true && (oldValue?.isEditing == false || oldValue?.isEditing == nil) {
//        // Entering edit mode - add test data if needed
//  
//      } else if newValue?.isEditing == false && oldValue?.isEditing == true {
//        // Exiting edit mode - changes are already saved
//        print("Exiting edit mode")
//        
//        // Explicitly save context to be safe
//        do {
//          try context.save()
//        } catch {
//          print("Error saving context: \(error)")
//        }
//      }
//    }
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
  
  // MARK: - Ingredient Selection Methods
  
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
