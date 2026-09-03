//
//  FoundationModelsRecipeClassifier.swift
//  Julia
//

import Foundation
import FoundationModels

/// Classifies recipe text lines into structured categories using Foundation Models.
/// Handles chunking for long recipes to stay within the ~4000 token budget.
struct FoundationModelsRecipeClassifier {

    /// Maximum lines per Foundation Models call.
    ///
    /// The ~4096 token budget covers the instructions (~900 tokens), the input
    /// lines, AND the structured output — which echoes every input line back
    /// into one of the arrays. So a chunk costs roughly twice its own token
    /// count on top of the fixed prompt, and 150 lines routinely overflowed.
    private let chunkSize = 40

    /// Smallest chunk worth retrying. Below this, an overflow is not a sizing
    /// problem and the error is surfaced instead of split further.
    private let minimumChunkSize = 5

    private let instructions = """
    You are a recipe text classifier. Your job is to read lines of recipe text (often extracted via OCR) and sort them into the correct fields of a structured recipe model.

    RECIPE MODEL STRUCTURE:
    - title: The name of the recipe. There is exactly one title per recipe.
    - summary: A brief description or introduction to the dish. Usually 1–3 sentences appearing before the ingredients or steps begin.
    - timings: Time-related metadata such as prep time, cook time, total time, chill time, or rest time (e.g. "Prep: 15 min", "Total time: 1 hour").
    - servings: Yield or serving size information (e.g. "Serves 4", "Makes 12 cookies", "Yield: 6 portions").
    - sectionTitles: Headings that divide the recipe into named groups of ingredients or steps (e.g. "For the sauce:", "Dough", "Assembly"). These are short labels, not cooking actions.
    - ingredients: Individual ingredient lines listing what is needed. Usually contain a quantity, unit, and item name (e.g. "2 cups flour", "1 tbsp olive oil").
    - instructions: Sequential, imperative cooking steps describing the actions required to make the dish (e.g. "Preheat oven to 350°F", "Fold in the egg whites until just combined").
    - notes: Tips, warnings, substitutions, storage guidance, make-ahead advice, serving suggestions, or any advisory text that is not a direct cooking action. Lines starting with "Tip:", "Note:", "Make ahead:", "Storage:", "Variation:", or "Serve with" are always notes.
    - source: Attribution, website URLs, cookbook names, or author credits.
    - unknown: Lines that do not fit any of the above categories.

    CLASSIFICATION RULES:
    - A line is an instruction only if it describes a direct cooking action the reader should perform, in sequence.
    - "Serve immediately", "Can be refrigerated for 3 days", "Best eaten fresh" → notes, not instructions.
    - Short standalone headings that label a group of ingredients or steps → sectionTitles, not instructions.
    - Every input line must appear in exactly one output array.

    OCR CORRECTION:
    The input text may contain OCR artifacts, garbled characters, stray punctuation, or minor typos. Correct these naturally when placing text into the output — fix obvious errors while preserving the original meaning and wording as closely as possible.
    """

    /// Classifies an array of recipe lines and returns a structured `ClassificationResult`.
    func classify(_ lines: [String]) async throws -> ClassificationResult {
        let nonEmpty = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !nonEmpty.isEmpty else {
            return emptyResult()
        }

        let chunks = makeChunks(nonEmpty)
        var merged = ClassifiedRecipe(
            title: "",
            ingredients: [],
            instructions: [],
            sectionTitles: [],
            summary: [],
            timings: [],
            servings: [],
            notes: [],
            source: [],
            unknown: []
        )

        for chunk in chunks {
            let partial = try await classifyChunkSplittingOnOverflow(chunk)
            merged = mergeResults(merged, partial)
        }

        return toClassificationResult(merged)
    }

    // MARK: - Private

