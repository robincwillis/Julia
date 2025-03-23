//
//  MockData.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData
import Foundation

enum MockIngredientLocation: String, Codable {
  case recipe
  case grocery
  case pantry
  case unknown
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = try MockIngredientLocation(rawValue: container.decode(String.self)) ?? .unknown
  }
}

struct MockIngredient: Decodable {
    let id: UUID
    let name: String
    let quantity: Double?
    let measurement: String?
    let comment: String?
    let location: IngredientLocation
}

struct MockRecipe: Decodable {
    let id: UUID
    let title: String
    let content: String?
    let rawText: [String]
    let ingredients: [MockIngredient]
    let steps: [String]
}

private enum CodingKeys: String, CodingKey {
  case recipe
  case pantry
  case grocery
}


var mockIngredients: [MockIngredient] = load("ingredientData.json", for: [MockIngredient].self)
var mockRecipes: [MockRecipe] = load("recipeData.json", for: [MockRecipe].self)

func load<T: Decodable>(_ filename: String, for type: T.Type) -> T {
    // Attempt to load mock data, with empty fallback if something fails
    do {
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
            print("Error: File \(filename) not found in bundle")
            return createEmptyMock(for: type)
        }
        
        let data = try Data(contentsOf: file)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        print("Error loading \(filename): \(error.localizedDescription)")
        return createEmptyMock(for: type)
    }
}

private func createEmptyMock<T: Decodable>(for type: T.Type) -> T {
    // Create empty mock objects when file loading fails
    if type == [MockIngredient].self {
        return [] as! T
    } else if type == [MockRecipe].self {
        return [] as! T
    } else {
        // Last resort for other types (should not happen)
        print("Critical: Unexpected mock type requested")
        return try! JSONDecoder().decode(T.self, from: "[]".data(using: .utf8)!)
    }
}

/// Manages sample data creation for previews and testing
@MainActor
class MockData {
  // MARK: - Sample Data Methods
  
  /// Sets up sample data in the provided container
  static func setupPreviewData(in container: ModelContainer) {
    let context = container.mainContext
    
    // Basic ingredients
    createBasicIngredients(in: context)
    
    // Create a basic recipe
    createSampleRecipe(in: context)
    
    // Create a recipe with sections
    createSectionedRecipe(in: context)
    
    // Create ingredients in other locations (grocery, pantry)
    createLocationIngredients(in: context)
    
    try? context.save()
  }
  
  // MARK: - Sample Data Creation
  
