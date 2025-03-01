//
//  MockData.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

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


