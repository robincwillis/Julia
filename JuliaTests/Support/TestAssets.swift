//
//  TestAssets.swift
//  JuliaTests
//
//  Auto-discovers test fixtures from the test bundle so adding a new test case
//  is just dropping a file into JuliaTests/Fixtures/ — no code change, no
//  project file change. JuliaTests is a synchronized folder group, so Xcode
//  picks up new files automatically and copies them into the test bundle.
//
//  Fixtures/Images  →  .jpg .jpeg .png .heic   (photos of recipes, for OCR)
//  Fixtures/Text    →  .txt                    (pasted / typed recipe text)
//  Fixtures/Web     →  .html                   (saved recipe pages, for JSON-LD)
//

import Foundation
import UIKit
import FoundationModels

/// Anchors `Bundle(for:)` to the test bundle. More reliable than looking the
/// bundle up by identifier, which returns nil unless the bundle is loaded.
private final class BundleToken {}

enum TestAssets {

    static let bundle = Bundle(for: BundleToken.self)

    // MARK: - Extensions we treat as each fixture kind

    static let imageExtensions = ["jpg", "jpeg", "png", "heic"]
    static let textExtensions = ["txt"]
    static let webExtensions = ["html", "htm"]

    // MARK: - Discovery

    /// Every image fixture in the bundle, keyed by filename without extension.
    /// Resources are flattened into the bundle root, so subfolders under
    /// Fixtures/ are organisational only — names must still be unique.
    static func images() -> [(name: String, image: UIImage)] {
        urls(withExtensions: imageExtensions).compactMap { url in
            guard let image = UIImage(contentsOfFile: url.path) else { return nil }
            return (url.deletingPathExtension().lastPathComponent, image)
        }
    }

    static func texts() -> [(name: String, text: String)] {
        urls(withExtensions: textExtensions).compactMap { url in
            guard let text = try? String(contentsOf: url, encoding: .utf8),
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }
            return (url.deletingPathExtension().lastPathComponent, text)
        }
    }

    static func webPages() -> [(name: String, html: String)] {
        urls(withExtensions: webExtensions).compactMap { url in
            guard let html = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return (url.deletingPathExtension().lastPathComponent, html)
        }
    }

    /// Sorted so test output ordering is stable run to run.
    private static func urls(withExtensions extensions: [String]) -> [URL] {
        extensions
            .flatMap { bundle.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    // MARK: - Synthetic fixtures

    /// Renders text into an image so OCR can be exercised without committing a
    /// binary photo. Deterministic, and independent of Apple Intelligence.
    static func renderedTextImage(
        _ lines: [String],
        size: CGSize = CGSize(width: 1000, height: 1400)
    ) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40),
                .foregroundColor: UIColor.black
            ]
            var y: CGFloat = 60
            for line in lines {
                let text = line as NSString
                text.draw(
                    in: CGRect(x: 60, y: y, width: size.width - 120, height: 60),
                    withAttributes: attributes
                )
                y += 60
            }
        }
    }

    // MARK: - Capability gating

    /// Whether the on-device model is usable here. The recipe classifier and the
    /// ingredient parser both route through Foundation Models, which is
    /// unavailable on most simulators — tests that need it are skipped rather
    /// than failed, via `.enabled(if:)`.
    static var isAppleIntelligenceAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    /// Human-readable reason, for logging when suites are skipped.
    static var appleIntelligenceStatus: String {
        switch SystemLanguageModel.default.availability {
        case .available:
            return "available"
        case .unavailable(let reason):
            return "unavailable (\(reason))"
        @unknown default:
            return "unknown"
        }
    }
}
