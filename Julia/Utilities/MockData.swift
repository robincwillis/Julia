//
//  MockData.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData
import Foundation

@MainActor
class MockData {

  static func setupPreviewData(in container: ModelContainer) {
    let context = container.mainContext

    createBasicIngredients(in: context)
    createSampleRecipe(in: context)
    createSectionedRecipe(in: context)
    createLocationIngredients(in: context)

    try? context.save()
  }

  private static func createBasicIngredients(in context: ModelContext) {
    let ingredients = [
      Ingredient(name: "Flour", location: .recipe, quantity: 2, unit: "cup"),
      Ingredient(name: "Sugar", location: .recipe, quantity: 1, unit: "cup"),
      Ingredient(name: "Eggs", location: .recipe, quantity: 2),
      Ingredient(name: "Milk", location: .recipe, quantity: 1, unit: "cup"),
      Ingredient(name: "Vanilla Extract", location: .recipe, quantity: 1, unit: "teaspoon")
    ]

    for ingredient in ingredients {
      context.insert(ingredient)
    }
  }

  private static func createSampleRecipe(in context: ModelContext) {
    let timing1 = Timing(type: "Prep", hours: 0, minutes: 15)
    let timing2 = Timing(type: "Cook", hours: 0, minutes: 30)
    let timing3 = Timing(type: "Total", hours: 0, minutes: 45)

    context.insert(timing1)
    context.insert(timing2)
    context.insert(timing3)

    let ingredient1 = Ingredient(name: "Flour", location: .recipe, quantity: 2, unit: "cup")
    let ingredient2 = Ingredient(name: "Sugar", location: .recipe, quantity: 1, unit: "cup")
    let ingredient3 = Ingredient(name: "Eggs", location: .recipe, quantity: 2)
    let ingredient4 = Ingredient(name: "Milk", location: .recipe, quantity: 1, unit: "cup")
    let ingredient5 = Ingredient(name: "Vanilla Extract", location: .recipe, quantity: 1, unit: "teaspoon")

    let recipe = Recipe(
      title: "Sample Recipe",
      summary: "A delicious sample recipe for pancakes that's perfect for breakfast. Light, fluffy, and easy to make.",
      ingredients: [ingredient1, ingredient2, ingredient3, ingredient4, ingredient5],
      instructions: [
        Step(value:"In a large bowl, whisk together the flour and sugar."),
        Step(value:"In another bowl, beat the eggs, then add milk and vanilla extract."),
        Step(value:"Pour the wet ingredients into the dry ingredients and stir until just combined."),
        Step(value:"Heat a lightly oiled griddle or frying pan over medium-high heat."),
        Step(value:"Pour or scoop the batter onto the griddle."),
        Step(value:"Cook until bubbles form and the edges are dry."),
        Step(value:"Flip and cook until browned on the other side.")
      ],
      rawText: [
        "PANCAKES",
        "2 cups flour",
        "1 cup sugar",
        "2 eggs",
        "1 cup milk",
        "1 teaspoon vanilla extract",
        "Mix dry ingredients. Mix wet ingredients. Combine them. Cook on griddle until done."
      ]
    )

    context.insert(recipe)

    recipe.timings = [timing1, timing2, timing3]
  }

  private static func createSectionedRecipe(in context: ModelContext) {
    let sectionedRecipe = Recipe(
      title: "Structured Recipe",
      summary: "A recipe with organized sections for better organization",
      instructions: [
        Step(value:"Prepare all ingredients according to the sections."),
        Step(value:"Start by preparing the sauce."),
        Step(value:"Cook the main ingredients."),
        Step(value:"Combine everything and simmer for 30 minutes."),
        Step(value:"Garnish before serving.")
      ]
    )

    context.insert(sectionedRecipe)

    let section1 = IngredientSection(name: "Main Ingredients", position: 0, recipe: sectionedRecipe)
    let section2 = IngredientSection(name: "Sauce", position: 1, recipe: sectionedRecipe)
    let section3 = IngredientSection(name: "Garnish", position: 2, recipe: sectionedRecipe)

    context.insert(section1)
    context.insert(section2)
    context.insert(section3)

    let section1Ingredients = [
      Ingredient(name: "Chicken", location: .recipe, quantity: 2, unit: "pounds", section: section1),
      Ingredient(name: "Olive Oil", location: .recipe, quantity: 2, unit: "tablespoons", section: section1),
      Ingredient(name: "Onion", location: .recipe, quantity: 1, unit: "large", section: section1)
    ]

    let section2Ingredients = [
      Ingredient(name: "Tomato Sauce", location: .recipe, quantity: 1, unit: "cup", section: section2),
      Ingredient(name: "Garlic", location: .recipe, quantity: 3, unit: "cloves", section: section2),
      Ingredient(name: "Basil", location: .recipe, quantity: 2, unit: "tablespoons", section: section2)
    ]

    let section3Ingredients = [
      Ingredient(name: "Parsley", location: .recipe, quantity: 0.25, unit: "cup", section: section3),
      Ingredient(name: "Parmesan", location: .recipe, quantity: 0.5, unit: "cup", section: section3)
    ]

    section1.ingredients = section1Ingredients
    section2.ingredients = section2Ingredients
    section3.ingredients = section3Ingredients

    sectionedRecipe.sections = [section1, section2, section3]

    let prepTime = Timing(type: "Prep", hours: 0, minutes: 20)
    let cookTime = Timing(type: "Cook", hours: 1, minutes: 0)

    context.insert(prepTime)
    context.insert(cookTime)

    sectionedRecipe.timings = [prepTime, cookTime]
  }

