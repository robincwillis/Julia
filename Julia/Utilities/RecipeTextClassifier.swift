//
//  RecipeTextClassifier.swift
//  Julia
//

import Foundation

/// Represents the type of line in a recipe text
enum RecipeLineType: String, CaseIterable {
    case title = "title"
    case ingredient = "ingredient"
    case instruction = "instruction"
    case serving = "serving"
    case summary = "summary"
    case time = "time"
    case section_title = "section_title"
    case note = "note"
    case source = "source"
    case unknown = "unknown"
}

/// Represents a classified line of text from a recipe
struct RecipeTextLine {
    let text: String
    let lineType: RecipeLineType
    let confidence: Double
}

/// Handles classification of recipe text lines using Foundation Models.
class RecipeTextClassifier {
    let confidenceThreshold: Double

    init(confidenceThreshold: Double = 0.65) {
        self.confidenceThreshold = confidenceThreshold
    }
}
