//
//  Ingredient.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

// Say I have an app with two models, recipe and ingredients. I have two views, groceries and pantry, I want to track which ingredients (with quantity and measurement) I have for recipes in pantry, and what I need in groceries, and be able to move them between views after I go shopping or start a new recipe. What is the best way to model ingredient?
                                                                                                                                                                                  


import Foundation
import SwiftData

enum MeasurementUnit: String, Codable {
  case pound
  case pounds
  case lb
  case lbs
  
  case gram
  case grams

  case ounce
  case ounces
  case oz
  
  case liter
  case liters
  
  case cup
  case cups

  case tablesooon
  case tablespoons
  case tbsp
  case tbsps
  
  case teaspoon
  case teaspoons
  case tsp
  case tsps

  case piece
  case pieces
  
}

enum IngredientLocation: String, Codable {
  case pantry
  case grocery
  case recipe
  case unknown
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = try IngredientLocation(rawValue: container.decode(String.self)) ?? .unknown
  }
}

@Model
final class Ingredient: Identifiable, Hashable, Equatable {

    
    @Attribute(.unique) var id: String = UUID().uuidString
    var createdDate: Date
    var name: String
    var location: IngredientLocation
    var quantity: Double?
    var unit: String?
    var comment: String?
    var recipe: Recipe?
  
    private var imageName: String?
    //  var image: Image? {
    //        Image(imageName)
    //  }
  init(
    id: String = UUID().uuidString,
    name: String,
    location: IngredientLocation,
    quantity: Double? = nil,
    unit: String? = nil,
    comment: String? = nil,
    imageName: String? = nil,
    recipe: Recipe? = nil
  ) {
        self.id = id
        self.createdDate = Date()
        self.name = name
        self.location = location
        self.quantity = quantity
        self.unit = unit
        self.comment = comment
        self.imageName = imageName
        self.recipe = recipe
    }
  
}

extension Ingredient {
  func moveTo(_ newLocation: IngredientLocation) {
    self.location = newLocation
  }
}
