//
//  MockData.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import Foundation

struct MockIngredient: Decodable {
    let id: UUID
    let name: String
    let quantity: Double?
    let measurement: String?
    let comment: String?
}

struct MockRecipe: Decodable {
    let id: UUID
    let title: String
    let content: String?
    let ingredients: [MockIngredient]
    let steps: [String]
}

var mockIngredients: [MockIngredient] = load("ingredientData.json")
// var mockGroceries: [Ingredient] = load("groceryData.json")
var mockRecipes: [MockRecipe] = load("recipeData.json")

func load<T: Decodable>(_ filename: String) -> T {
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
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
