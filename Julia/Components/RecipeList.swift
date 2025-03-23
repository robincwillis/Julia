//
//  RecipeList.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData

struct RecipeList: View {
    let recipes: [Recipe]
    var body: some View {
        List {
            ForEach(recipes, id: \.id) { recipe in
                NavigationLink {
                    RecipeDetails(recipe: recipe)
                } label: {
                    RecipeRow(recipe: recipe)
                }
            }
            
            // Add spacer at the end for tab bar
            Section {
                Color.clear
                    .frame(height: 90) // Height of tab bar + extra padding
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
}

#Preview("Recipe List") {
  Previews.previewModels(with: { context in
    // Create sample recipes
    let recipe1 = Recipe(
      title: "Chocolate Chip Cookies",
      summary: "Classic homemade cookies with chocolate chips",
      instructions: ["Mix ingredients", "Bake at 350°F for 12 minutes"]
    )
    
    let recipe2 = Recipe(
      title: "Pasta Primavera",
      summary: "Light pasta dish with spring vegetables",
      instructions: ["Cook pasta", "Sauté vegetables", "Combine and serve"]
    )
    
    let recipe3 = Recipe(
      title: "Greek Salad",
      summary: "Fresh Mediterranean salad with feta cheese",
      instructions: ["Chop vegetables", "Add dressing", "Top with feta"]
    )
    
    // Insert recipes into context
    context.insert(recipe1)
    context.insert(recipe2)
    context.insert(recipe3)
    
    // Return the array of recipes
    return [recipe1, recipe2, recipe3]
  }) { recipes in
    // Content closure receives the recipes array
    RecipeList(recipes: recipes)
  }
}
