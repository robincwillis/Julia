//
//  FoundationModelsRecipeClassifier.swift
//  Julia
//

import Foundation
import FoundationModels

/// Classifies recipe text lines into structured categories using Foundation Models.
///
/// The model returns only `{lineNumber, category}` per line — never the line's
/// text. That keeps the response a few tokens per line instead of restating the
/// whole input, which is what used to consume the ~4,096 token budget twice
/// over. See docs/bugs/context-window-overflow.md.
struct FoundationModelsRecipeClassifier {

    /// Maximum lines per Foundation Models call.
    ///
    /// The budget covers the instructions, the input lines, and the output. Now
    /// that the output no longer echoes the input text, a chunk costs roughly
    /// its own token count plus a small per-line assignment, rather than double.
    /// Kept at 40 rather than raised: chunking also bounds the blast radius of a
    /// single bad generation, and a smaller chunk keeps line numbers short.
    let chunkSize = 40

    /// Lines of preceding context prepended to every chunk after the first.
    ///
    /// A chunk is otherwise classified blind: its opening lines have no preamble,
    /// so mid-recipe instructions can read as a title and a section heading gets
    /// separated from the ingredients it introduces. These lines were already
    /// classified by the previous chunk — they are here to be *read*, not
    /// re-decided, and their answers are discarded on merge.
    let chunkOverlap = 5

    /// Smallest chunk worth retrying. Below this, an overflow is not a sizing
    /// problem and the error is surfaced instead of split further.
    private let minimumChunkSize = 5

    /// Confidence recorded for a line the model classified.
    private let assignedConfidence = 1.0

    /// Confidence recorded for a line the model did not return, which we
    /// defaulted to `.unknown`. Below `RecipeProcessor.confidenceThreshold`, so
    /// the review sheet can actually surface these.
    private let defaultedConfidence = 0.3

    /// Shorter than it was, but the category glossary has to stay here.
    ///
    /// `@Generable` on an enum sends only the *case names* to the model — there
    /// is no per-case `@Guide`, so "timing" and "note" arrive as bare labels
    /// with no definition. An earlier version of this file dropped the glossary
    /// on the assumption the schema carried it, and accuracy fell measurably:
    /// "Total: 3 hours including cooling" was classified as summary, "Heat the
    /// oven to 175C" as a timing, and "Keeps 4 days in an airtight tin" as a
    /// timing rather than a note.
    ///
    /// What did leave is the OCR-correction section, which is genuinely obsolete
    /// now that the model returns no text to correct.
    private let instructions = """
    You classify lines of recipe text, often extracted via OCR.

    You are given numbered lines. Return one entry per line: its number and the
    part of the recipe it belongs to. Never omit a line. Never invent a number
    that was not in the input.

    Categories:
    - title: the name of the dish. Exactly one per recipe.
    - summary: a sentence or two describing or introducing the dish.
    - timing: how long a stage takes — prep, cook, bake, chill, rest, or total.
    - serving: how much it makes ("Serves 4", "Makes 24 cookies").
    - sectionTitle: a short heading labelling a group of ingredients or steps
      ("For the sauce:", "Assembly"). A label, never a cooking action.
    - ingredient: one thing needed, usually quantity + unit + item.
    - instruction: one cooking action the reader performs, in sequence.
    - note: advice rather than a step — tips, substitutions, storage, make-ahead,
      serving suggestions.
    - source: attribution, author, publication, or URL.
    - unknown: only when a line genuinely fits nothing else.

    Distinctions that are easy to get wrong:
    - A line naming a duration is a timing only if it states how long a stage
      takes. "Total: 3 hours including cooling" is a timing. "Keeps 4 days in an
      airtight tin" is storage advice, so it is a note.
    - A step that mentions a temperature or a duration is still an instruction:
      "Heat the oven to 175C" and "Bake 30 to 35 minutes" are instructions, not
      timings.
    - "Serve immediately", "Best eaten fresh" are notes, not instructions.
    """

    /// Classifies an array of recipe lines and returns a structured `ClassificationResult`.
    func classify(_ lines: [String]) async throws -> ClassificationResult {
        let nonEmpty = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !nonEmpty.isEmpty else {
            return emptyResult()
        }

        // Absolute index into `nonEmpty` → category. A dictionary rather than an
        // accumulating struct so out-of-order or duplicated line numbers from the
        // model cannot append the same line twice.
        var categories: [Int: RecipeLineType] = [:]

        for window in makeChunks(nonEmpty) {
            let assignments = try await classifyChunkSplittingOnOverflow(window.lines)
            for assignment in assignments {
                // Line numbers are 1-based within the window. Anything outside it
                // is a hallucinated number and is dropped rather than trusted.
                let local = assignment.lineNumber - 1
                guard window.lines.indices.contains(local) else { continue }

                // First write wins. A window's leading `chunkOverlap` lines were
                // primary in the previous window, where they had full preceding
                // context, so that verdict is the better one. The exception is
                // useful: if the previous window omitted a line entirely, the
                // overlap gives it a second chance to be classified.
                let absolute = window.start + local
                if categories[absolute] == nil {
                    categories[absolute] = assignment.category.lineType
                }
            }
        }

        return buildResult(from: nonEmpty, categories: categories)
    }

