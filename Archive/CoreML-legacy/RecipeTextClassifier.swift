//
//  RecipeTextClassifier.swift  —  ARCHIVED, NOT IN THE BUILD
//
//  The document-level classifier from the Core ML pipeline, kept for reference
//  alongside RecipeClassifier.mlmodel. Superseded by
//  FoundationModelsRecipeClassifier.
//
//  By the time it was archived the class had already been reduced to a stub:
//  the merge that introduced Foundation Models stripped its Core ML inference,
//  leaving only a threshold it no longer applied. Nothing referenced it.
//
//  `RecipeLineType` used to live in this file and is still very much live —
//  it moved to Julia/Models/RecipeLineType.swift. `RecipeTextLine` below had no
//  references and came along with the class.
//
//  See ../README.md and docs/AUDIT.md §5.
//

import Foundation

/// Represents a classified line of text from a recipe.
struct RecipeTextLine {
    let text: String
    let lineType: RecipeLineType
    let confidence: Double
}

/// Handled classification of recipe text lines. Vestigial by the time it was
/// archived — see the file header.
class RecipeTextClassifier {
    let confidenceThreshold: Double

    init(confidenceThreshold: Double = 0.65) {
        self.confidenceThreshold = confidenceThreshold
    }
}
