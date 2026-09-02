//
//  RecipeMatchingService.swift
//  Julia
//

import Foundation

/// Represents how well a recipe's ingredients are covered by available pantry/grocery items.
struct RecipeMatch: Identifiable {
    var id: String { recipe.id }
    let recipe: Recipe
    let coveredCount: Int
    let totalCount: Int
    let missingIngredients: [String]

    var coveragePercent: Double {
        totalCount > 0 ? Double(coveredCount) / Double(totalCount) : 0
    }

    /// Human-readable coverage label, e.g. "8/12 ingredients".
    var coverageLabel: String {
        "\(coveredCount)/\(totalCount) ingredient\(totalCount == 1 ? "" : "s")"
    }
}

/// Pure-Swift service that computes pantry-to-recipe coverage.
/// No ML involved — uses string normalization and substring containment.
struct RecipeMatchingService {

    /// Compute coverage for all recipes against the provided available ingredients.
    /// - Parameters:
    ///   - recipes: All saved `Recipe` objects.
    ///   - availableIngredients: Pantry (and optionally grocery) `Ingredient` objects.
    /// - Returns: `RecipeMatch` array sorted by coverage descending.
    static func computeMatches(
        recipes: [Recipe],
        availableIngredients: [Ingredient]
    ) -> [RecipeMatch] {
        let availableNames = Set(availableIngredients.map { normalize($0.name) })
        return recipes
            .map { computeMatch(recipe: $0, availableNames: availableNames) }
            .sorted { $0.coveragePercent > $1.coveragePercent }
    }

    // MARK: - Private

    private static func computeMatch(recipe: Recipe, availableNames: Set<String>) -> RecipeMatch {
        let recipeIngredients = recipe.allIngredients
        var coveredCount = 0
        var missing: [String] = []

        for ingredient in recipeIngredients {
            let normalizedIngredient = normalize(ingredient.name)
            // Match if pantry contains this ingredient name, or if one is a substring of the other
            let matched = availableNames.contains(normalizedIngredient)
                || availableNames.contains(where: { available in
                    available.contains(normalizedIngredient) || normalizedIngredient.contains(available)
                })
            if matched {
                coveredCount += 1
            } else {
                missing.append(ingredient.name)
            }
        }

        return RecipeMatch(
            recipe: recipe,
            coveredCount: coveredCount,
            totalCount: recipeIngredients.count,
            missingIngredients: missing
        )
    }

    /// Normalizes an ingredient name for comparison:
    /// lowercase, trim whitespace, strip parenthetical annotations like "(optional)".
    static func normalize(_ name: String) -> String {
        var result = name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove parenthetical annotations (e.g. "(optional)", "(divided)")
        if let range = result.range(of: #"\s*\([^)]*\)"#, options: .regularExpression) {
            result.removeSubrange(range)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
