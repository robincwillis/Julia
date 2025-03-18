//
//  DataController.swift
//  Julia
//
//  Created by Robin Willis on 11/6/24.
//

import SwiftData
import Foundation

@MainActor
class DataController {
  static let previewContainer: ModelContainer = {
    do {
      // Create a completely fresh in-memory configuration with schema options
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let schema = Schema([
        Ingredient.self,
        Recipe.self,
        Timing.self,
        IngredientSection.self
      ], version: Schema.Version(2, 1, 0))
      let container = try ModelContainer(for: schema, configurations: config)
      
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
      // Create recipe with the updated model structure
      let recipe = Recipe(
        title: mockRecipe.title, 
        summary: mockRecipe.content, 
        instructions: mockRecipe.steps, 
        timings: [],
        rawText: mockRecipe.rawText
        // time is optional so we don't need to provide it
      )
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
      let schema = Schema([
        Ingredient.self,
        Recipe.self,
        Timing.self,
        IngredientSection.self
      ])
      return try ModelContainer(for: schema, configurations: config)
    } catch {
      // Last resort - empty container with minimal schema
      return try! ModelContainer(for: Ingredient.self)
    }
  }
  
  static let appContainer: ModelContainer = {
    do {
      return try ModelContainer(for: Ingredient.self, Recipe.self, Timing.self)
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
