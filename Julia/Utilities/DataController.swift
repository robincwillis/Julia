//
//  DataController.swift
//  Julia
//
//  Created by Robin Willis on 11/6/24.
//

import SwiftData

@MainActor
class DataController {
  static let previewContainer: ModelContainer = {
    do {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try ModelContainer(for: Ingredient.self, Recipe.self, configurations: config)
      for mockIngredient in mockIngredients {
        let ingredient = Ingredient(name: mockIngredient.name, location: mockIngredient.location, quantity: mockIngredient.quantity)
        container.mainContext.insert(ingredient)
      }
      for mockRecipe in mockRecipes {
        var recipe = Recipe(title: mockRecipe.title, content: mockRecipe.content, steps: mockRecipe.steps)
        container.mainContext.insert(recipe)
        
        for mockIngredient in mockRecipe.ingredients {
          let ingredient = Ingredient(name: mockIngredient.name, location: IngredientLocation.recipe, quantity: mockIngredient.quantity)
          recipe.ingredients.append(ingredient)
        }
        
      }
      return container
    } catch {
      fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
    }
  }()
  
  static let appContainer: ModelContainer = {
    do {
      let container = try ModelContainer(for: Ingredient.self, Recipe.self)
      return container
    } catch {
      fatalError("Failed to create ModelContainer for Ingredients.")
    }
  }()
}
