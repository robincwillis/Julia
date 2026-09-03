//
//  RecipeProcessingTests.swift
//  JuliaTests
//
//  Coverage of the import pipeline, split by what each stage needs:
//
//  • Offline suites run everywhere — text reconstruction, ingredient parsing
//    and Vision OCR need no network and no Apple Intelligence.
//  • The full-pipeline suite routes through FoundationModelsRecipeClassifier
//    and so is skipped automatically when Apple Intelligence is unavailable
//    (the usual case on a simulator) rather than failing.
//
//  Adding a test case is a file drop — see JuliaTests/Fixtures/README.md.
//

import Testing
import SwiftUI
import SwiftData
import Vision
@testable import Julia

// MARK: - Text reconstruction (offline)

@Suite("Text reconstruction (offline)")
struct TextReconstructionTests {

    @Test("Empty input yields an empty result rather than crashing")
    func emptyInput() {
        let result = RecipeTextReconstructor.reconstructText(from: [])
        #expect(result.reconstructedLines.isEmpty)
        #expect(result.artifacts.isEmpty)
    }

    @Test("Blank lines are dropped without becoming artifacts")
    func blankLines() {
        let result = RecipeTextReconstructor.reconstructText(from: ["Butter", "", "   ", "Flour"])
        #expect(!result.reconstructedLines.contains(""))
        #expect(!result.artifacts.contains(""))
        let joined = result.reconstructedLines.joined(separator: " ")
        #expect(joined.contains("Butter"))
        #expect(joined.contains("Flour"))
    }

    @Test("Every line of real text survives into lines or artifacts")
    func nothingSilentlyDropped() throws {
        let fixture = try #require(
            TestAssets.texts().first { $0.name == "simple_recipe" }?.text,
            "Missing fixture Fixtures/Text/simple_recipe.txt"
        )
        let lines = fixture
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let result = RecipeTextReconstructor.reconstructText(from: lines)

        // Content should be preserved somewhere — the reconstructor joins
        // fragments, so compare on total non-whitespace characters rather than
        // line counts.
        let inputChars = lines.joined().filter { !$0.isWhitespace }.count
        let outputChars = (result.reconstructedLines + result.artifacts)
            .joined().filter { !$0.isWhitespace }.count
        #expect(outputChars >= inputChars,
                "Reconstruction lost content: \(inputChars) chars in, \(outputChars) out")
    }

    @Test("Distinctive ingredient text is still findable after reconstruction")
    func preservesIngredients() throws {
        let fixture = try #require(
            TestAssets.texts().first { $0.name == "simple_recipe" }?.text
        )
        let lines = fixture.components(separatedBy: .newlines)
        let result = RecipeTextReconstructor.reconstructText(from: lines)
        let haystack = result.reconstructedLines.joined(separator: "\n")

        #expect(haystack.contains("olive oil"))
        #expect(haystack.contains("chicken stock"))
        #expect(haystack.contains("Preheat the oven"))
    }
}

// MARK: - Ingredient parsing (offline)

@Suite("Ingredient parsing — heuristic path (offline)")
struct IngredientParsingTests {

    @Test("Plain decimal quantity with a unit")
    func decimalWithUnit() throws {
        let ingredient = try #require(
            IngredientParser.fromString(input: "2 cups flour", location: .recipe)
        )
        #expect(ingredient.name == "flour")
        #expect(ingredient.quantity == 2)
        #expect(ingredient.unit != nil)
    }

    @Test("Slash fractions parse to a decimal quantity")
    func slashFraction() throws {
        let ingredient = try #require(
            IngredientParser.fromString(input: "1/2 cup butter", location: .recipe)
        )
        #expect(ingredient.quantity == 0.5)
        #expect(ingredient.name == "butter")
    }

    @Test("A bare item gets no quantity")
    func bareItem() throws {
        let ingredient = try #require(
            IngredientParser.fromString(input: "Salt", location: .pantry)
        )
        #expect(ingredient.name == "Salt")
        #expect(ingredient.quantity == nil)
    }

    @Test("Multi-word names keep every word")
    func multiWordName() throws {
        let ingredient = try #require(
            IngredientParser.fromString(input: "3 tablespoons extra virgin olive oil", location: .recipe)
        )
        #expect(ingredient.quantity == 3)
        #expect(ingredient.name == "extra virgin olive oil")
    }

    @Test("Empty and whitespace-only input is rejected", arguments: ["", "   ", "\n"])
    func rejectsEmpty(input: String) {
        #expect(IngredientParser.fromString(input: input, location: .recipe) == nil)
    }

    // These cover `parseQuantity`, which handles the Unicode fractions and
    // hyphenated ranges the app advertises.
    @Test("Unicode vulgar fractions parse", arguments: [
        ("½ cup butter", 0.5),
        ("¼ teaspoon salt", 0.25),
        ("¾ cup sugar", 0.75),
        ("⅓ cup cream", 1.0 / 3.0)
    ])
    func unicodeFractions(input: String, expected: Double) throws {
        let ingredient = try #require(
            IngredientParser.fromString(input: input, location: .recipe)
        )
        let quantity = try #require(ingredient.quantity, "No quantity parsed from \(input)")
        #expect(abs(quantity - expected) < 0.0001, "\(input) → \(quantity), expected \(expected)")
    }

    @Test("A whole number plus a vulgar fraction sums")
    func mixedNumber() throws {
        let ingredient = try #require(
            IngredientParser.fromString(input: "1½ cups milk", location: .recipe)
        )
        let quantity = try #require(ingredient.quantity)
        #expect(abs(quantity - 1.5) < 0.0001, "Expected 1.5, got \(quantity)")
    }

    @Test("A hyphenated range averages its bounds")
    func rangeAverages() throws {
        let ingredient = try #require(
            IngredientParser.fromString(input: "2-4 cups stock", location: .recipe)
        )
        let quantity = try #require(ingredient.quantity)
        #expect(abs(quantity - 3.0) < 0.0001, "Expected the midpoint 3.0, got \(quantity)")
    }

    @Test("Round trip through toString keeps the quantity and name")
    func roundTrip() throws {
        let ingredient = try #require(
            IngredientParser.fromString(input: "2 cups flour", location: .recipe)
        )
        let rendered = IngredientParser.toString(for: ingredient)
        #expect(rendered.contains("flour"))
        #expect(rendered.contains("2"))
    }
}

