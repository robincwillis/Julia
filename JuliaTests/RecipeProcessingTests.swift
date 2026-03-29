//
//  RecipeProcessingTests.swift
//  JuliaTests
//
//  Created by Robin Willis on 5/10/25.
//

import Testing
import SwiftUI
import SwiftData
import Vision
@testable import Julia

// let imageNames = ["onion_soup", "sardine_nicoise", "sauteed_chanterelles", "steamed_haddock"]
let imageNames =  ["trout_with_haricots_verts_capers_and_lemons"] // ["kalbi_butter_noodles"]
//TODO Add more:
// let imageNames = ["baked_alaska", "butter_cookies", "carpaccio_tuna_fin", "cheese_dough_torte", "chesnut_almond_torte", "clear_pork_noodle_soup", "coconut_tapioca_soup", "coconut_tapioca", "coffee_cake", "crepes_suzette", "fish_stew", "fried_zucchini_blossoms", "green_salad_with_zatar", "grilled_hearts_of_palm", "grilled_rainbow_escabeche", "gunard_baked_banana_leaf", "herbs_de_provence", "how_southern_are_you", "leg_of_lamb", "linguini_and_clams", "little_gem_salad", "lobster_consumee_in_jelee", "mon_poulet_roti", "nicoise_toast", "onion_flan", "onion_pizza", "onion_soup", "party_posole_rojo", "pastry_fritters", "poached_salmon_with_coarse_salt", "potato_galette", "red_pepper_tapenade", "rice_noodles_multiple", "roast_chicken_with_bell_peppers", "rock_lobster_salad", "salade_nicoise", "sardine_nicoise", "scrambled_eggs_with_mushrooms", "seafood_gumbo", "slow_cooked_chicken_with_kale", "soft_shell_crab_with_sweet_black_pepper_sauce", "staff_lasagna", "tomato_melon_gazpacho", "unami_salami", "veal_scallops", "watermelon_radish_salad"]
let textFiles = ["recipe"]
//TODO Add more:
// let textFiles = [ "recipe", "clean_recipe", "messy_recipe", "multiple_recipes_text", "recipe_with_ads", "incomplete_recipe"]

struct RecipeProcessingTests {
    // State for each test
    @MainActor
    struct TestState {
        
        var processor: RecipeProcessor
        var modelContainer: ModelContainer
        var testImages: [String: UIImage] = [:]
        var testTexts: [String: String] = [:]
        var logFile: URL?
        
        init() throws {
            // Create in-memory model container for testing
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            self.modelContainer = try ModelContainer(for: Recipe.self, Ingredient.self, configurations: config)
            // Create processor
            self.processor = RecipeProcessor(modelContext: modelContainer.mainContext)
            self.processor = RecipeProcessor()
            // Create log file
            let fileManager = FileManager.default
            let testLogsDirectory = fileManager.temporaryDirectory.appendingPathComponent("RecipeTests")
            try? fileManager.createDirectory(at: testLogsDirectory, withIntermediateDirectories: true)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let dateString = dateFormatter.string(from: Date())
            logFile = testLogsDirectory.appendingPathComponent("recipe_test_\(dateString).log")
            // Log test start
            logMessage("=== RECIPE PROCESSOR TEST RUN ===")
            logMessage("Date: \(Date())")
            // Load test assets
            loadTestAssets()
        }
        
        mutating func loadTestAssets() {
            logMessage("\nLoading test assets... images:\(imageNames) texts:\(textFiles)")
            let mainBundle = Bundle.main
            guard let testBundle = Bundle(identifier: "rcw.JuliaTests") else
            {
                logMessage("❌ Failed to find any usable test bundle")
                return
            }
            
            
            // Check if the asset catalog is properly included
//            let resources = testBundle.paths(forResourcesOfType: "", inDirectory: nil)
//            {
//                let assetPaths = resources.filter { $0.contains("Test Images.xcassets") }
//                if !assetPaths.isEmpty {
//                    logMessage("Found 'Test Images.xcassets' in the test bundle!")
//                } else {
//                    logMessage("WARNING: 'Test Images.xcassets' not found in the test bundle resources")
//                }
//            }
                    
//            logMessage("Test bundle path: \(testBundle.bundlePath)")
            logMessage("Test bundle ID: \(testBundle.bundleIdentifier ?? "nil")")
//            logMessage("Main bundle path: \(mainBundle.bundlePath)")
            logMessage("Main bundle ID: \(mainBundle.bundleIdentifier ?? "nil")")
            logMessage("Are main and processor bundles the same? \(mainBundle == testBundle)")
            
            // Load test image files
            var loadedImages = 0
            for name in imageNames {
                if let image = UIImage(named: name, in: testBundle, compatibleWith: nil) {
                    testImages[name] = image
                    loadedImages += 1
                }
            }
            
            // Load test text files
            var loadedTexts = 0
            for file in textFiles {
                if let url = testBundle.url(forResource: file, withExtension: "txt"),
                   let text = try? String(contentsOf: url) {
                    testTexts[file] = text
                    loadedTexts += 1
                }
            }
            
            logMessage("Loaded \(loadedImages) test images and \(loadedTexts) test text files")
            
        }
        
