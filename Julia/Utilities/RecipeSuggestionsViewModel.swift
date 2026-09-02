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
        let missingList = match.missingIngredients.prefix(10).joined(separator: ", ")
        let prompt = """
        For the recipe "\(match.recipe.title)", suggest practical substitutions for these missing ingredients: \(missingList).
        Only suggest substitutes that are common pantry staples most home cooks would have.
        """

        do {
            let result = try await FoundationModelsService.shared.generate(
                prompt,
                type: SubstitutionSuggestions.self,
                instructions: "You are a helpful culinary assistant. Suggest realistic ingredient substitutions."
            )
            substitutionsByRecipeId[match.recipe.id] = result
        } catch {
            substitutionError = "Could not generate substitutions: \(error.localizedDescription)"
        }
    }
}
