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

  var body: some View {
    Text("Ingredients")
      .font(.headline)
    
    if recipe.ingredients.isEmpty && recipe.sections.isEmpty {
      Text("No ingredients available")
        .foregroundColor(.gray)
        .padding(.vertical, 8)
    } else {
      // Display unsectioned ingredients first
      let unsectionedIngredients = recipe.ingredients.filter { $0.section == nil }
      if !unsectionedIngredients.isEmpty {
        ForEach(unsectionedIngredients, id: \.id) { ingredient in
          IngredientRow(ingredient: ingredient, padding: 3)
        }
      }
      
      // Display sections with their ingredients
      ForEach(recipe.sections.sorted(by: { $0.position < $1.position }), id: \.id) { section in
        VStack(alignment: .leading, spacing: 6) {
          Text(section.name)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.top, 8)
            .padding(.bottom, 4)
          
          ForEach(section.ingredients, id: \.id) { ingredient in
            IngredientRow(ingredient: ingredient, padding: 3)
          }
        }
      }
    }
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
                )
            )
        }
    }
    
    return PreviewWrapper()
}