        // MARK: - Logging
        
        
        func logMessage(_ message: String, style: String = ConsoleStyle.none) {
            let styledMessage = style + message
            print(styledMessage)
            // Also write to log file
            if let logFile = logFile {
                let logEntry = message + "\n"
                if let data = logEntry.data(using: .utf8) {
                    if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    } else {
                        try? logEntry.write(to: logFile, atomically: true, encoding: .utf8)
                    }
                }
            }
            
        }
        
        func logClassfiedLines(_ lines: [(String, RecipeLineType, Double)]) {

            let sortedLines = lines.sorted { $0.2 > $1.2 }
                
            // Create table headers with fixed widths for type and confidence
            logMessage("  | Type            | Confidence | Text")
            logMessage("  |-----------------|------------|")
            
            
            // Print each row
            for (index, item) in sortedLines.enumerated() {
                let (text, type, confidence) = item
                
                // Type-specific styling
                let confidenceStyle: String
                let typeStyle: String
                
                switch type {
                case RecipeLineType.title:
                    typeStyle = ConsoleStyle.purple
                case RecipeLineType.ingredient:
                    typeStyle = ConsoleStyle.green
                case RecipeLineType.instruction:
                    typeStyle = ConsoleStyle.blue
                default:
                    typeStyle = ConsoleStyle.white
                }
                
                if confidence < 0.5 {
                    confidenceStyle = ConsoleStyle.brightRed
                } else if confidence < 0.65 {
                    confidenceStyle = ConsoleStyle.brightOrange
                } else if confidence < 0.85 {
                    confidenceStyle = ConsoleStyle.brightYellow
                } else {
                    confidenceStyle = ConsoleStyle.brightGreen
                }
                
                let paddedConfidence = String(format: "%.2f", confidence).padding(toLength: 7, withPad: " ", startingAt: 0)
                let paddedType = type.rawValue.padding(toLength: 12, withPad: " ", startingAt: 0)

                // Print the full, unmodified text with aligned columns for type and confidence
                logMessage("  | \(typeStyle) \(paddedType) | \(confidenceStyle) \(paddedConfidence) | \(text)")
            }
            logMessage("  --------------------------------")
        }
        
        func logTestResult(_ result: TestResult) {
            logMessage("\n  --- TEST RESULT: \(result.name) ---")

            logMessage("  Status: \(result.success ? "SUCCESS" : "❌ FAILURE")")
            
            if let duration = result.duration {
                logMessage("  Duration: \(String(format: "%.2f", duration)) seconds")
            }
            

            if let data = result.resultData {

                logMessage("\n  --- RAW OCR TEXT (\(data.rawText.count) lines) ---")
                for (index, line) in data.rawText.enumerated() {
                    logMessage("  \(index + 1). \(line)")
                }
                
                
                logMessage("\n  --- RECONSTRUCTED TEXT (\(data.reconstructedText.reconstructedLines.count) lines) ---")
                logMessage("  Title: \(data.reconstructedText.title)")
                for (index, line) in data.reconstructedText.reconstructedLines.enumerated() {
                    logMessage("  \(index + 1). \(line)")
                }
                
                logMessage("\n  --- ARTIFACTS (\(data.reconstructedText.artifacts.count) lines) ---")
                for (index, line) in data.reconstructedText.artifacts.enumerated() {
                    logMessage("  \(index + 1). \(line)")
                }
                
                logMessage("\n  --- CLASSIFIED LINES (\(data.classifiedLines.count) lines) ---")
                logClassfiedLines(data.classifiedLines)
                logMessage("\n")
                
                logMessage("\n  --- SKIPPED LINES (\(data.skippedLines.count) lines) ---")
                logClassfiedLines(data.skippedLines)
                logMessage("\n")
                                    
                logMessage("Recipe Title: \(data.title)")
                // Log first 3 ingredients and instructions as sample
                if !data.ingredients.isEmpty {
                    logMessage("Ingredients: \(data.ingredients.count)")
                    for (index, ingredient) in data.ingredients.enumerated() {
                        logMessage("  \(index + 1). \(ingredient)")
                    }
                }
                
                if !data.instructions.isEmpty {
                    logMessage("Instructions: \(data.instructions.count)")
                    for (index, instruction) in data.instructions.enumerated() {
                        logMessage("  \(index + 1). \(instruction)")
                    }
                }
            }
                
            if let logFile = logFile {
                logMessage("📝 LOG FILE LOCATION: \(logFile.path)")
            }
        }
    }
    
    // MARK: - Tests
    
    