    // MARK: - Private

    /// Assembles the pipeline's `ClassificationResult` by walking the input in
    /// document order and looking up each line's category.
    ///
    /// Walking the *input* rather than the model's response is what makes
    /// omissions safe: a line the model never returned is still present here,
    /// categorised `.unknown` and flagged with a low confidence, instead of
    /// silently vanishing from the recipe.
    private func buildResult(
        from lines: [String],
        categories: [Int: RecipeLineType]
    ) -> ClassificationResult {
        var title = ""
        var ingredients: [String] = []
        var instructionLines: [String] = []
        var sectionTitles: [String] = []
        var summary: [String] = []
        var timings: [String] = []
        var servings: [String] = []
        var notes: [String] = []
        var source: [String] = []
        var classified: [(String, RecipeLineType, Double)] = []
        var skipped: [(String, RecipeLineType, Double)] = []

        for (index, line) in lines.enumerated() {
            let type = categories[index] ?? .unknown
            let confidence = categories[index] == nil ? defaultedConfidence : assignedConfidence

            classified.append((line, type, confidence))

            switch type {
            case .title:
                // Exactly one title; later candidates are more useful as summary
                // than discarded outright.
                if title.isEmpty { title = line } else { summary.append(line) }
            case .ingredient:    ingredients.append(line)
            case .instruction:   instructionLines.append(line)
            case .section_title: sectionTitles.append(line)
            case .summary:       summary.append(line)
            case .time:          timings.append(line)
            case .serving:       servings.append(line)
            case .note:          notes.append(line)
            case .source:        source.append(line)
            case .unknown:       skipped.append((line, .unknown, confidence))
            }
        }

        return (
            title: title.isEmpty ? "New Recipe" : title,
            sectionTitles: sectionTitles,
            ingredients: ingredients,
            instructions: instructionLines,
            summary: summary,
            servings: servings,
            timings: timings,
            notes: notes,
            source: source,
            skipped: skipped,
            classified: classified
        )
    }

    /// Classifies a chunk, halving it and retrying if the model overflows its
    /// context window. Structured generation output length is not fully
    /// predictable — the model can ramble on messy OCR text and exceed the
    /// budget even for an input that usually fits — so treat overflow as a
    /// sizing hint rather than a fatal error.
    ///
    /// Returned line numbers are 1-based relative to `lines`, so the second half
    /// of a split is re-based before being handed back.
    private func classifyChunkSplittingOnOverflow(_ lines: [String]) async throws -> [ClassifiedLine] {
        do {
            return try await classifyChunk(lines)
        } catch let error as LanguageModelSession.GenerationError {
            guard case .exceededContextWindowSize = error,
                  lines.count > minimumChunkSize else { throw error }

            let middle = lines.count / 2
            let first = try await classifyChunkSplittingOnOverflow(Array(lines[..<middle]))
            let second = try await classifyChunkSplittingOnOverflow(Array(lines[middle...]))
            return first + second.map {
                ClassifiedLine(lineNumber: $0.lineNumber + middle, category: $0.category)
            }
        }
    }

    private func classifyChunk(_ lines: [String]) async throws -> [ClassifiedLine] {
        let numbered = lines.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let prompt = """
        Classify each numbered line below. Return one entry per line.

        \(numbered)
        """

        let result = try await FoundationModelsService.shared.generate(
            prompt,
            type: ClassifiedLines.self,
            instructions: instructions
        )
        return result.lines
    }

    /// One request's worth of lines, plus where it sits in the whole document.
    struct ChunkWindow {
        /// Absolute index into the full line array of `lines[0]`.
        let start: Int
        /// Overlap context followed by this window's primary lines.
        let lines: [String]
    }

    /// Splits into windows of `chunkSize` primary lines, each after the first
    /// prefixed with `chunkOverlap` lines of preceding context.
    ///
    /// Primary ranges tile the input exactly — every line is primary in exactly
    /// one window — so coverage is complete and `categories` cannot be written
    /// twice for the same line by two windows that both consider it primary.
    func makeChunks(_ lines: [String]) -> [ChunkWindow] {
        guard lines.count > chunkSize else {
            return [ChunkWindow(start: 0, lines: lines)]
        }

        var windows: [ChunkWindow] = []
        var primaryStart = 0

        while primaryStart < lines.count {
            let primaryEnd = min(primaryStart + chunkSize, lines.count)
            let windowStart = max(0, primaryStart - chunkOverlap)
            windows.append(
                ChunkWindow(start: windowStart, lines: Array(lines[windowStart..<primaryEnd]))
            )
            primaryStart = primaryEnd
        }
        return windows
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
