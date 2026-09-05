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
  
  // MARK: - Schema Definition
  
  /// Application schema with versioning
  static let appSchema: Schema = {
    Schema([
      Ingredient.self,
      Recipe.self,
      Timing.self,
      IngredientSection.self,
      Note.self,
      Step.self,
      ImageItem.self
    ], version: Schema.Version(2, 2, 2))
  }()
  
  // MARK: - Data Management
  
  /// Clears all data from the model context
  static func clearAllData(in context: ModelContext) async throws {
    // First fetch and delete all recipes (which should cascade to related objects)
    let recipesDescriptor = FetchDescriptor<Recipe>()
    let recipes = try context.fetch(recipesDescriptor)
    
    for recipe in recipes {
      // First clear relationships to avoid issues with deletion
      recipe.ingredients = []
      recipe.sections = []
      recipe.timings = []
      recipe.instructions = []
      recipe.notes = []
      recipe.images = []
      
      // Then delete the recipe
      context.delete(recipe)
    }
    
    // Delete standalone ingredients (not associated with recipes)
    let ingredientsDescriptor = FetchDescriptor<Ingredient>(
      predicate: #Predicate<Ingredient> { $0.recipe == nil && $0.section == nil }
    )
    let ingredients = try context.fetch(ingredientsDescriptor)
    
    for ingredient in ingredients {
      context.delete(ingredient)
    }
    
    // Save changes
    try context.save()
  }
  
  // MARK: - Containers
  
  /// Main application container for persistent storage
  static let appContainer: ModelContainer = {
    do {
      return try ModelContainer(for: appSchema)
    } catch {
      print("Error creating app container: \(error.localizedDescription)")
      // Post notification for app to display user-facing error
      NotificationCenter.default.post(
        name: NSNotification.Name("ModelContainerError"),
        object: error
      )
      // Crash in development so a schema mistake is caught immediately.
      assertionFailure("Failed to create app container: \(error.localizedDescription)")

      // In production, degrade instead of crashing: an in-memory container over
      // the same schema keeps the app usable and read-consistent for the
      // session, and the notification above drives the user-facing alert.
      //
      // Previously this force-tried a *second* on-disk container — inside the
      // handler for the first one failing — so the usual outcome was a crash
      // moments after going to the trouble of reporting the error. It also used
      // a different schema (Ingredient only), which would have failed on any
      // Recipe query anyway.
      if let fallback = try? ModelContainer(
        for: appSchema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      ) {
        return fallback
      }

      // Nothing left to try: the schema itself cannot be realised.
      fatalError("Failed to create any container for the app schema: \(error.localizedDescription)")
    }
  }()
  
  /// In-memory container for previews
  static let previewContainer: ModelContainer = {
    do {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try ModelContainer(for: appSchema, configurations: config)
      
      // Pre-populate with sample data right away (from MockData)
      // MockData.setupPreviewData(in: container)
      
      return container
    } catch {
      print("Error creating preview container: \(error.localizedDescription)")
      // Crash only in development builds - this should never fail with proper schemas
      fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
  }()
}
