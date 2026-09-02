//
//  JuliaTools.swift
//  Julia
//

import Foundation
import FoundationModels
import SwiftData

// MARK: - AddToGroceryListTool

struct AddToGroceryListTool: Tool {
    let name = "addToGroceryList"
    let description = "Add one or more ingredients to the user's grocery shopping list. Use this when the user asks to add ingredients, build a shopping list, or wants to prepare to cook a specific dish."

    nonisolated(unsafe) let context: ModelContext

    @Generable
    struct Arguments {
        @Guide(description: "Ingredient strings with quantities, e.g. '2 cups flour', '1 lb chicken breast'")
        var ingredients: [String]
    }

    func call(arguments: Arguments) async throws -> String {
        let (count, names) = await MainActor.run {
            var parsed: [Ingredient] = []
            for input in arguments.ingredients {
                if let ingredient = IngredientParser.fromString(input: input, location: .grocery) {
                    context.insert(ingredient)
                    parsed.append(ingredient)
                }
            }
            try? context.save()
            return (parsed.count, parsed.map { $0.name }.joined(separator: ", "))
        }

        if count == 0 {
            return "No ingredients could be parsed."
        }
        return "Added \(count) item(s): \(names)."
    }
}

// MARK: - CreateRecipeTool

struct CreateRecipeTool: Tool {
    let name = "createRecipe"
    let description = "Create and save a new recipe to the user's collection. Use this when the user asks to create, generate, or save a recipe."

    nonisolated(unsafe) let context: ModelContext

    @Generable
    struct Arguments {
        @Guide(description: "The title of the recipe")
        var title: String

        @Guide(description: "Brief description, empty if none")
        var description: String

        @Guide(description: "Number of servings, 0 if unknown")
        var servings: Int

        @Guide(description: "Ingredient strings with quantities")
        var ingredients: [String]

        @Guide(description: "Step-by-step instructions")
        var steps: [String]

        @Guide(description: "Prep time in minutes, 0 if unknown")
        var prepMinutes: Int

        @Guide(description: "Cook time in minutes, 0 if unknown")
        var cookMinutes: Int
    }

    func call(arguments: Arguments) async throws -> String {
        let ingredientCount = arguments.ingredients.count
        let stepCount = arguments.steps.count
        let title = arguments.title

        await MainActor.run {
            let recipe = Recipe(title: arguments.title)

            if !arguments.description.isEmpty {
                recipe.summary = arguments.description
            }
            if arguments.servings > 0 {
                recipe.servings = arguments.servings
            }
            recipe.sourceType = .manual
            context.insert(recipe)

            for (index, input) in arguments.ingredients.enumerated() {
                if let ingredient = IngredientParser.fromString(input: input, location: .recipe) {
                    ingredient.position = index
                    ingredient.recipe = recipe
                    context.insert(ingredient)
                }
            }

            for (index, value) in arguments.steps.enumerated() {
                let step = Step(value: value, position: index, recipe: recipe)
                recipe.instructions.append(step)
                context.insert(step)
            }

            if arguments.prepMinutes > 0 {
                let prep = Timing(
                    type: "prep",
                    hours: arguments.prepMinutes / 60,
                    minutes: arguments.prepMinutes % 60,
                    position: 0,
                    recipe: recipe
                )
                context.insert(prep)
            }

            if arguments.cookMinutes > 0 {
                let cook = Timing(
                    type: "cook",
                    hours: arguments.cookMinutes / 60,
                    minutes: arguments.cookMinutes % 60,
                    position: 1,
                    recipe: recipe
                )
                context.insert(cook)
            }

            try? context.save()
        }

        return "Created '\(title)' with \(ingredientCount) ingredients and \(stepCount) steps. It's now in your recipe collection."
    }
}
