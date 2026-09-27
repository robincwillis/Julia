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

    @Guide(description: "The numeric quantity as a decimal string (e.g. '2', '0.5', '1.5'). Extract any leading number even when no unit follows it (e.g. '2 eggs' -> '2'). If no number is given, use culinary judgment: a discrete countable item (egg, tomato, onion) defaults to '1'; an ingredient normally measured by volume/weight (flour, sugar, butter, oil) should get a realistic quantity for the dish, using any recipe context given (e.g. flour in a cake is usually a few cups). Leave empty only when no quantity applies at all (e.g. 'salt to taste', 'pepper').")
    var quantity: String

    @Guide(description: "The unit of measurement (e.g. 'cup', 'tbsp', 'oz', 'lb'). Use 'item' only for things genuinely counted individually with no measuring unit, e.g. an egg, a tomato, an onion. For ingredients normally measured by volume or weight (flour, sugar, butter, milk, rice, oil, etc.) with no unit given, infer a realistic one by culinary convention and any recipe context — e.g. flour is almost always 'cup', not 'item'. Empty string only when quantity itself is also empty.")
    var unit: String

    @Guide(description: "Preparation note or comment (e.g. 'finely chopped', 'at room temperature'). Empty string if not present.")
    var comment: String
}

// MARK: - Recipe AI Edit

/// One inferred timing entry (e.g. "Prep: 15 min").
@Generable
struct ClassifiedTiming {
    @Guide(description: "The kind of timing, e.g. 'Prep', 'Cook', 'Bake', 'Total'")
    var type: String

    @Guide(description: "Hours as a whole number, 0 if under an hour")
    var hours: Int

    @Guide(description: "Minutes as a whole number, 0-59")
    var minutes: Int
}

/// One group of instruction steps sharing a heading, or the initial
/// ungrouped steps when `name` is empty. See `RecipeAIEdit.instructionGroups`.
@Generable
struct ClassifiedInstructionGroup {
    @Guide(description: "Name of this group, e.g. 'Dressing', 'Crust'. Empty string for the initial steps that come before any section heading.")
    var name: String

    @Guide(description: "The steps belonging to this group, in order, as clean instruction text. If this group's name came from a step that was actually a section heading (e.g. 'For the dressing'), that heading line is not itself a step — it becomes `name` above and is removed from this list.")
    var steps: [String]
}

/// One group of ingredients sharing a heading, or the initial ungrouped
/// ingredients when `name` is empty. See `RecipeAIEdit.ingredientGroups`.
@Generable
struct ClassifiedIngredientGroup {
    @Guide(description: "Name of this group, e.g. 'Dressing', 'Crust'. Empty string for the initial ingredients that come before any section heading.")
    var name: String

    @Guide(description: "The ingredients belonging to this group, restructured into name/quantity/unit/comment, in order. If this group's name came from an ingredient line that was actually a section heading (e.g. 'For the dressing'), that heading line is not itself an ingredient — it becomes `name` above and is removed from this list.")
    var ingredients: [ClassifiedIngredient]
}

/// Structured output for "Edit with AI": restructures ingredient lines that
/// weren't cleanly split into quantity/unit/name, detects ingredient lines
/// and instruction steps that are actually section headings and splits them
/// out, and infers whichever recipe-level fields the caller asked for
/// because they're currently blank. Every field is left empty/unset when it
/// can't be confidently determined from the given text — the model is not
/// meant to invent facts (except where a custom instruction explicitly asks
/// it to change something).
@Generable
struct RecipeAIEdit {
    @Guide(description: "One entry per ingredient line provided, in the same order. Restructure each into name/quantity/unit/comment.")
    var ingredients: [ClassifiedIngredient]

    @Guide(description: "Number of servings this recipe makes, as a whole number string (e.g. '4'). Empty string if it cannot be confidently determined from the title/instructions/ingredients.")
    var servings: String

    @Guide(description: "A one-to-two sentence summary of the recipe. Empty string if one cannot be confidently written from the given text.")
    var summary: String

    @Guide(description: "Timing entries (prep, cook, etc.) inferred from the instructions. Empty array if none can be confidently determined.")
    var timings: [ClassifiedTiming]

    @Guide(description: "Only set when the given instruction steps contain one that's actually a section heading rather than a real instruction (e.g. a short step reading 'For the dressing' or 'Dressing:') — regroup ALL given steps into groups split at each heading, with the heading text becoming that group's name (not a step) and remaining as the group's steps. Preserve step order. Leave this empty when every given step is a genuine instruction with no hidden headings — do not restructure or reword steps that don't need it.")
    var instructionGroups: [ClassifiedInstructionGroup]

    @Guide(description: "Only set when the given unsectioned ingredients (see the separate 'unsectioned ingredients' list, not the general ingredients-to-restructure list) contain one that's actually a section heading rather than a real ingredient (e.g. 'For the dressing', 'Dressing:') — regroup ALL of those unsectioned ingredients into groups split at each heading, restructuring each into name/quantity/unit/comment same as the main `ingredients` field. Preserve order. Leave this empty when none of them are actually headings.")
    var ingredientGroups: [ClassifiedIngredientGroup]
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
    @Guide(description: "Exactly one substitution entry per missing ingredient listed in the prompt — matched by name, no duplicates, no invented ingredients")
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
