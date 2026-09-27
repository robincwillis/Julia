//
//  ImportExportTests.swift
//  JuliaTests
//
//  Tests for the import/export pipeline — JSON decoding, round-trip fidelity,
//  backward compatibility with exports that predate the instructionSections field,
//  and uniqueness-constraint safety when loading multiple recipes at once.
//

import Testing
import SwiftData
import Foundation
@testable import Julia

@Suite("Import/Export")
@MainActor
struct ImportExportTests {

    @MainActor
    private struct Store {
        let container: ModelContainer
        var context: ModelContext { container.mainContext }
    }

    private func makeStore() throws -> Store {
        let container = try ModelContainer(
            for: DataController.appSchema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return Store(container: container)
    }

    // MARK: - JSON Decoding

    @Test("RecipeExport decodes current format with instructionSections")
    func decodeCurrentFormat() throws {
        let json = """
        [{
          "id": "r1", "title": "Test", "summary": null, "servings": 4,
          "tags": ["test"], "rawText": [], "source": null, "sourceType": null,
          "sourceTitle": null, "website": null, "author": null,
          "ingredients": [], "sections": [],
          "timings": [{"id": "t-1", "type": "Prep", "hours": 0, "minutes": 10}],
          "instructions": [{"id": "s-1", "value": "Mix it.", "position": 0}],
          "instructionSections": [],
          "notes": []
        }]
        """
        let recipes = try JSONDecoder().decode([ImportExportManager.RecipeExport].self, from: Data(json.utf8))
        #expect(recipes.count == 1)
        #expect(recipes[0].title == "Test")
        #expect(recipes[0].instructions.count == 1)
        #expect(recipes[0].instructionSections?.isEmpty == true)
    }

    @Test("RecipeExport decodes old format without instructionSections (backward compat)")
    func decodeOldFormatMissingInstructionSections() throws {
        let json = """
        [{
          "id": "r-old", "title": "Old Recipe", "summary": null, "servings": null,
          "tags": [], "rawText": null, "source": null, "sourceType": null,
          "sourceTitle": null, "website": null, "author": null,
          "ingredients": [], "sections": [], "timings": [], "instructions": [],
          "notes": []
        }]
        """
        // Should not throw — missing instructionSections is treated as nil/empty.
        let recipes = try JSONDecoder().decode([ImportExportManager.RecipeExport].self, from: Data(json.utf8))
        #expect(recipes.count == 1)
        #expect(recipes[0].instructionSections == nil)
    }

    // MARK: - Import

    @Test("Importing multiple recipes with unique IDs creates all of them", .timeLimit(.minutes(1)))
    func importMultipleRecipes() async throws {
        let store = try makeStore()

        let json = """
        [
          {
            "id": "import-r1", "title": "Recipe One", "summary": null, "servings": 2,
            "tags": [], "rawText": [], "source": null, "sourceType": null,
            "sourceTitle": null, "website": null, "author": null,
            "ingredients": [{"id": "ing-r1-1", "name": "Salt", "location": "recipe", "quantity": 1, "unit": "teaspoon", "comment": null, "position": 0}],
            "sections": [],
            "timings": [{"id": "timing-r1-prep", "type": "Prep", "hours": 0, "minutes": 10}],
            "instructions": [{"id": "step-r1-1", "value": "Mix it.", "position": 0}],
            "instructionSections": [],
            "notes": [{"id": "note-r1-1", "text": "A note.", "position": 0}]
          },
          {
            "id": "import-r2", "title": "Recipe Two", "summary": null, "servings": 4,
            "tags": [], "rawText": [], "source": null, "sourceType": null,
            "sourceTitle": null, "website": null, "author": null,
            "ingredients": [],
            "sections": [],
            "timings": [{"id": "timing-r2-cook", "type": "Cook", "hours": 1, "minutes": 0}],
            "instructions": [{"id": "step-r2-1", "value": "Cook it.", "position": 0}],
            "instructionSections": [],
            "notes": [{"id": "note-r2-1", "text": "Another note.", "position": 0}]
          }
        ]
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("import-test.json")
        try Data(json.utf8).write(to: url)

        let count = try await ImportExportManager.importRecipesFile(from: url, context: store.context)
        #expect(count == 2)

        let recipes = try store.context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == 2)

        let r1 = recipes.first { $0.id == "import-r1" }
        let r2 = recipes.first { $0.id == "import-r2" }
        #expect(r1?.title == "Recipe One")
        #expect(r1?.ingredients.count == 1)
        #expect(r1?.timings.count == 1)
        #expect(r1?.instructions.count == 1)
        #expect(r1?.notes.count == 1)
        #expect(r2?.title == "Recipe Two")
    }

    @Test("Importing the same recipe twice updates rather than duplicating", .timeLimit(.minutes(1)))
    func importIsIdempotent() async throws {
        let store = try makeStore()

        let base = """
        [{"id": "dedup-r1", "title": "Version 1", "summary": null, "servings": null,
          "tags": [], "rawText": [], "source": null, "sourceType": null,
          "sourceTitle": null, "website": null, "author": null,
          "ingredients": [], "sections": [], "timings": [], "instructions": [],
          "instructionSections": [], "notes": []}]
        """
        let updated = """
        [{"id": "dedup-r1", "title": "Version 2", "summary": null, "servings": null,
          "tags": [], "rawText": [], "source": null, "sourceType": null,
          "sourceTitle": null, "website": null, "author": null,
          "ingredients": [], "sections": [], "timings": [], "instructions": [],
          "instructionSections": [], "notes": []}]
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("idempotent-test.json")

        try Data(base.utf8).write(to: url)
        _ = try await ImportExportManager.importRecipesFile(from: url, context: store.context)

        try Data(updated.utf8).write(to: url)
        _ = try await ImportExportManager.importRecipesFile(from: url, context: store.context)

        let recipes = try store.context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == 1, "second import should update the existing recipe, not duplicate it")
        #expect(recipes.first?.title == "Version 2")
    }

