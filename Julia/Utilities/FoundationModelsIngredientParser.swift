//
//  FoundationModelsIngredientParser.swift
//  Julia
//

import Foundation

/// Parses a single ingredient string into structured components using Foundation Models.
struct FoundationModelsIngredientParser {

    private let instructions = """
    You are a culinary ingredient parser. Extract the name, quantity, unit, and preparation note from ingredient text.
    The name must be just the ingredient name — no amounts, units, or comments.

    Always try to fill in quantity and unit rather than leaving them empty.
    Extract any leading number as the quantity even if no unit follows it.
    When no number or unit is given, use culinary judgment and take liberties
    based on what the ingredient normally is and any recipe context given:

    - Genuinely discrete items with no measuring unit (egg, tomato, onion,
      clove of garlic) default to quantity "1", unit "item".
    - Ingredients normally measured by volume or weight (flour, sugar,
      butter, milk, rice, oil, etc.) should get a realistic unit and amount
      for the dish rather than "item" — e.g. flour in a cake recipe is
      almost always a few cups, not "1 item". Use the recipe context if
      given to pick a plausible quantity and unit; otherwise use the most
      common convention for that ingredient (e.g. flour -> cups, butter ->
      tablespoons or cups, oil -> tablespoons).

    Only leave quantity and unit empty when no quantity genuinely applies at
    all (e.g. "salt to taste"). Use empty string for comment when not present.
    """

    /// Parses an ingredient string and returns a structured `Ingredient` model object.
    /// `recipeContext` — e.g. the recipe's title — helps the model pick a
    /// realistic quantity/unit when the ingredient text doesn't specify one
    /// (see instructions above). Optional; parsing still works without it,
    /// just with less to go on for that inference.
    func parse(_ text: String, location: IngredientLocation, recipeContext: String? = nil) async throws -> Ingredient? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var prompt = "Parse this ingredient: \"\(trimmed)\""
        if let recipeContext, !recipeContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prompt += "\n\nRecipe context: \(recipeContext)"
        }
        let result = try await FoundationModelsService.shared.generate(
            prompt,
            type: ClassifiedIngredient.self,
            instructions: instructions
        )

        guard !result.name.isEmpty else { return nil }

        let quantity = Double(result.quantity)
        let unit = result.unit.isEmpty ? nil : result.unit
        let comment = result.comment.isEmpty ? nil : result.comment

        return Ingredient(
            name: result.name,
            location: location,
            quantity: quantity,
            unit: unit,
            comment: comment
        )
    }
}
