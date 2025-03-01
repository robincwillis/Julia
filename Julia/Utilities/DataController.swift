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
      
      // Add mock data
      try? addMockData(to: container)
      return container
    } catch {
      print("Error creating preview container: \(error.localizedDescription)")
      return createFallbackContainer()
    }
  }()
  
  private static func addMockData(to container: ModelContainer) throws {
    for mockIngredient in mockIngredients {
      let ingredient = Ingredient(name: mockIngredient.name, location: mockIngredient.location, quantity: mockIngredient.quantity)
      container.mainContext.insert(ingredient)
    }
    
    for mockRecipe in mockRecipes {
      var recipe = Recipe(title: mockRecipe.title, summary: mockRecipe.content, instructions: mockRecipe.steps, rawText: mockRecipe.rawText)
      container.mainContext.insert(recipe)
      
      for mockIngredient in mockRecipe.ingredients {
        let ingredient = Ingredient(name: mockIngredient.name, location: IngredientLocation.recipe, quantity: mockIngredient.quantity)
        recipe.ingredients.append(ingredient)
      }
    }
  }
  
  private static func createFallbackContainer() -> ModelContainer {
    do {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      return try ModelContainer(for: [], configurations: config)
    } catch {
      // Last resort - empty container
      return try! ModelContainer(for: [])
    }
  }
  
  static let appContainer: ModelContainer = {
    do {
      return try ModelContainer(for: Ingredient.self, Recipe.self)
    } catch {
      print("Error creating app container: \(error.localizedDescription)")
      // In production, we use a user-facing alert instead of crashing
      NotificationCenter.default.post(
        name: NSNotification.Name("ModelContainerError"),
        object: error
      )
      return createFallbackContainer()
    }
  }()
}
