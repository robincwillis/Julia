//
//  FoundationModelsRecipeEditor.swift
//  Julia
//

import Foundation

/// Backs the recipe "Edit with AI" action: restructures ingredient lines that
/// import left unstructured (whole line dumped into the name, no
/// quantity/unit), and infers whichever recipe-level fields the caller says
/// are currently missing. Never asked to touch fields that already have a
/// value — the caller decides what's missing and only applies results for
/// those fields, so a non-empty model response for something already set is
/// simply ignored rather than overwriting user data.
struct FoundationModelsRecipeEditor {
    private let instructions = """
    You are a culinary recipe editor. Restructure the given ingredient lines \
    into name/quantity/unit/comment, and, only where explicitly asked, infer \
    recipe-level fields from the title, instructions, and ingredients. Leave \
    a field empty (empty string or empty array) whenever it cannot be \
    confidently determined — never guess or invent information that isn't \
    supported by the given text.
    """

    struct Input {
        let title: String
        let instructions: [String]
        /// Ingredient lines that need restructuring, in a stable order —
        /// the result's `ingredients` array is matched back to these by
        /// index, so this order must be preserved by the caller.
        let unstructuredIngredients: [String]
        let needsServings: Bool
        let needsSummary: Bool
        let needsTimings: Bool
    }

    func edit(_ input: Input) async throws -> RecipeAIEdit {
        var sections: [String] = ["Recipe title: \(input.title)"]

        if !input.instructions.isEmpty {
            let numbered = input.instructions.enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            sections.append("Instructions:\n\(numbered)")
        }

        if !input.unstructuredIngredients.isEmpty {
            let numbered = input.unstructuredIngredients.enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            sections.append("Ingredient lines to restructure, in order:\n\(numbered)")
        }

        var asks: [String] = []
        if input.needsServings { asks.append("the number of servings") }
        if input.needsSummary { asks.append("a one-to-two sentence summary") }
        if input.needsTimings { asks.append("prep/cook timing") }
        if !asks.isEmpty {
            sections.append("Also determine, only if confident: \(asks.joined(separator: ", ")).")
        }

        let prompt = sections.joined(separator: "\n\n")

        return try await FoundationModelsService.shared.generate(
            prompt,
            type: RecipeAIEdit.self,
            instructions: instructions
        )
    }
}