  private static func createLocationIngredients(in context: ModelContext) {
    let groceryItems = [
      Ingredient(name: "Eggs", location: .grocery, quantity: 1, unit: "dozen"),
      Ingredient(name: "Milk", location: .grocery, quantity: 1, unit: "gallon"),
      Ingredient(name: "Bread", location: .grocery, quantity: 1, unit: "loaf"),
      Ingredient(name: "Chicken Breast", location: .grocery, quantity: 2, unit: "pounds"),
      Ingredient(name: "Tomatoes", location: .grocery, quantity: 4)
    ]

    let pantryItems = [
      Ingredient(name: "Salt", location: .pantry, quantity: 1, unit: "box"),
      Ingredient(name: "Pepper", location: .pantry, quantity: 1, unit: "container"),
      Ingredient(name: "Olive Oil", location: .pantry, quantity: 1, unit: "bottle"),
      Ingredient(name: "Rice", location: .pantry, quantity: 5, unit: "pounds"),
      Ingredient(name: "Pasta", location: .pantry, quantity: 2, unit: "boxes")
    ]

    for ingredient in groceryItems + pantryItems {
      context.insert(ingredient)
    }
  }

  static func createSampleTimings() -> [Timing] {
    let timings = [
      Timing(type: "Prep", hours: 0, minutes: 15),
      Timing(type: "Cook", hours: 1, minutes: 30)
    ]
    return timings
  }

  static func createSampleIngredients() -> [Ingredient] {
    let ingredients: [Ingredient] = [
      Ingredient(name: "Flour", location: .recipe, quantity: 2.5, unit: "cup"),
      Ingredient(name: "Ginger soeaked in honey and tea", location: .recipe, quantity: 1, unit: "pinch", comment: "make sure soaks at least an hour"),
      Ingredient(name: "Sugar", location: .recipe, quantity: 1, unit: "pound", comment: "make sure it is a blend of brown and white sugar")
    ]

    return ingredients
  }

  static func createSampleIngredientSections() -> [IngredientSection] {
    let section1 = IngredientSection(name: "Main Ingredients", position: 0)
    let section2 = IngredientSection(name: "Sauce", position: 1)
    let section3 = IngredientSection(name: "Garnish", position: 2)

    let ingredients1 = [
      Ingredient(name: "Chicken", location: .recipe, quantity: 2, unit: "pounds"),
      Ingredient(name: "Olive Oil", location: .recipe, quantity: 2, unit: "tablespoons")
    ]

    let ingredients2 = [
      Ingredient(name: "Tomato Sauce", location: .recipe, quantity: 1, unit: "cup"),
      Ingredient(name: "Garlic", location: .recipe, quantity: 3, unit: "cloves")
    ]

    let ingredients3 = [
      Ingredient(name: "Parsley", location: .recipe, quantity: 0.25, unit: "cup")
    ]

    for (i, ingredient) in ingredients1.enumerated() {
      ingredient.position = i
    }

    for (i, ingredient) in ingredients2.enumerated() {
      ingredient.position = i
    }

    for (i, ingredient) in ingredients3.enumerated() {
      ingredient.position = i
    }

    section1.ingredients = ingredients1
    section2.ingredients = ingredients2
    section3.ingredients = ingredients3

    return [section1, section2, section3]
  }

  static func createSampleRecipe() -> Recipe {
    let recipe = Recipe(
      title: "Quick Sample Recipe",
      summary: "A simple recipe for preview purposes",
      ingredients: [],
      instructions: [
        Step(value:"Step 1: Sample instruction"),
        Step(value:"Step 2: Another instruction")
      ],
      rawText: [
        "PANCAKES",
        "2 cups flour",
        "1 cup sugar",
        "2 eggs",
        "1 cup milk",
        "1 teaspoon vanilla extract",
        "Mix dry ingredients. Mix wet ingredients. Combine them. Cook on griddle until done."
      ]
    )

    let ingredients = [
      Ingredient(name: "Ingredient 1", location: .recipe, quantity: 1, unit: "cup"),
      Ingredient(name: "Ingredient 2", location: .recipe, quantity: 2, unit: "tablespoons")
    ]

    recipe.ingredients = ingredients

    return recipe
  }

  static func createSampleSectionedRecipe() -> Recipe {
    let recipe = Recipe(
      title: "Sample Sectioned Recipe",
      summary: "A recipe with sections for preview purposes",
      instructions: [
        Step(value:"Follow the sections in order")
      ]
    )

    let section1 = IngredientSection(name: "First Section", position: 0, recipe: recipe)
    let section2 = IngredientSection(name: "Second Section", position: 1, recipe: recipe)

    let section1Ingredients = [
      Ingredient(name: "Section 1 Item 1", location: .recipe, quantity: 1, unit: "unit", section: section1),
      Ingredient(name: "Section 1 Item 2", location: .recipe, quantity: 2, unit: "units", section: section1)
    ]

    let section2Ingredients = [
      Ingredient(name: "Section 2 Item 1", location: .recipe, quantity: 3, unit: "units", section: section2),
      Ingredient(name: "Section 2 Item 2", location: .recipe, quantity: 4, unit: "units", section: section2)
    ]

    section1.ingredients = section1Ingredients
    section2.ingredients = section2Ingredients
    recipe.sections = [section1, section2]

    return recipe
  }
}

extension Recipe {
  @MainActor
  static func createSample() -> Recipe {
    return MockData.createSampleRecipe()
  }

  @MainActor
  static func createSampleWithSections() -> Recipe {
    return MockData.createSampleSectionedRecipe()
  }
}
