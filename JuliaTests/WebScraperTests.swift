//
//  WebScraperTests.swift
//  JuliaTests
//
//  Deterministic, offline coverage of URL import. These exercise the JSON-LD
//  path of RecipeWebScraper against saved HTML in Fixtures/Web, so they need
//  neither the network nor Apple Intelligence.
//
//  To add a page: save it as Fixtures/Web/<name>.html. `allFixturesParse`
//  picks it up automatically. Add a named test below when you want to assert
//  specific field values.
//

import Testing
import Foundation
@testable import Julia

// RecipeWebScraper is @MainActor-isolated, so the suite is too.
@Suite("Web scraping — JSON-LD (offline)")
@MainActor
struct WebScraperTests {

    // MARK: - Field-level assertions

    @Test("Direct @type: Recipe page maps every field")
    func directRecipeNode() throws {
        let html = try #require(
            TestAssets.webPages().first { $0.name == "jsonld_direct" }?.html,
            "Missing fixture Fixtures/Web/jsonld_direct.html"
        )

        let scraper = RecipeWebScraper()
        let data = try #require(
            scraper.extractJSONLD(from: html, sourceURL: "https://example.test/salmon"),
            "JSON-LD block should be found and parsed"
        )

        #expect(data.title == "Sheet Pan Harissa Salmon")
        #expect(data.summary == ["A weeknight salmon traybake with harissa, chickpeas and charred lemon."])

        // The whitespace-only ingredient in the fixture must be filtered out.
        #expect(data.ingredients.count == 7)
        #expect(data.ingredients.first == "4 salmon fillets, skin on")
        #expect(data.ingredients.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty })

        // HowToStep objects should be flattened to their `text`.
        #expect(data.instructions.count == 4)
        #expect(data.instructions.first == "Heat the oven to 425F.")

        #expect(data.timings.contains("prep: 15 min"))
        #expect(data.timings.contains("cook: 25 min"))
        #expect(data.timings.contains("total: 40 min"))

        #expect(data.servings == ["4 servings"])
        #expect(data.author == "Ada Fixture")
        #expect(data.sourceTitle == "Fixture Kitchen")
        #expect(data.source == "https://example.test/salmon")
        #expect(data.sourceType == "website")
    }

    @Test("Recipe nested in an @graph array is found")
    func graphRecipeNode() throws {
        let html = try #require(
            TestAssets.webPages().first { $0.name == "jsonld_graph" }?.html,
            "Missing fixture Fixtures/Web/jsonld_graph.html"
        )

        let scraper = RecipeWebScraper()
        let data = try #require(
            scraper.extractJSONLD(from: html, sourceURL: "https://example.test/banana-bread"),
            "Recipe inside @graph should be found by walking the array"
        )

        #expect(data.title == "Brown Butter Banana Bread")
        // author as [[String: Any]] — the third of three author shapes.
        #expect(data.author == "Grace Hopperson")
        // recipeYield as an array takes the first entry.
        #expect(data.servings == ["1 loaf"])
        // Instructions given as plain strings, not HowToStep objects.
        #expect(data.instructions.count == 4)
        #expect(data.ingredients.count == 7)
        // 70 minutes should format as hours + minutes, not "70 min".
        #expect(data.timings.contains("cook: 1 hr 10 min"))
        #expect(data.timings.contains("prep: 20 min"))
        // No totalTime in this fixture.
        #expect(!data.timings.contains { $0.hasPrefix("total:") })
    }

    // MARK: - Every fixture should at least parse

    @Test("Every HTML fixture yields a usable recipe")
    func allFixturesParse() throws {
        let pages = TestAssets.webPages()
        try #require(!pages.isEmpty, "No HTML fixtures found in the test bundle")

        for page in pages {
            let scraper = RecipeWebScraper()
            let data = scraper.extractJSONLD(from: page.html, sourceURL: "https://example.test/\(page.name)")

            let recipe = try #require(data, "\(page.name): no JSON-LD recipe extracted")
            #expect(!recipe.title.isEmpty, "\(page.name): title should not be empty")
            #expect(!recipe.ingredients.isEmpty, "\(page.name): should have ingredients")
            #expect(!recipe.instructions.isEmpty, "\(page.name): should have instructions")
            #expect(!recipe.rawText.isEmpty, "\(page.name): rawText should be populated for the review sheet")
        }
    }

    // MARK: - Helpers

    @Test("ISO 8601 durations parse to minutes", arguments: [
        ("PT15M", 15),
        ("PT45M", 45),
        ("PT1H", 60),
        ("PT1H30M", 90),
        ("PT2H15M", 135)
    ])
    func isoDurations(iso: String, expected: Int) {
        #expect(RecipeWebScraper().isoToMinutes(iso) == expected)
    }

    @Test("Malformed or zero durations return nil", arguments: [
        "", "30M", "1H30M", "garbage", "PT0M"
    ])
    func rejectedDurations(iso: String) {
        #expect(RecipeWebScraper().isoToMinutes(iso) == nil)
    }

    @Test("Script and style bodies are stripped from page text")
    func stripsScriptAndStyle() throws {
        let html = try #require(
            TestAssets.webPages().first { $0.name == "jsonld_direct" }?.html
        )

        let text = RecipeWebScraper().stripHTML(html)

        // Script bodies are what the AI fallback would otherwise be fed.
        #expect(!text.contains("tracking pixel noise"))
        #expect(!text.contains("window.analytics"))
        #expect(!text.contains("display: none"))
        #expect(!text.contains("<p>"))
        // Real copy survives, and entities are decoded.
        #expect(text.contains("Sheet Pan Harissa Salmon"))
        #expect(text.contains("Serves 4 & comes together on one pan."))
    }

    @Test("A page with no JSON-LD returns nil rather than an empty recipe")
    func noJSONLD() {
        let html = "<html><body><h1>Just a blog post</h1><p>No structured data here.</p></body></html>"
        #expect(RecipeWebScraper().extractJSONLD(from: html, sourceURL: "https://example.test") == nil)
    }
}
