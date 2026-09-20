//
//  RecipeSuggestionsViewModel.swift
//  Julia
//

import Foundation

/// View model that drives the "What can I cook?" feature.
@Observable
@MainActor
class RecipeSuggestionsViewModel {
    var matches: [RecipeMatch] = []
    var isLoading = false
    var includePantry: Bool = true
    var includeGrocery: Bool = false

    /// Substitution results keyed by recipe ID; populated on demand.
    var substitutionsByRecipeId: [String: SubstitutionSuggestions] = [:]
    var isFetchingSubstitutions = false
    var substitutionError: String? = nil

    /// Recomputes coverage matches using the provided ingredients.
    func computeMatches(recipes: [Recipe], ingredients: [Ingredient]) {
        isLoading = true
        let available = ingredients.filter {
            (includePantry && $0.location == .pantry)
                || (includeGrocery && $0.location == .grocery)
        }
        matches = RecipeMatchingService.computeMatches(
            recipes: recipes,
            availableIngredients: available
        )
        isLoading = false
    }

    /// Fetches Foundation Models substitution suggestions for missing ingredients.
    /// Only called when the user explicitly requests suggestions for a specific recipe.
    func fetchSubstitutions(for match: RecipeMatch) async {
        guard !match.missingIngredients.isEmpty else { return }
        guard await FoundationModelsService.shared.isAvailable else {
            substitutionError = "Apple Intelligence is not available on this device."
            return
        }

        isFetchingSubstitutions = true
        substitutionError = nil
        defer { isFetchingSubstitutions = false }

        // Limit to the 10 most impactful missing ingredients to stay within token budget
        let missingIngredients = Array(match.missingIngredients.prefix(10))
        let missingList = missingIngredients.map { "- \($0)" }.joined(separator: "\n")
        let prompt = """
        For the recipe "\(match.recipe.title)", suggest a practical substitution for each of these \(missingIngredients.count) missing ingredients:
        \(missingList)

        Only suggest substitutes that are common pantry staples most home cooks would have.
        Return exactly \(missingIngredients.count) suggestion(s) — one per ingredient listed above, no more and no fewer. Each suggestion's missingIngredient must exactly match one listed ingredient, with no repeats.
        """

        do {
            let result = try await FoundationModelsService.shared.generate(
                prompt,
                type: SubstitutionSuggestions.self,
                instructions: "You are a helpful culinary assistant. Suggest realistic ingredient substitutions, one per ingredient given — never pad the list with repeats or invented ingredients."
            )
            // The model is non-deterministic and has been observed padding the
            // list with duplicates even when told not to (e.g. 1 missing
            // ingredient → 3 identical suggestions). Enforce alignment
            // client-side: keep only suggestions that match a missing
            // ingredient, and only the first suggestion per ingredient.
            var seen = Set<String>()
            let alignedSuggestions = result.suggestions.filter { suggestion in
                let key = suggestion.missingIngredient.lowercased()
                guard missingIngredients.contains(where: { $0.lowercased() == key }) else { return false }
                return seen.insert(key).inserted
            }
            substitutionsByRecipeId[match.recipe.id] = SubstitutionSuggestions(suggestions: alignedSuggestions)
        } catch {
            substitutionError = "Could not generate substitutions: \(error.localizedDescription)"
        }
    }
}
