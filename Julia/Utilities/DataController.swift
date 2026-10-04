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

  static let appSchema: Schema = {
    Schema([
      Ingredient.self,
      Recipe.self,
      Timing.self,
      IngredientSection.self,
      InstructionSection.self,
      Note.self,
      Step.self,
      ImageItem.self
    ], version: Schema.Version(2, 2, 4))
  }()

  static func clearAllData(in context: ModelContext) async throws {
    let recipesDescriptor = FetchDescriptor<Recipe>()
    let recipes = try context.fetch(recipesDescriptor)

    for recipe in recipes {
      recipe.ingredients = []
      recipe.sections = []
      recipe.timings = []
      recipe.instructions = []
      recipe.instructionSections = []
      recipe.notes = []
      recipe.images = []

      context.delete(recipe)
    }

    let ingredientsDescriptor = FetchDescriptor<Ingredient>(
      predicate: #Predicate<Ingredient> { $0.recipe == nil && $0.section == nil }
    )
    let ingredients = try context.fetch(ingredientsDescriptor)

    for ingredient in ingredients {
      context.delete(ingredient)
    }

    try context.save()
  }

  /// Set synchronously if the on-disk store failed to load and the app fell back to an
  /// in-memory container — meaning nothing persists for the rest of this run. Read this
  /// (not a notification) to detect the fallback: `appContainer` is force-initialized by
  /// `.modelContainer(...)` before the app's view hierarchy appears, so anything relying on
  /// `.onAppear`-registered observers is too late to catch the failure.
  static private(set) var containerLoadError: Error?
  static var isRunningInMemoryFallback: Bool { containerLoadError != nil }

  static let appContainer: ModelContainer = {
    do {
      return try ModelContainer(for: appSchema)
    } catch {
      print("Error creating app container: \(error.localizedDescription)")
      containerLoadError = error

      // Crash in development so a schema mistake is caught immediately.
      assertionFailure("Failed to create app container: \(error.localizedDescription)")

      // In production, degrade instead of crashing: an in-memory container over
      // the same schema keeps the app usable and read-consistent for the
      // session. `containerLoadError` above drives the user-facing alert.
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

  static let previewContainer: ModelContainer = {
    do {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try ModelContainer(for: appSchema, configurations: config)
      return container
    } catch {
      print("Error creating preview container: \(error.localizedDescription)")
      fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
  }()
}
