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
    Use empty strings for quantity, unit, and comment when they are not present.
    """

    /// Parses an ingredient string and returns a structured `Ingredient` model object.
    func parse(_ text: String, location: IngredientLocation) async throws -> Ingredient? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let prompt = "Parse this ingredient: \"\(trimmed)\""
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