//    @Test
//    func testSingleRecipeImage() async throws {
//        
//    }
//    
//    @Test
//    func testIncompleteRecipe() async throws {
//    }
//    
//    @Test
//    func testMultipleRecipesImage() async throws {
//    }
//    
//    
//    @Test
//    func testComplexLayoutImage() async throws {
//    }
//    
//    @Test
//    func testCleanText() async throws {
//    }
    
    @Test
    func testAllImages() async throws {
        let state = try await TestState()
        await state.logMessage("\n=== TESTING ALL IMAGES ===")
        for (name, image) in state.testImages {
            try await testProcessorWithImage(image, testName: "Image: \(name)", state: state)
        }
        await state.logMessage("=== END IMAGE TESTS ===\n")
    }
    
//    @Test
//    func testAllTexts() async throws {
//        let state = try await TestState()
//        await state.logMessage("\n=== TESTING ALL TEXTS ===")
//        for (name, text) in state.testTexts {
//            try await testProcessorWithText(text, testName: "Text: \(name)", state: state)
//        }
//        await state.logMessage("=== END TEXT TESTS ===\n")
//    }
    
    // MARK: - Helpers
    private func testProcessorWithImage(_ image: UIImage,
                                        expectedTitle: String? = nil,
                                        expectsMultiple: Bool = false,
                                        expectsIncomplete: Bool = false,
                                        testName: String,
                                        state: TestState) async throws {
        
        // Log test start
        await state.logMessage("\n--- TEST: \(testName) ---")
        await state.logMessage("Type: Image | Expected Multiple: \(expectsMultiple) | Expected Incomplete: \(expectsIncomplete)")
        
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TestResult, Error>) in
            Task { @MainActor in
                var testResult = TestResult(name: testName, type: .image)
                testResult.startTime = Date()
                
                // Set up callbacks
                state.processor.onCompletion = { recipeData in
                    testResult.success = true
                    testResult.resultData = recipeData
                    
                    // Check title if expected
                    if let expected = expectedTitle {
                        testResult.titleMatch = recipeData.title == expected
                    }
                    
                    // Check for multiple recipes
                    if expectsMultiple {
                        //                                 testResult.hasMultipleRecipes = state.processor.processingState.detectedRecipes.count > 1
                    }
                    
                    testResult.endTime = Date()
                    
                    // Log success
                    Task { @MainActor in
                        state.logTestResult(testResult)
                        continuation.resume(returning: testResult)
                    }
                }
                
                state.processor.onError = { errorMessage in
                    testResult.success = expectsIncomplete // Success if we expected failure
                    testResult.errorMessage = errorMessage
                    testResult.endTime = Date()
                    
                    // Log error
                    Task { @MainActor in
                        state.logMessage("ERROR: \(errorMessage)")
                        state.logTestResult(testResult)
                        continuation.resume(returning: testResult)
                    }
                }
                
                // Process the image
                state.logMessage("Starting image processing...")
                state.processor.processImage(image)
            }
        }
        // Validate expectations
        if expectsMultiple {
            //            try #expect(state.processor.processingState.detectedRecipes.count > 1, "Expected multiple recipes")
            //            state.logMessage("Multiple recipes: \(state.processor.processingState.detectedRecipes.count) recipes detected")
        }
        
        if let expected = expectedTitle {
            //            try #expect(state.processor.recipeData.title == expected, "Title should match expected value")
            //            state.logMessage("Title match: \(state.processor.recipeData.title == expected ? "✓" : "✗")")
        }
        
        if expectsIncomplete {
            //            try #expect(!result.success || !state.processor.processingState.incompleteRecipes.isEmpty,
            //                      "Expected incomplete recipe")
            //            state.logMessage("Incomplete recipes: \(state.processor.processingState.incompleteRecipes.count)")
        } else if !expectsMultiple {
            //            try #expect(result.success, "Processing should succeed")
        }
        
        // state.logMessage("--- END TEST: \(testName) ---\n")
    }
    
    private func testProcessorWithText(_ text: String,
                                       expectedTitle: String? = nil,
                                       expectsMultiple: Bool = false,
                                       expectsIncomplete: Bool = false,
                                       testName: String,
                                       state: TestState) async throws {
        
        // Log test start - await automatically runs this on MainActor
        await state.logMessage("\n--- TEST: \(testName) ---")
        await state.logMessage("Type: Text | Expected Multiple: \(expectsMultiple) | Expected Incomplete: \(expectsIncomplete)")
        
        // Create completion handler
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TestResult, Error>) in
            Task { @MainActor in
                var testResult = TestResult(name: testName, type: .text)
                testResult.startTime = Date()
                
                // Set up callbacks
                state.processor.onCompletion = { recipeData in
                    testResult.success = true
                    testResult.resultData = recipeData
                    
                    // Check title if expected
                    if let expected = expectedTitle {
                        testResult.titleMatch = recipeData.title == expected
                    }
                    
                    // Check for multiple recipes
                    if expectsMultiple {
                        // testResult.hasMultipleRecipes = state.processor.processingState.detectedRecipes.count > 1
                    }
                    
                    testResult.endTime = Date()
                    
                    // Log success - now uses state.logTestResult directly
                    Task { @MainActor in
                        state.logTestResult(testResult)
                        continuation.resume(returning: testResult)
                    }
                }
                
                state.processor.onError = { errorMessage in
                    testResult.success = expectsIncomplete // Success if we expected failure
                    testResult.errorMessage = errorMessage
                    testResult.endTime = Date()
                    
                    // Log error - now uses state.logTestResult directly
                    Task { @MainActor in
                        state.logMessage("ERROR: \(errorMessage)")
                        state.logTestResult(testResult)
                        continuation.resume(returning: testResult)
                    }
                }
                
                // Process the text
                state.logMessage("Starting text processing...")
                state.processor.processText(text)
            }
        }
        
        // Validate expectations - await automatically runs this on MainActor
        if expectsMultiple {
            //try #expect(await state.processor.processingState.detectedRecipes.count > 1, "Expected multiple recipes")
            // await state.logMessage("Multiple recipes: \(state.processor.processingState.detectedRecipes.count) recipes detected")
        }
        
        if let expected = expectedTitle {
            try #expect(await state.processor.recipeData.title == expected, "Title should match expected value")
            await state.logMessage("Title match: \(await state.processor.recipeData.title == expected ? "✓" : "✗")")
        }
        
        if expectsIncomplete {
            // try #expect(!result.success || await !state.processor.processingState.incompleteRecipes.isEmpty, "Expected incomplete recipe")
            //await state.logMessage("Incomplete recipes: \(state.processor.processingState.incompleteRecipes.count)")
        } else if !expectsMultiple {
            // try #expect(result.success, "Processing should succeed")
        }
        
        await state.logMessage("--- END TEST: \(testName) ---\n")
    }
}

struct ConsoleStyle {
    // Colors
    static let black = "⚫"
    static let red = "🔴"
    static let green = "🟢"
    static let yellow = "🟡"
    static let blue = "🔵"
    static let purple = "🟣"
    static let orange = "🟠"
    static let white = "⚪"
    static let brown = "🟤"
    
    // Colors Box
    static let brightBlack = "⬛"
    static let brightRed = "🟥"
    static let brightGreen = "🟩"
    static let brightYellow = "🟨"
    static let brightBlue = "🟦"
    static let brightPurple = "🟪"
    static let brightOrange = "🟧"
    static let brightWhite = "⬜"
    static let brightBrown = "🟫"
    
    static let warn = "⚠️"
    static let error = "❌"
    static let success = "✅"
    static let info = "ℹ️"
    static let debug = "🔍"

    // Default no formatting
    static let none = ""

}
