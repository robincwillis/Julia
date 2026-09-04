//
//  ClassifierChunkingTests.swift
//  JuliaTests
//
//  Chunk windows decide which lines the model sees together, and a boundary
//  error here loses or duplicates ingredients rather than failing loudly. All
//  offline — no model involved.
//

import Testing
@testable import Julia

@Suite("Classifier chunking (offline)")
struct ClassifierChunkingTests {

    private let classifier = FoundationModelsRecipeClassifier()

    /// `line 0`, `line 1`, … so a window's contents identify their own indices.
    private func lines(_ count: Int) -> [String] {
        (0..<count).map { "line \($0)" }
    }

    /// Where each window's *primary* lines sit — the ones it is responsible for,
    /// excluding leading overlap context.
    private func primaryRanges(
        _ windows: [FoundationModelsRecipeClassifier.ChunkWindow]
    ) -> [Range<Int>] {
        windows.enumerated().map { index, window in
            let primaryStart = index == 0 ? window.start : window.start + classifier.chunkOverlap
            return primaryStart..<(window.start + window.lines.count)
        }
    }

    // MARK: - Single window

    @Test("Input shorter than a chunk is one window at offset zero")
    func shortInputIsOneWindow() {
        let source = lines(10)
        let windows = classifier.makeChunks(source)

        #expect(windows.count == 1)
        #expect(windows[0].start == 0)
        #expect(windows[0].lines == source)
    }

    @Test("Input exactly one chunk long is still one window")
    func exactlyOneChunk() {
        let source = lines(classifier.chunkSize)
        let windows = classifier.makeChunks(source)

        #expect(windows.count == 1)
        #expect(windows[0].lines.count == classifier.chunkSize)
    }

    @Test("Empty input yields one empty window rather than crashing")
    func emptyInput() {
        let windows = classifier.makeChunks([])
        #expect(windows.count == 1)
        #expect(windows[0].lines.isEmpty)
    }

    // MARK: - Overlapping windows

    @Test("One line past a chunk splits, and the second window carries context")
    func justOverOneChunk() {
        let source = lines(classifier.chunkSize + 1)
        let windows = classifier.makeChunks(source)

        #expect(windows.count == 2)
        #expect(windows[0].start == 0)
        // Second window starts `chunkOverlap` lines early, so its single primary
        // line is not classified without any preamble.
        #expect(windows[1].start == classifier.chunkSize - classifier.chunkOverlap)
        #expect(windows[1].lines.count == classifier.chunkOverlap + 1)
    }

    @Test("Every window after the first begins with overlap context", arguments: [41, 85, 120, 201])
    func windowsCarryOverlap(count: Int) {
        let windows = classifier.makeChunks(lines(count))
        try? #require(windows.count > 1)

        for (index, window) in windows.enumerated() where index > 0 {
            let previous = windows[index - 1]
            let previousEnd = previous.start + previous.lines.count
            #expect(window.start == previousEnd - classifier.chunkOverlap,
                    "window \(index) should overlap the previous by exactly \(classifier.chunkOverlap)")
        }
    }

    @Test("Primary ranges tile the input exactly", arguments: [41, 85, 120, 201, 399])
    func primaryRangesTileExactly(count: Int) {
        let windows = classifier.makeChunks(lines(count))
        let ranges = primaryRanges(windows)

        // Contiguous, in order, no gap and no double coverage.
        #expect(ranges.first?.lowerBound == 0)
        #expect(ranges.last?.upperBound == count)
        for (index, range) in ranges.enumerated() where index > 0 {
            #expect(range.lowerBound == ranges[index - 1].upperBound,
                    "gap or overlap in primary coverage at window \(index)")
        }

        // Every line is primary in exactly one window — this is what stops a
        // line being written twice, or dropped, when merging.
        let covered = ranges.flatMap { Array($0) }
        #expect(covered.count == count)
        #expect(Set(covered).count == count)
    }

    @Test("Window contents match the source slice they claim", arguments: [41, 85, 201])
    func windowContentsMatchTheirOffset(count: Int) {
        let source = lines(count)
        for window in classifier.makeChunks(source) {
            let expected = Array(source[window.start..<(window.start + window.lines.count)])
            #expect(window.lines == expected,
                    "window at \(window.start) does not match the source at that offset")
        }
    }

    @Test("No window exceeds the chunk size plus its overlap", arguments: [41, 85, 120, 201, 399])
    func windowsStayWithinBudget(count: Int) {
        let limit = classifier.chunkSize + classifier.chunkOverlap
        for window in classifier.makeChunks(lines(count)) {
            #expect(window.lines.count <= limit,
                    "window of \(window.lines.count) lines exceeds the \(limit)-line budget")
        }
    }
}
