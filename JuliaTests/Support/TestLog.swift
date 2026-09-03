//
//  TestLog.swift
//  JuliaTests
//
//  Detailed run logging for the processing pipeline. Assertions tell you
//  *that* something broke; these logs tell you what the OCR, reconstruction
//  and classification stages actually produced, which is what you need when
//  tuning prompts or heuristics.
//
//  Output goes to the test report as an attachment, not to a file: tests run
//  in throwaway simulator clones, so anything written to the app container is
//  discarded when the run ends, and stdout is swallowed by the test harness.
//  Call `attach()` at the end of a test (or let `flush()` do it via deinit) and
//  open the log from the Report navigator in Xcode, or from the .xcresult:
//
//      xcrun xcresulttool get --path <result>.xcresult ...
//

import Foundation
import Testing
@testable import Julia

final class TestLog {

    private let name: String
    private var lines: [String] = []

    init(name: String) {
        self.name = name
        write("=== \(name) — \(Date()) ===")
        write("Apple Intelligence: \(TestAssets.appleIntelligenceStatus)")
    }

    func write(_ message: String) {
        lines.append(message)
    }

    /// Dumps what the pipeline produced for one asset.
    func dump(_ data: RecipeData, label: String) {
        write("\n--- \(label) ---")
        write("title:        \(data.title)")
        write("servings:     \(data.servings)")
        write("timings:      \(data.timings)")
        write("ingredients:  \(data.ingredients.count)")
        for line in data.ingredients { write("    • \(line)") }
        write("instructions: \(data.instructions.count)")
        for line in data.instructions { write("    \(line)") }
        if !data.summary.isEmpty { write("summary:      \(data.summary)") }
        if !data.notes.isEmpty { write("notes:        \(data.notes)") }
        write("rawText:      \(data.rawText.count) line(s)")
    }

    /// Records the accumulated log on the current test. Safe to call once.
    func attach() {
        guard !lines.isEmpty else { return }
        let body = lines.joined(separator: "\n")
        Attachment.record(body, named: "\(name).log")
        lines.removeAll()
    }

    deinit {
        // Belt and braces: if a test forgets to call attach(), still record it.
        if !lines.isEmpty {
            Attachment.record(lines.joined(separator: "\n"), named: "\(name).log")
        }
    }
}
