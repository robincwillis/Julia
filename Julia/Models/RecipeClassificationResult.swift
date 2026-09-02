//
//  RecipeClassificationResult.swift
//  Julia
//

import Foundation
import FoundationModels

// MARK: - Recipe Classification

/// Structured output for classifying all lines of a recipe text.
@Generable
struct ClassifiedRecipe {
    @Guide(description: "The recipe title — the name of the dish")
    var title: String

    @Guide(description: "Ingredient lines exactly as they appear in the input")
    var ingredients: [String]

    @Guide(description: "Step-by-step cooking instruction lines")
    var instructions: [String]

    @Guide(description: "Section header lines that group ingredients (e.g. 'For the sauce:', 'Topping:')")
    var sectionTitles: [String]

    @Guide(description: "Summary, description, or introduction lines about the dish")
    var summary: [String]

    @Guide(description: "Timing information lines (prep time, cook time, bake time, total time)")
    var timings: [String]

    @Guide(description: "Serving size or yield lines (e.g. 'Serves 4', 'Makes 24 cookies')")
    var servings: [String]

    @Guide(description: "Notes, tips, or variations lines")
    var notes: [String]

    @Guide(description: "Source attribution lines (author, publication, website)")
    var source: [String]

    @Guide(description: "Lines that do not fit any other category")
    var unknown: [String]
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
