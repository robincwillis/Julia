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
    private let chunkSize = 40

    /// Smallest chunk worth retrying. Below this, an overflow is not a sizing
    /// problem and the error is surfaced instead of split further.
    private let minimumChunkSize = 5

    /// Confidence recorded for a line the model classified.
    private let assignedConfidence = 1.0

    /// Confidence recorded for a line the model did not return, which we
    /// defaulted to `.unknown`. Below `RecipeProcessor.confidenceThreshold`, so
    /// the review sheet can actually surface these.
    private let defaultedConfidence = 0.3

    /// Shorter than it was: the ten-category glossary moved into `@Guide`
    /// descriptions on `LineCategory`, which the framework already sends as part
    /// of the schema, and the OCR-correction section is gone because the model
    /// no longer returns text to correct. What remains is the judgement calls
    /// the schema cannot express.
    private let instructions = """
    You classify lines of recipe text, often extracted via OCR.

    You are given numbered lines. Return one entry per line: its number and the
    part of the recipe it belongs to. Never omit a line. Never invent a number
    that was not in the input.

    Judgement calls:
    - A line is an instruction only if it describes a cooking action the reader
      performs, in sequence.
    - "Serve immediately", "Keeps 3 days refrigerated", "Best eaten fresh" are
      notes, not instructions.
    - A short standalone heading labelling a group of ingredients or steps is a
      sectionTitle, not an instruction.
    - There is exactly one title per recipe.
    - Use unknown only when a line genuinely fits nothing else.
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

        var offset = 0
        for chunk in makeChunks(nonEmpty) {
            let assignments = try await classifyChunkSplittingOnOverflow(chunk)
            for assignment in assignments {
                // Line numbers are 1-based within the chunk. Anything outside it
                // is a hallucinated number and is dropped rather than trusted.
                let local = assignment.lineNumber - 1
                guard chunk.indices.contains(local) else { continue }
                categories[offset + local] = assignment.category.lineType
            }
            offset += chunk.count
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

    private func makeChunks(_ lines: [String]) -> [[String]] {
        guard lines.count > chunkSize else { return [lines] }

        var chunks: [[String]] = []
        var current: [String] = []

        for line in lines {
            current.append(line)
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