  /// Creates basic ingredients
  private static func createBasicIngredients(in context: ModelContext) {
    // Sample ingredients
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
  
  /// Creates a basic sample recipe
  private static func createSampleRecipe(in context: ModelContext) {
    // Sample timings
    let timing1 = Timing(type: "Prep", hours: 0, minutes: 15)
    let timing2 = Timing(type: "Cook", hours: 0, minutes: 30)
    let timing3 = Timing(type: "Total", hours: 0, minutes: 45)
    
    context.insert(timing1)
    context.insert(timing2)
    context.insert(timing3)
    
    // Sample ingredients specifically for the recipe
    let ingredient1 = Ingredient(name: "Flour", location: .recipe, quantity: 2, unit: "cup")
    let ingredient2 = Ingredient(name: "Sugar", location: .recipe, quantity: 1, unit: "cup")
    let ingredient3 = Ingredient(name: "Eggs", location: .recipe, quantity: 2)
    let ingredient4 = Ingredient(name: "Milk", location: .recipe, quantity: 1, unit: "cup")
    let ingredient5 = Ingredient(name: "Vanilla Extract", location: .recipe, quantity: 1, unit: "teaspoon")
    
    // Create basic recipe
    let recipe = Recipe(
      title: "Sample Recipe",
      summary: "A delicious sample recipe for pancakes that's perfect for breakfast. Light, fluffy, and easy to make.",
      ingredients: [ingredient1, ingredient2, ingredient3, ingredient4, ingredient5],
      instructions: [
        "In a large bowl, whisk together the flour and sugar.",
        "In another bowl, beat the eggs, then add milk and vanilla extract.",
        "Pour the wet ingredients into the dry ingredients and stir until just combined.",
        "Heat a lightly oiled griddle or frying pan over medium-high heat.",
        "Pour or scoop the batter onto the griddle.",
        "Cook until bubbles form and the edges are dry.",
        "Flip and cook until browned on the other side."
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
    
    // Add timings to recipe
    recipe.timings = [timing1, timing2, timing3]
  }
  
  /// Creates a recipe with ingredient sections
  private static func createSectionedRecipe(in context: ModelContext) {
    // Create the recipe first
    let sectionedRecipe = Recipe(
      title: "Structured Recipe",
      summary: "A recipe with organized sections for better organization",
      instructions: [
        "Prepare all ingredients according to the sections.",
        "Start by preparing the sauce.",
        "Cook the main ingredients.",
        "Combine everything and simmer for 30 minutes.",
        "Garnish before serving."
      ]
    )
    
    context.insert(sectionedRecipe)
    
    // Create sections
    let section1 = IngredientSection(name: "Main Ingredients", position: 0, recipe: sectionedRecipe)
    let section2 = IngredientSection(name: "Sauce", position: 1, recipe: sectionedRecipe)
    let section3 = IngredientSection(name: "Garnish", position: 2, recipe: sectionedRecipe)
    
    context.insert(section1)
    context.insert(section2)
    context.insert(section3)
    
    // Section 1 ingredients
    let section1Ingredients = [
      Ingredient(name: "Chicken", location: .recipe, quantity: 2, unit: "pounds", section: section1),
      Ingredient(name: "Olive Oil", location: .recipe, quantity: 2, unit: "tablespoons", section: section1),
      Ingredient(name: "Onion", location: .recipe, quantity: 1, unit: "large", section: section1)
    ]
    
    // Section 2 ingredients
    let section2Ingredients = [
      Ingredient(name: "Tomato Sauce", location: .recipe, quantity: 1, unit: "cup", section: section2),
      Ingredient(name: "Garlic", location: .recipe, quantity: 3, unit: "cloves", section: section2),
      Ingredient(name: "Basil", location: .recipe, quantity: 2, unit: "tablespoons", section: section2)
    ]
    
    // Section 3 ingredients
    let section3Ingredients = [
      Ingredient(name: "Parsley", location: .recipe, quantity: 0.25, unit: "cup", section: section3),
      Ingredient(name: "Parmesan", location: .recipe, quantity: 0.5, unit: "cup", section: section3)
    ]
    
    // Add all ingredients to sections
    section1.ingredients = section1Ingredients
    section2.ingredients = section2Ingredients
    section3.ingredients = section3Ingredients
    
    // Update recipe with sections
    sectionedRecipe.sections = [section1, section2, section3]
    
    // Add timings
    let prepTime = Timing(type: "Prep", hours: 0, minutes: 20)
    let cookTime = Timing(type: "Cook", hours: 1, minutes: 0)
    
    context.insert(prepTime)
    context.insert(cookTime)
    
    sectionedRecipe.timings = [prepTime, cookTime]
  }
  
  /// Creates ingredients in various locations (grocery, pantry)
  private static func createLocationIngredients(in context: ModelContext) {
    // Grocery items
    let groceryItems = [
      Ingredient(name: "Eggs", location: .grocery, quantity: 1, unit: "dozen"),
      Ingredient(name: "Milk", location: .grocery, quantity: 1, unit: "gallon"),
      Ingredient(name: "Bread", location: .grocery, quantity: 1, unit: "loaf"),
      Ingredient(name: "Chicken Breast", location: .grocery, quantity: 2, unit: "pounds"),
      Ingredient(name: "Tomatoes", location: .grocery, quantity: 4)
    ]
    
    // Pantry items
    let pantryItems = [
      Ingredient(name: "Salt", location: .pantry, quantity: 1, unit: "box"),
      Ingredient(name: "Pepper", location: .pantry, quantity: 1, unit: "container"),
      Ingredient(name: "Olive Oil", location: .pantry, quantity: 1, unit: "bottle"),
      Ingredient(name: "Rice", location: .pantry, quantity: 5, unit: "pounds"),
      Ingredient(name: "Pasta", location: .pantry, quantity: 2, unit: "boxes")
    ]
    
    // Insert all ingredients
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
      Ingredient(name: "Flour", location: .recipe, quantity: 2, unit: "cup"),
      Ingredient(name: "Sugar", location: .recipe, quantity: 1, unit: "cup")
    ]
    
    return ingredients
  }
  
  static func createSampleIngredientSections() -> [IngredientSection] {
    // Create sections with minimal relationships
    let section1 = IngredientSection(name: "Main Ingredients", position: 0)
    let section2 = IngredientSection(name: "Sauce", position: 1)
    let section3 = IngredientSection(name: "Garnish", position: 2)
    
    // Create basic ingredients for preview (without circular references)
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
    
    // Set positions for all ingredients
    for (i, ingredient) in ingredients1.enumerated() {
      ingredient.position = i
    }
    
    for (i, ingredient) in ingredients2.enumerated() {
      ingredient.position = i
    }
    
    for (i, ingredient) in ingredients3.enumerated() {
      ingredient.position = i
    }
    
    // Assign ingredients to sections without creating circular references
    section1.ingredients = ingredients1
    section2.ingredients = ingredients2
    section3.ingredients = ingredients3
    
    return [section1, section2, section3]
  }
  
  /// Creates a sample recipe for previews or tests
  static func createSampleRecipe() -> Recipe {
    let recipe = Recipe(
      title: "Quick Sample Recipe",
      summary: "A simple recipe for preview purposes",
      ingredients: [],
      instructions: ["Step 1: Sample instruction", "Step 2: Another instruction"],
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
    
    // Add some basic ingredients
    let ingredients = [
      Ingredient(name: "Ingredient 1", location: .recipe, quantity: 1, unit: "cup"),
      Ingredient(name: "Ingredient 2", location: .recipe, quantity: 2, unit: "tablespoons")
    ]
    
    recipe.ingredients = ingredients
    
    return recipe
  }
  
  /// Creates a sample sectioned recipe for previews or tests
  static func createSampleSectionedRecipe() -> Recipe {
    let recipe = Recipe(
      title: "Sample Sectioned Recipe",
      summary: "A recipe with sections for preview purposes",
      instructions: ["Follow the sections in order"]
    )
    
    // Create sections
    let section1 = IngredientSection(name: "First Section", position: 0, recipe: recipe)
    let section2 = IngredientSection(name: "Second Section", position: 1, recipe: recipe)
    
    // Create section ingredients
    let section1Ingredients = [
      Ingredient(name: "Section 1 Item 1", location: .recipe, quantity: 1, unit: "unit", section: section1),
      Ingredient(name: "Section 1 Item 2", location: .recipe, quantity: 2, unit: "units", section: section1)
    ]
    
    let section2Ingredients = [
      Ingredient(name: "Section 2 Item 1", location: .recipe, quantity: 3, unit: "units", section: section2),
      Ingredient(name: "Section 2 Item 2", location: .recipe, quantity: 4, unit: "units", section: section2)
    ]
    
    // Set up relationships
    section1.ingredients = section1Ingredients
    section2.ingredients = section2Ingredients
    recipe.sections = [section1, section2]
    
    return recipe
  }
}

// MARK: - Recipe Extension for Sample Creation

extension Recipe {
  /// Creates a standard sample recipe
  @MainActor
  static func createSample() -> Recipe {
    return MockData.createSampleRecipe()
  }
  
  /// Creates a sample recipe with sections
  @MainActor
  static func createSampleWithSections() -> Recipe {
    return MockData.createSampleSectionedRecipe()
  }
}
