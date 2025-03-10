//
//  RecipeIngredientsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI
import SwiftData

struct RecipeIngredientsSection: View {
  let recipe: Recipe
  let selectableBinding: (Ingredient) -> Binding<Bool>
  let toggleSelection: (Ingredient) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
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
                .selectable(selected: selectableBinding(ingredient))
                .contentShape(Rectangle())
                .onTapGesture {
                  toggleSelection(ingredient)
                }
            }
          }
          .padding(.bottom, 8)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var ingredients: [Ingredient] = [
            Ingredient(name: "Flour", location: .recipe, unit: "cup"),
            Ingredient(name: "Sugar", location: .recipe, unit: "cup")
        ]
        @State private var sections: [IngredientSection] = []
        @State private var selectedIngredient: Ingredient?
        @State private var showEditor = false
        @FocusState private var focused: Bool
        
        var body: some View {
            RecipeIngredientsSection(
                recipe: Recipe(
                    title: "Sample Recipe",
                    summary: "A delicious sample recipe",
                    ingredients: ingredients,
                    instructions: []
                ),
                selectableBinding: { _ in .constant(false) },
                toggleSelection: { _ in }
            )
        }
    }
    
    return PreviewWrapper()
}
