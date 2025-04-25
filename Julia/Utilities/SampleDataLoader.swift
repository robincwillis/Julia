//
//  SampleDataLoader.swift
//  Julia
//
//  Created by Robin Willis on 4/20/25.
//


// SampleDataLoader.swift

import SwiftUI
import SwiftData

class SampleDataLoader {
  
  enum SampleDataType {
    case recipes
    case pantryIngredients
    case groceryIngredients
    case all
  }
  
  static func loadSampleData(type: SampleDataType, context: ModelContext) async throws -> Int {
    var count = 0
    
    switch type {
    case .recipes:
      count = try await loadSampleRecipes(context: context)
    case .pantryIngredients:
      count = try await loadSampleIngredients(location: .pantry, context: context)
    case .groceryIngredients:
      count = try await loadSampleIngredients(location: .grocery, context: context)
    case .all:
      let recipeCount = try await loadSampleRecipes(context: context)
      let pantryCount = try await loadSampleIngredients(location: .pantry, context: context)
      let groceryCount = try await loadSampleIngredients(location: .grocery, context: context)
      count = recipeCount + pantryCount + groceryCount
    }
    
    return count
  }
  
  private static func loadSampleRecipes(context: ModelContext) async throws -> Int {
    // Load recipes JSON
    guard let url = Bundle.main.url(forResource: "recipeData", withExtension: "json") else {
      throw NSError(domain: "SampleData", code: 1, userInfo: [NSLocalizedDescriptionKey: "Recipes JSON not found"])
    }
    print(url)
    return try await ImportExportManager.importRecipesFile(from: url, context: context)
  }
  
  private static func loadSampleIngredients(location: IngredientLocation, context: ModelContext) async throws -> Int {
    // Load ingredients JSON
    guard let url = Bundle.main.url(forResource: "ingredientData", withExtension: "json") else {
      throw NSError(domain: "SampleData", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ingredient JSON not found"])
    }
    
    // Load all ingredients and then filter by location
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    let allIngredients = try decoder.decode([ImportExportManager.IngredientExport].self, from: data)
    
    // Filter by location
    let filteredIngredients = allIngredients.filter { $0.location == location.rawValue }
    
    // Import each ingredient
    for importedIngredient in filteredIngredients {
      let ingredient = ImportExportManager.createIngredient(from: importedIngredient)
      context.insert(ingredient)
    }
    
    try context.save()
    return filteredIngredients.count
  }
}
