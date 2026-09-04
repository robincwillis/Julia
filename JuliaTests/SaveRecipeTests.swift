//
//  SaveRecipeTests.swift
//  JuliaTests
//
//  Coverage for RecipeProcessor.saveRecipe — the path the review sheet's Save
//  button drives. It became async when the Foundation Models ingredient parser
//  was wired in, and had no tests.
//

import Testing
import SwiftData
import Foundation
@testable import Julia

@Suite("Saving a reviewed recipe")
@MainActor
struct SaveRecipeTests {

    /// The container **must** be returned and held for the life of the test.
    /// A `ModelContext` does not keep its container alive, so letting the
    /// container go out of scope leaves the context dangling and crashes the
    /// test process at the first use — with no assertion failure to explain it.
    @MainActor
    private struct Store {
        let container: ModelContainer
        let processor: RecipeProcessor
        var context: ModelContext { container.mainContext }
    }

    private func makeStore() throws -> Store {
        let container = try ModelContainer(
            for: DataController.appSchema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return Store(
            container: container,
            processor: RecipeProcessor(modelContext: container.mainContext)
        )
    }

    private var sampleData: RecipeData {
        var data = RecipeData()
        data.title = "Test Loaf"
        data.ingredients = ["2 cups flour", "1 tsp salt", "300 ml water"]
        data.instructions = ["Mix everything.", "Bake for an hour."]
        data.servings = ["Serves 4"]
        return data
    }

    @Test("Saving persists a recipe and reports success", .timeLimit(.minutes(2)))
    func savePersists() async throws {
        let store = try makeStore()
        store.processor.recipeData = sampleData

        let saved = await store.processor.saveRecipe()
        #expect(saved, "saveRecipe returned false — the Save button would appear to do nothing")

        let recipes = try store.context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == 1)
        #expect(recipes.first?.title == "Test Loaf")
        #expect(recipes.first?.ingredients.count == 3)
    }

    @Test("Saving without a model context fails loudly rather than silently")
    func saveWithoutContext() async {
        let processor = RecipeProcessor()   // no context
        processor.recipeData = sampleData

        let saved = await processor.saveRecipe()
        #expect(!saved)
        #expect(!processor.processingState.errorMessage.isEmpty,
                "a failed save must leave a message the UI can show")
    }

    @Test("An ingredient the heuristic is unsure of still saves",
          .timeLimit(.minutes(3)))
    func saveWithEscalatingIngredient() async throws {
        let store = try makeStore()
        var data = sampleData
        // Scores 0.6 and 0.3 respectively, so these take the model path when it
        // is available and the heuristic path when it is not. Either way the
        // save must complete and persist every ingredient.
        data.ingredients = ["1 1/2 cups flour", "Pinch of salt", "2 cups flour"]
        store.processor.recipeData = data

        let saved = await store.processor.saveRecipe()
        #expect(saved)

        let recipes = try store.context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.first?.ingredients.count == 3,
                "an escalated ingredient must not be dropped")
    }

    @Test("Saving replaces the auto-saved copy instead of duplicating it",
          .timeLimit(.minutes(2)))
    func saveDeduplicatesAutoSave() async throws {
        let store = try makeStore()

        // processData auto-saves immediately, then the user reviews and saves.
        store.processor.processData(sampleData, immediatePresentation: true)
        let afterAutoSave = try store.context.fetch(FetchDescriptor<Recipe>()).count
        #expect(afterAutoSave == 1, "processData should have auto-saved one copy")

        let saved = await store.processor.saveRecipe()
        #expect(saved)

        let recipes = try store.context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == 1, "the auto-saved copy should have been replaced, not kept")
    }
}
