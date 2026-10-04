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

// MARK: - UpdateRecipeTool

/// Lets the assistant edit and save changes to the specific recipe the user
/// is currently viewing/chatting about. Only registered when ChefChatView
/// has a recipe in scope — there's nothing to update in the generic chat.
struct UpdateRecipeTool: Tool {
    let name = "updateRecipe"
    let description = "Update and save changes to the recipe currently being viewed — title, description, servings, ingredients, and/or instructions, including ones organized into named sections (e.g. 'For the Sauce'). Use this when the user asks to change, fix, edit, improve, scale, or otherwise modify this recipe. Only set the fields that should change; leave the rest at their defaults (empty string, 0, or false) to leave them unchanged."

    nonisolated(unsafe) let context: ModelContext
    nonisolated(unsafe) let recipe: Recipe

    @Generable
    struct IngredientSectionUpdate {
        @Guide(description: "Section heading, e.g. 'For the Sauce'")
        var name: String

        @Guide(description: "Ingredient strings with quantities for this section, e.g. '2 cups flour'")
        var ingredients: [String]
    }

    @Generable
    struct InstructionSectionUpdate {
        @Guide(description: "Section heading, e.g. 'For the Sauce'")
        var name: String

        @Guide(description: "Step-by-step instructions for this section")
        var steps: [String]
    }

    @Generable
    struct Arguments {
        @Guide(description: "New title, empty string to leave unchanged")
        var title: String

        @Guide(description: "New description/summary, empty string to leave unchanged")
        var description: String

        @Guide(description: "New serving count, 0 to leave unchanged")
        var servings: Int

        @Guide(description: "Set true to replace the whole UNSECTIONED ingredient list with `ingredients` below — required for any change to ingredients that aren't under a section heading, even a small one (the entire unsectioned list must be given, not just the changed items). Does not touch sectioned ingredients — use replaceIngredientSections for those. False leaves the existing unsectioned ingredients untouched and `ingredients` is ignored.")
        var replaceIngredients: Bool

        @Guide(description: "Full replacement unsectioned ingredient list with quantities (e.g. '2 cups flour'), in order. Only used when replaceIngredients is true.")
        var ingredients: [String]

        @Guide(description: "Set true to replace the whole UNSECTIONED instructions list with `steps` below — required for any change to instructions that aren't under a section heading, even a small one. Does not touch sectioned instructions — use replaceInstructionSections for those. False leaves the existing unsectioned instructions untouched and `steps` is ignored.")
        var replaceInstructions: Bool

        @Guide(description: "Full replacement step-by-step unsectioned instructions, in order. Only used when replaceInstructions is true.")
        var steps: [String]

        @Guide(description: "Set true to replace every ingredient SECTION with `ingredientSections` below — required if the recipe has sections (e.g. 'For the Sauce') and any of their ingredients change, including scaling. Does not touch unsectioned ingredients. False leaves existing sections untouched and `ingredientSections` is ignored. Pass an empty list with this set true to remove all ingredient sections.")
        var replaceIngredientSections: Bool

        @Guide(description: "Full replacement list of ingredient sections, in order. Only used when replaceIngredientSections is true.")
        var ingredientSections: [IngredientSectionUpdate]

        @Guide(description: "Set true to replace every instruction SECTION with `instructionSections` below — required if the recipe has sections and any of their steps change. Does not touch unsectioned instructions. False leaves existing sections untouched and `instructionSections` is ignored. Pass an empty list with this set true to remove all instruction sections.")
        var replaceInstructionSections: Bool

        @Guide(description: "Full replacement list of instruction sections, in order. Only used when replaceInstructionSections is true.")
        var instructionSections: [InstructionSectionUpdate]
    }

    func call(arguments: Arguments) async throws -> String {
        let changed = await MainActor.run { () -> [String] in
            var changes: [String] = []

            context.undoManager?.beginUndoGrouping()
            context.undoManager?.setActionName("Update Recipe")
            defer { context.undoManager?.endUndoGrouping() }

            if !arguments.title.isEmpty && arguments.title != recipe.title {
                recipe.title = arguments.title
                changes.append("title")
            }
            if !arguments.description.isEmpty {
                recipe.summary = arguments.description
                changes.append("description")
            }
            if arguments.servings > 0 {
                recipe.servings = arguments.servings
                changes.append("servings")
            }
            if arguments.replaceIngredients {
                let unsectioned = recipe.ingredients.filter { $0.section == nil }
                for old in unsectioned { context.delete(old) }
                recipe.ingredients.removeAll { $0.section == nil }

                for (index, input) in arguments.ingredients.enumerated() {
                    if let ingredient = IngredientParser.fromString(input: input, location: .recipe) {
                        ingredient.position = index
                        ingredient.recipe = recipe
                        context.insert(ingredient)
                    }
                }
                changes.append("ingredients")
            }
            if arguments.replaceInstructions {
                for old in recipe.instructions { context.delete(old) }
                recipe.instructions.removeAll()

                for (index, value) in arguments.steps.enumerated() {
                    let step = Step(value: value, position: index, recipe: recipe)
                    recipe.instructions.append(step)
                    context.insert(step)
                }
                changes.append("instructions")
            }
            if arguments.replaceIngredientSections {
                for old in recipe.sections {
                    for ingredient in old.ingredients { context.delete(ingredient) }
                    context.delete(old)
                }
                recipe.sections.removeAll()

                for (sectionIndex, sectionInput) in arguments.ingredientSections.enumerated() {
                    let section = IngredientSection(name: sectionInput.name, position: sectionIndex, recipe: recipe)
                    context.insert(section)
                    recipe.sections.append(section)

                    for (index, input) in sectionInput.ingredients.enumerated() {
                        if let ingredient = IngredientParser.fromString(input: input, location: .recipe) {
                            ingredient.position = index
                            ingredient.section = section
                            context.insert(ingredient)
                            section.ingredients.append(ingredient)
                        }
                    }
                }
                changes.append("ingredient sections")
            }
            if arguments.replaceInstructionSections {
                for old in recipe.instructionSections {
                    for step in old.steps { context.delete(step) }
                    context.delete(old)
                }
                recipe.instructionSections.removeAll()

                for (sectionIndex, sectionInput) in arguments.instructionSections.enumerated() {
                    let section = InstructionSection(name: sectionInput.name, position: sectionIndex, recipe: recipe)
                    context.insert(section)
                    recipe.instructionSections.append(section)

                    for (index, value) in sectionInput.steps.enumerated() {
                        let step = Step(value: value, position: index, section: section)
                        context.insert(step)
                        section.steps.append(step)
                    }
                }
                changes.append("instruction sections")
            }

            try? context.save()
            return changes
        }

        guard !changed.isEmpty else {
            return "Nothing was specified to update — no changes made."
        }
        return "Updated \(changed.joined(separator: ", ")) and saved the recipe."
    }
}
