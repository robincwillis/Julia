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
              IngredientRow(ingredient: ingredient)
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
  Previews.recipeComponent { recipe in
    RecipeIngredientsSection(
      recipe: recipe,
      selectableBinding: { _ in .constant(false) },
      toggleSelection: { _ in }
    )
    .padding()
  }
}



