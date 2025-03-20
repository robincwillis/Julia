//
//  DataController.swift
//  Julia
//
//  Created by Robin Willis on 11/6/24.
//

import SwiftData
import SwiftUI
import Foundation

@MainActor
class DataController {
  // MARK: - Preview Helpers
  
  // A special struct for creating reliable previews
  struct PreviewData {
    // Static container for previews to ensure it stays alive for the entire preview session
    // We use a non-MainActor isolated initialization for the container as it's safe
    static let container: ModelContainer = createPreviewContainer()
    
    // Sample data initializer to ensure MainActor isolation
    // Call this when the app starts to prepare sample data
    @MainActor static func initialize() {
      // Create and insert sample data only once
      if !_dataInitialized {
        createSampleData()
        _dataInitialized = true
      }
    }
    
    // Track if we've initialized the data
    private static var _dataInitialized = false
    
    // References to sample data
    private static var _sampleTiming1: Timing?
    private static var _sampleTiming2: Timing?
    private static var _sampleIngredient: Ingredient?
    private static var _sampleRecipe: Recipe?
    
    // Sample data getters with lazy initialization
    @MainActor static var sampleTiming1: Timing {
      if _sampleTiming1 == nil {
        initialize()
      }
      return _sampleTiming1!
    }
    
    @MainActor static var sampleTiming2: Timing {
      if _sampleTiming2 == nil {
        initialize()
      }
      return _sampleTiming2!
    }
    
    @MainActor static var sampleIngredient: Ingredient {
      if _sampleIngredient == nil {
        initialize()
      }
      return _sampleIngredient!
    }
    
    @MainActor static var sampleRecipe: Recipe {
      if _sampleRecipe == nil {
        initialize()
      }
      return _sampleRecipe!
    }
    
    // Create all sample data at once inside a MainActor context
    @MainActor private static func createSampleData() {
      // Create sample timing objects
      let timing1 = Timing(type: "Prep", hours: 0, minutes: 15)
      let timing2 = Timing(type: "Cook", hours: 1, minutes: 30)
      
      // Create sample ingredient
      let ingredient = Ingredient(name: "Flour", location: .recipe, quantity: 2, unit: "cup")
      
      // Create sample recipe
      let recipe = Recipe(
        title: "Sample Recipe",
        summary: "A delicious sample recipe",
        ingredients: [],
        instructions: ["Step 1: Mix ingredients", "Step 2: Cook thoroughly"],
        timings: [timing1, timing2]
      )
      
      // Insert everything into the container
      container.mainContext.insert(timing1)
      container.mainContext.insert(timing2)
      container.mainContext.insert(ingredient)
      container.mainContext.insert(recipe)
      
      // Store references
      _sampleTiming1 = timing1
      _sampleTiming2 = timing2
      _sampleIngredient = ingredient
      _sampleRecipe = recipe
    }
    
    // Helper to create a standalone container without messing with the static one
    static func createPreviewContainer() -> ModelContainer {
      do {
        // Create a completely fresh in-memory configuration with schema options
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema([
          Ingredient.self,
          Recipe.self, 
          Timing.self,
          IngredientSection.self
        ], version: Schema.Version(2, 2, 0))
        return try ModelContainer(for: schema, configurations: config)
      } catch {
        print("Error creating preview container: \(error.localizedDescription)")
        return fallbackContainer()
      }
    }
    
    private static func fallbackContainer() -> ModelContainer {
      // A minimal container that should always work
      do {
        return try ModelContainer(for: Schema([Ingredient.self]))
      } catch {
        fatalError("Could not create even a minimal preview container: \(error)")
      }
    }
  }
  
  // Keep the older API for backward compatibility, but use the new PreviewData under the hood
  static var previewContainer: ModelContainer {
    return PreviewData.container
  }
  
  // This now just references the same static container
  static func resetPreviewContainer() -> ModelContainer {
    return PreviewData.container
  }
  
  // Simple preview helper
  // Usage: DataController.makePreview { YourContent() }
  static func makePreview<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
      .modelContainer(PreviewData.container)
  }
  
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
  
  // This is only used for previews/tests
  private static func createFallbackContainer() -> ModelContainer {
    do {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let schema = Schema([
        Ingredient.self,
        Recipe.self,
        Timing.self,
        IngredientSection.self
      ], version: Schema.Version(2, 2, 0))
      return try ModelContainer(for: schema, configurations: config)
    } catch {
      // Last resort - empty container with minimal schema
      return try! ModelContainer(for: Ingredient.self)
    }
  }
  
  // This is used for production fallback
  private static func createPersistentFallbackContainer() -> ModelContainer {
    do {
      // Minimal schema but still persistent
      let minimalSchema = Schema([Ingredient.self])
      return try ModelContainer(for: minimalSchema)
    } catch {
      // Absolute last resort - create simple container for one model
      return try! ModelContainer(for: Ingredient.self)
    }
  }
  
  static let appContainer: ModelContainer = {
    do {
      // Use the same schema as preview but without in-memory flag
      let schema = Schema([
        Ingredient.self,
        Recipe.self,
        Timing.self,
        IngredientSection.self
      ], version: Schema.Version(2, 2, 0))
      return try ModelContainer(for: schema)
    } catch {
      print("Error creating app container: \(error.localizedDescription)")
      // In production, we use a user-facing alert instead of crashing
      NotificationCenter.default.post(
        name: NSNotification.Name("ModelContainerError"),
        object: error
      )
      // Don't use in-memory container for fallback in production
      return createPersistentFallbackContainer()
    }
  }()
}
