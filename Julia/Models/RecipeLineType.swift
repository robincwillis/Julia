//
//  RecipeLineType.swift
//  Julia
//

import Foundation

/// The kind of line a piece of recipe text represents.
///
/// Lives here rather than alongside a classifier because it is a model type the
/// whole pipeline speaks: `RecipeData.classifiedLines`, `LineCategory.lineType`,
/// and the review sheet all use it. It previously sat in
/// `RecipeTextClassifier.swift`, which is why archiving that file could not be
/// a straight move.
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