// MARK: - OCR (offline)

@Suite("Vision OCR (offline)")
struct TextRecognitionTests {

    @Test("OCR reads back text rendered into an image", .timeLimit(.minutes(1)))
    func synthenticImageRoundTrip() async throws {
        let expected = [
            "Lemon Garlic Chicken",
            "2 cups flour",
            "Preheat the oven to 425F"
        ]
        let image = TestAssets.renderedTextImage(expected)

        let lines = await TextRecognitionService.shared.recognizeText(from: image)
        let joined = lines.joined(separator: " ")

        #expect(!lines.isEmpty, "OCR returned nothing for a clean rendered image")
        // OCR is fuzzy on punctuation, so assert on distinctive words.
        #expect(joined.contains("Lemon"))
        #expect(joined.contains("flour"))
        #expect(joined.contains("Preheat"))
    }

    @Test("Every image fixture produces some text", .timeLimit(.minutes(5)))
    func imageFixturesProduceText() async throws {
        let images = TestAssets.images()
        // Not a failure — the suite ships without binary photos. Drop JPEGs
        // into Fixtures/Images to exercise this.
        guard !images.isEmpty else { return }

        let log = TestLog(name: "ocr")
        for (name, image) in images {
            let lines = await TextRecognitionService.shared.recognizeText(from: image)
            log.write("\(name): \(lines.count) line(s) recognised")
            for line in lines { log.write("    \(line)") }
            #expect(!lines.isEmpty, "\(name): OCR produced no text")
        }
        log.attach()
    }
}

// MARK: - Full pipeline (needs Apple Intelligence)

@Suite(
    "Full import pipeline (requires Apple Intelligence)",
    .enabled(if: TestAssets.isAppleIntelligenceAvailable,
             "Apple Intelligence is \(TestAssets.appleIntelligenceStatus)")
)
struct FullPipelineTests {

    /// Drives the processor and waits for whichever callback fires first.
    @MainActor
    private func run(
        _ start: @MainActor (RecipeProcessor) -> Void
    ) async throws -> RecipeData {
        let container = try ModelContainer(
            for: DataController.appSchema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let processor = RecipeProcessor(modelContext: container.mainContext)

        return try await withCheckedThrowingContinuation { continuation in
            var settled = false
            processor.onCompletion = { data in
                guard !settled else { return }
                settled = true
                continuation.resume(returning: data)
            }
            processor.onError = { message in
                guard !settled else { return }
                settled = true
                continuation.resume(throwing: PipelineFailure.processing(message))
            }
            start(processor)
        }
    }

    enum PipelineFailure: Error, CustomStringConvertible {
        case processing(String)
        var description: String {
            switch self {
            case .processing(let message): return "Pipeline reported: \(message)"
            }
        }
    }

    @Test("Text import produces a titled recipe with ingredients", .timeLimit(.minutes(5)))
    func textImport() async throws {
        let fixture = try #require(
            TestAssets.texts().first { $0.name == "simple_recipe" }?.text
        )

        let log = TestLog(name: "pipeline-text")
        let data = try await run { $0.processText(fixture) }
        log.dump(data, label: "simple_recipe")
        defer { log.attach() }

        #expect(!data.title.isEmpty, "Classifier produced no title")
        #expect(!data.ingredients.isEmpty, "Classifier produced no ingredients")
        #expect(!data.instructions.isEmpty, "Classifier produced no instructions")
        #expect(!data.rawText.isEmpty, "rawText should be retained for the review sheet")
    }

    @Test("Every text fixture completes without error", .timeLimit(.minutes(10)))
    func allTextFixtures() async throws {
        let fixtures = TestAssets.texts()
        try #require(!fixtures.isEmpty, "No text fixtures found in the test bundle")

        let log = TestLog(name: "pipeline-all-text")
        for (name, text) in fixtures {
            let data = try await run { $0.processText(text) }
            log.dump(data, label: name)
            #expect(!data.ingredients.isEmpty, "\(name): no ingredients classified")
        }
        log.attach()
    }

    @Test("Every image fixture completes without error", .timeLimit(.minutes(10)))
    func allImageFixtures() async throws {
        let images = TestAssets.images()
        guard !images.isEmpty else { return }

        let log = TestLog(name: "pipeline-all-images")
        for (name, image) in images {
            let data = try await run { $0.processImage(image) }
            log.dump(data, label: name)
            #expect(!data.ingredients.isEmpty, "\(name): no ingredients classified")
        }
        log.attach()
    }
}
