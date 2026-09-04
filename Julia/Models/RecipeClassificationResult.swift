//
//  RecipeClassificationResult.swift
//  Julia
//

import Foundation
import FoundationModels

// MARK: - Recipe Classification

/// The part of a recipe a single line belongs to.
///
/// A `@Generable` enum rather than a free string, so the model can only return
/// a category that actually exists — an invalid one is unrepresentable instead
/// of something we have to parse and defend against.
@Generable
enum LineCategory {
    case title
    case ingredient
    case instruction
    case sectionTitle
    case summary
    case timing
    case serving
    case note
    case source
    case unknown

    var lineType: RecipeLineType {
        switch self {
        case .title:        return .title
        case .ingredient:   return .ingredient
        case .instruction:  return .instruction
        case .sectionTitle: return .section_title
        case .summary:      return .summary
        case .timing:       return .time
        case .serving:      return .serving
        case .note:         return .note
        case .source:       return .source
        case .unknown:      return .unknown
        }
    }
}

/// One line's classification.
///
/// Carries the line's *number* and nothing else — deliberately not its text.
/// The previous shape returned every input line back inside one of ten string
/// arrays, so the response restated the whole input and the request paid for
/// that text twice against a ~4,096 token budget. Returning only a number and
/// a category cuts the output to a few tokens per line.
/// See docs/bugs/context-window-overflow.md.
@Generable
struct ClassifiedLine {
    @Guide(description: "The number printed before the line in the input")
    var lineNumber: Int

    @Guide(description: "Which part of the recipe this line belongs to")
    var category: LineCategory
}

/// Structured output for classifying all lines of a recipe text.
@Generable
struct ClassifiedLines {
    @Guide(description: "One entry for every numbered input line")
    var lines: [ClassifiedLine]
}

// MARK: - Ingredient Parsing

/// Structured output for parsing a single ingredient string into its components.
@Generable
struct ClassifiedIngredient {
    @Guide(description: "The ingredient name only — no quantity or unit (e.g. 'all-purpose flour', 'unsalted butter')")
    var name: String

    @Guide(description: "The numeric quantity as a decimal string (e.g. '2', '0.5', '1.5'). Empty string if not present.")
    var quantity: String

    @Guide(description: "The unit of measurement (e.g. 'cup', 'tbsp', 'oz', 'lb'). Empty string if not present.")
    var unit: String

    @Guide(description: "Preparation note or comment (e.g. 'finely chopped', 'at room temperature'). Empty string if not present.")
    var comment: String
}

// MARK: - Receipt Parsing

/// Structured output for parsing an entire grocery receipt.
@Generable
struct ParsedReceipt {
    @Guide(description: "Grocery or food product items found on the receipt. Exclude totals, taxes, subtotals, store name, date, and payment method lines.")
    var items: [ParsedReceiptItem]
}

/// A single item parsed from a receipt.
@Generable
struct ParsedReceiptItem {
    @Guide(description: "Product name, cleaned and readable (e.g. 'Whole Milk', 'Organic Eggs', 'Chicken Breast')")
    var name: String

    @Guide(description: "Quantity purchased as a decimal string (e.g. '2', '1.5'). Empty string if not shown.")
    var quantity: String

    @Guide(description: "Unit of measurement if shown (e.g. 'lb', 'oz', 'each'). Empty string if not shown.")
    var unit: String

    @Guide(description: "Item price as a decimal string (e.g. '3.99'). Empty string if not readable.")
    var price: String
}

// MARK: - Recipe Substitution Suggestions

/// Structured output for ingredient substitution recommendations.
@Generable
struct SubstitutionSuggestions {
    @Guide(description: "Substitution suggestions for missing recipe ingredients")
    var suggestions: [IngredientSubstitution]
}

/// A substitution suggestion for one missing ingredient.
@Generable
struct IngredientSubstitution {
    @Guide(description: "The name of the missing ingredient")
    var missingIngredient: String

    @Guide(description: "One or two practical substitutes that are common pantry staples")
    var substitutes: [String]

    @Guide(description: "One concise sentence explaining how the substitution affects the dish")
    var note: String
}