    @Test("Importing old-format JSON (no instructionSections) succeeds", .timeLimit(.minutes(1)))
    func importOldFormatSucceeds() async throws {
        let store = try makeStore()

        let json = """
        [{"id": "old-fmt-1", "title": "Old Recipe", "summary": null, "servings": null,
          "tags": [], "rawText": null, "source": null, "sourceType": null,
          "sourceTitle": null, "website": null, "author": null,
          "ingredients": [], "sections": [],
          "timings": [{"id": "timing-old-1", "type": "Prep", "hours": 0, "minutes": 5}],
          "instructions": [{"id": "step-old-1", "value": "Do the thing.", "position": 0}],
          "notes": []}]
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("old-format-test.json")
        try Data(json.utf8).write(to: url)

        let count = try await ImportExportManager.importRecipesFile(from: url, context: store.context)
        #expect(count == 1)

        let recipes = try store.context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == 1)
        #expect(recipes.first?.title == "Old Recipe")
        #expect(recipes.first?.instructionSections.isEmpty == true)
    }

    // MARK: - Round-trip

    @Test("Export then import preserves recipe structure", .timeLimit(.minutes(1)))
    func roundTrip() async throws {
        let store = try makeStore()

        let recipe = Recipe(
            id: "rt-1",
            title: "Round Trip Recipe",
            summary: "A round-trip test recipe",
            servings: 4,
            tags: ["test"]
        )
        let step = Step(id: "rt-step-1", value: "Do everything.", position: 0)
        recipe.instructions = [step]
        let timing = Timing(id: "rt-timing-1", type: "Prep", hours: 0, minutes: 20)
        recipe.timings = [timing]
        store.context.insert(recipe)
        try store.context.save()

        let exportURL = try await ImportExportManager.createRecipesExport(context: store.context)

        // Clear store
        for r in try store.context.fetch(FetchDescriptor<Recipe>()) {
            store.context.delete(r)
        }
        try store.context.save()

        let count = try await ImportExportManager.importRecipesFile(from: exportURL, context: store.context)
        #expect(count == 1)

        let imported = try store.context.fetch(FetchDescriptor<Recipe>())
        let r = try #require(imported.first)
        #expect(r.id == "rt-1")
        #expect(r.title == "Round Trip Recipe")
        #expect(r.summary == "A round-trip test recipe")
        #expect(r.servings == 4)
        #expect(r.tags == ["test"])
        #expect(r.instructions.count == 1)
        #expect(r.instructions.first?.value == "Do everything.")
        #expect(r.timings.count == 1)
        #expect(r.timings.first?.type == "Prep")
    }

    // MARK: - ID uniqueness

    @Test("All IDs across three sample recipes are globally unique", .timeLimit(.minutes(1)))
    func sampleRecipeIDsAreUnique() async throws {
        // This embeds the same structure as recipeData.json and verifies that importing
        // all three at once doesn't hit SwiftData's @Attribute(.unique) constraint.
        let store = try makeStore()

        let json = """
        [
          {"id":"imported-recipe-1","title":"Galette","summary":null,"servings":6,"tags":[],"rawText":[],
           "source":null,"sourceType":null,"sourceTitle":null,"website":null,"author":null,
           "ingredients":[],"sections":[],
           "timings":[{"id":"timing-galette-prep","type":"Prep","hours":0,"minutes":30},
                      {"id":"timing-galette-cook","type":"Cook","hours":1,"minutes":20}],
           "instructions":[{"id":"instruction-crust-1","value":"Step one.","position":0}],
           "instructionSections":[],
           "notes":[{"id":"note-galette-1","text":"A note.","position":0}]},
          {"id":"imported-recipe-2","title":"Pot Roast","summary":null,"servings":8,"tags":[],"rawText":[],
           "source":null,"sourceType":null,"sourceTitle":null,"website":null,"author":null,
           "ingredients":[],"sections":[],
           "timings":[{"id":"timing-roast-prep","type":"Prep","hours":0,"minutes":30},
                      {"id":"timing-roast-cook","type":"Cook","hours":4,"minutes":0}],
           "instructions":[{"id":"instruction-roast-1","value":"Preheat oven.","position":0}],
           "instructionSections":[],
           "notes":[{"id":"note-roast-1","text":"A note.","position":0}]},
          {"id":"imported-recipe-3","title":"Niçoise","summary":null,"servings":2,"tags":[],"rawText":[],
           "source":null,"sourceType":null,"sourceTitle":null,"website":null,"author":null,
           "ingredients":[],"sections":[],
           "timings":[{"id":"timing-nicoise-prep","type":"Prep","hours":0,"minutes":45}],
           "instructions":[{"id":"instruction-nicoise-1","value":"Make dressing.","position":0}],
           "instructionSections":[],
           "notes":[{"id":"note-nicoise-1","text":"A note.","position":0}]}
        ]
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("id-uniqueness-test.json")
        try Data(json.utf8).write(to: url)

        // If any IDs collide the context save will throw a uniqueness constraint error.
        let count = try await ImportExportManager.importRecipesFile(from: url, context: store.context)
        #expect(count == 3, "all three sample recipes should import without ID collision")
    }
}