    /// Classifies a chunk, halving it and retrying if the model overflows its
    /// context window. Structured generation output length is not fully
    /// predictable — the model can ramble on messy OCR text and exceed the
    /// budget even for an input that usually fits — so treat overflow as a
    /// sizing hint rather than a fatal error.
    private func classifyChunkSplittingOnOverflow(_ lines: [String]) async throws -> ClassifiedRecipe {
        do {
            return try await classifyChunk(lines)
        } catch let error as LanguageModelSession.GenerationError {
            guard case .exceededContextWindowSize = error,
                  lines.count > minimumChunkSize else { throw error }

            let middle = lines.count / 2
            let first = try await classifyChunkSplittingOnOverflow(Array(lines[..<middle]))
            let second = try await classifyChunkSplittingOnOverflow(Array(lines[middle...]))
            return mergeResults(first, second)
        }
    }

    private func classifyChunk(_ lines: [String]) async throws -> ClassifiedRecipe {
        let numbered = lines.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let prompt = """
        Classify each numbered line of this recipe text into the correct category.
        Assign each line to exactly one array. Use 'unknown' for any line that doesn't fit.

        Recipe text:
        \(numbered)
        """

        return try await FoundationModelsService.shared.generate(
            prompt,
            type: ClassifiedRecipe.self,
            instructions: instructions
        )
    }

    private func makeChunks(_ lines: [String]) -> [[String]] {
        guard lines.count > chunkSize else { return [lines] }

        var chunks: [[String]] = []
        var current: [String] = []

        for line in lines {
            current.append(line)
            // Split on blank lines (section boundaries) when near the chunk size
            if current.count >= chunkSize {
                chunks.append(current)
                current = []
            }
        }
        if !current.isEmpty {
            chunks.append(current)
        }
        return chunks
    }

    private func mergeResults(_ a: ClassifiedRecipe, _ b: ClassifiedRecipe) -> ClassifiedRecipe {
        // Prefer the first non-empty title
        let mergedTitle = a.title.isEmpty ? b.title : a.title
        return ClassifiedRecipe(
            title: mergedTitle,
            ingredients: a.ingredients + b.ingredients,
            instructions: a.instructions + b.instructions,
            sectionTitles: a.sectionTitles + b.sectionTitles,
            summary: a.summary + b.summary,
            timings: a.timings + b.timings,
            servings: a.servings + b.servings,
            notes: a.notes + b.notes,
            source: a.source + b.source,
            unknown: a.unknown + b.unknown
        )
    }

    /// Converts `ClassifiedRecipe` to the `ClassificationResult` typealias used throughout the pipeline.
    private func toClassificationResult(_ r: ClassifiedRecipe) -> ClassificationResult {
        var classified: [(String, RecipeLineType, Double)] = []

        func add(_ lines: [String], type: RecipeLineType) {
            for line in lines {
                classified.append((line, type, 1.0))
            }
        }

        if !r.title.isEmpty { classified.append((r.title, .title, 1.0)) }
        add(r.ingredients, type: .ingredient)
        add(r.instructions, type: .instruction)
        add(r.sectionTitles, type: .section_title)
        add(r.summary, type: .summary)
        add(r.timings, type: .time)
        add(r.servings, type: .serving)
        add(r.notes, type: .note)
        add(r.source, type: .source)
        add(r.unknown, type: .unknown)

        let skipped: [(String, RecipeLineType, Double)] = r.unknown.map { ($0, .unknown, 1.0) }

        return (
            title: r.title.isEmpty ? "New Recipe" : r.title,
            sectionTitles: r.sectionTitles,
            ingredients: r.ingredients,
            instructions: r.instructions,
            summary: r.summary,
            servings: r.servings,
            timings: r.timings,
            notes: r.notes,
            source: r.source,
            skipped: skipped,
            classified: classified
        )
    }

    private func emptyResult() -> ClassificationResult {
        return (
            title: "New Recipe",
            sectionTitles: [],
            ingredients: [],
            instructions: [],
            summary: [],
            servings: [],
            timings: [],
            notes: [],
            source: [],
            skipped: [],
            classified: []
        )
    }
}
