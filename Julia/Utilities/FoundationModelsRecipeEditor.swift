//
//  FoundationModelsRecipeEditor.swift
//  Julia
//

import Foundation

/// Backs the recipe "Edit with AI" action: restructures ingredient lines that
/// import left unstructured (whole line dumped into the name, no
/// quantity/unit), detects ingredient lines and instruction steps that are
/// actually section headings (e.g. "For the dressing") and splits them into
/// proper groups, infers whichever recipe-level fields the caller says are
/// currently missing, and — when the caller supplies a custom instruction —
/// applies it across the full ingredient list (e.g. "make this vegetarian",
/// "double the recipe"). Never asked to touch recipe-level fields that
/// already have a value — the caller decides what's missing and only
/// applies results for those fields, so a non-empty model response for
/// something already set is simply ignored rather than overwriting user data.
struct FoundationModelsRecipeEditor {
    private let instructions = """
    You are a culinary recipe editor.

    INGREDIENTS: Restructure the given ingredient lines into \
    name/quantity/unit/comment. Always try to fill in quantity and unit \
    rather than leaving them empty. Extract any leading number as the \
    quantity even if no unit follows it. When no number or unit is given, \
    use culinary judgment and take liberties based on what the ingredient \
    normally is, the recipe's title, and its instructions:

    - Genuinely discrete items with no measuring unit (egg, tomato, onion,
      clove of garlic) default to quantity "1", unit "item".
    - Ingredients normally measured by volume or weight (flour, sugar,
      butter, milk, rice, oil, etc.) should get a realistic unit and amount
      for this specific recipe rather than "item" — e.g. flour in a cake
      recipe is almost always a few cups, not "1 item". Use the recipe's
      title and instructions to judge what's plausible; fall back to the
      most common convention for that ingredient if the recipe gives no
      further hint (e.g. flour -> cups, butter -> tablespoons or cups, oil
      -> tablespoons).

    Only leave quantity and unit empty when no quantity genuinely applies at
    all (e.g. "salt to taste"). Return exactly one ingredient entry per
    ingredient line given, in the same order — never add or remove entries,
    even when applying a custom instruction that changes an ingredient's
    name, quantity, or unit.

    INGREDIENT SECTIONS: Recipe imports commonly misfile a section heading
    (e.g. "For the dressing", "Dressing:", "For the crust") as if it were an
    ordinary ingredient, when it's actually introducing a sub-group of the
    ingredients that follow it. A separate "unsectioned ingredients" list
    below (distinct from the ingredient lines you restructure into the main
    `ingredients` field above) is given specifically to check for this. If
    one of those lines is actually a heading, regroup ALL of them into
    `ingredientGroups`: split at each heading, the heading text becomes that
    group's `name` (removed from the ingredients themselves), and the
    ingredients between one heading and the next (or the end) become that
    group's ingredients — restructured into name/quantity/unit/comment the
    same way as the main INGREDIENTS guidance above. Ingredients before the
    first heading go in a group with an empty `name`. If none of them are
    actually headings, leave `ingredientGroups` empty.

    INSTRUCTIONS: Recipe imports commonly misfile a section heading (e.g.
    "For the dressing", "Dressing:", "For the crust") as if it were an
    instruction step, when it's actually introducing a sub-group of the
    steps that follow it. Check the given instruction steps for this. If you
    find one, regroup ALL the given steps into `instructionGroups`: split at
    each heading, the heading text becomes that group's `name` (removed from
    the steps themselves), and the steps between one heading and the next
    (or the end) become that group's `steps`, in order. Steps before the
    first heading go in a group with an empty `name`. If none of the given
    steps are actually headings, leave `instructionGroups` empty — do not
    restructure or reword steps that don't need it.

    If a custom instruction is given, apply it to the ingredients, \
    instructions, and/or recipe-level fields as appropriate (e.g. "make this \
    vegetarian" changes relevant ingredient names; "double the recipe" \
    doubles every quantity and servings). The custom instruction is the one \
    case where you should also update recipe-level fields that already have \
    a value, not just fields that are blank.

    Separately, when not overridden by a custom instruction above, only \
    infer recipe-level fields (servings, summary, timings) where explicitly \
    asked, from the title, instructions, and ingredients — and never guess: \
    leave a field empty (empty string or empty array) whenever it cannot be \
    confidently determined from the given text.
    """

    struct Input {
        let title: String
        /// Current unsectioned instruction steps, in order — sent both as
        /// context for inferring other fields, and as the target for
        /// section-heading detection/restructuring (see `instructions`
        /// above). Steps already inside an instruction section are not
        /// included; re-detecting structure that already exists isn't needed.
        let instructions: [String]
        /// Ingredient lines to send to the model, in a stable order — the
        /// result's `ingredients` array is matched back to these by index,
        /// so this order must be preserved by the caller. This is just the
        /// unstructured ones when there's no custom instruction (cheaper,
        /// and nothing else needs touching), or the full current list when
        /// there is one (a custom instruction like "double the recipe" needs
        /// to see and revise everything, not just what's broken).
        let ingredientLines: [String]
        /// Current unsectioned ingredients, in order — sent specifically for
        /// section-heading detection (see INGREDIENT SECTIONS above), always
        /// when non-empty regardless of what `ingredientLines` contains.
        /// Ingredients already inside an IngredientSection are not included;
        /// re-detecting structure that already exists isn't needed.
        let unsectionedIngredientLines: [String]
        let needsServings: Bool
        let needsSummary: Bool
        let needsTimings: Bool
        /// Free-text instruction from the user, e.g. "make this vegetarian".
        /// When present, the model may also revise recipe-level fields that
        /// already have a value (e.g. doubling servings), not just blank ones.
        let customInstruction: String?
    }

    func edit(_ input: Input) async throws -> RecipeAIEdit {
        var sections: [String] = ["Recipe title: \(input.title)"]

        if !input.instructions.isEmpty {
            let numbered = input.instructions.enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            sections.append("Instruction steps, in order — check for a misfiled section heading per the INSTRUCTIONS guidance:\n\(numbered)")
        }

        if !input.ingredientLines.isEmpty {
            let numbered = input.ingredientLines.enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            sections.append("Ingredients, in order:\n\(numbered)")
        }

        if !input.unsectionedIngredientLines.isEmpty {
            let numbered = input.unsectionedIngredientLines.enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            sections.append("Unsectioned ingredients, in order — check for a misfiled section heading per the INGREDIENT SECTIONS guidance:\n\(numbered)")
        }

        var asks: [String] = []
        if input.needsServings { asks.append("the number of servings") }
        if input.needsSummary { asks.append("a one-to-two sentence summary") }
        if input.needsTimings { asks.append("prep/cook timing") }
        if !asks.isEmpty {
            sections.append("Also determine, only if confident: \(asks.joined(separator: ", ")).")
        }

        if let customInstruction = input.customInstruction, !customInstruction.isEmpty {
            sections.append("Custom instruction from the user — apply this: \(customInstruction)")
        }

        let prompt = sections.joined(separator: "\n\n")

        return try await FoundationModelsService.shared.generate(
            prompt,
            type: RecipeAIEdit.self,
            instructions: instructions
        )
    }
}
