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
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Cound't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        
        
        return try decoder.decode(T.self, from: data)
        // return container.value
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}


//struct DecodableContainer<T: Decodable>: Decodable {
//  let value: T
//  
//  init(from decoder: Decoder) {
//    let container = try! decoder.singleValueContainer()
//    //decoder.
//    value = try T(from: decoder.with(IngredientLocation.self, using: IngredientLocationCodingStrategy.self, decoder: decoder))
//
//  }
//}
//
//struct IngredientLocationCodingStrategy: TypedCodingValueProvider {
//  static func provide(for type: IngredientLocation.Type, decoder: Decoder) throws -> IngredientLocation {
//    let container = try decoder.singleValueContainer()
//    let locationString = try container.decode(String.self)
//    guard let location = IngredientLocation(rawValue: locationString) else {
//      throw DecodingError.dataCorrupted(DecodingError.Context(
//        codingPath: decoder.codingPath,
//        debugDescription: "Invalid IngredientLocation value: \(locationString)"
//      ))
//    }
//    return location
//  }
//}
