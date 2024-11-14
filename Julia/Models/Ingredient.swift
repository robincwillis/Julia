//
//  Ingredient.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

// Say I have an app with two models, recipe and ingredients. I have two views, groceries and pantry, I want to track which ingredients (with quantity and measurement) I have for recipes in pantry, and what I need in groceries, and be able to move them between views after I go shopping or start a new recipe. What is the best way to model ingredient?
                                                                                                                                                                                  


import Foundation
import SwiftData

enum MeasurementFraction: Double, CaseIterable, CustomStringConvertible {
  case oneQuarter = 0.25
  case oneThird = 0.3333
  case oneHalf = 0.5
  case twoThirds = 0.6666
  case threeQuarters = 0.75
  
  var description: String {
    switch self {
    case .oneQuarter:
      return "¼"
    case .oneThird:
      return "⅓"
    case .oneHalf:
      return "½"
    case .twoThirds:
      return "⅔"
    case .threeQuarters:
      return "¾"
    }
  }
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
  var title: String{
    switch self {
    case .grocery:
      return "Groceries"
    case .pantry:
      return "Pantry"
    case .recipe:
      return "Recipes"
    case .unknown:
      return "Unknown"
      
    }
  }
}

@Model
final class Ingredient: Identifiable, Hashable, Equatable, CustomStringConvertible {
    @Attribute(.unique) var id: String = UUID().uuidString
    var createdDate: Date
    var name: String
    var location: IngredientLocation
    var quantity: Double?
    var unit: MeasurementUnit?
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
        self.unit = MeasurementUnit(from: unit)
        self.comment = comment
        self.imageName = imageName
        self.recipe = recipe
    }
  
  var description: String {
    return "Ingredient(id: \(id), name: \(name), quantity: \(String(describing: quantity)), unit: \(String(describing: unit)), location: \(location.rawValue))"
  }
}

extension Ingredient {
  func moveTo(_ newLocation: IngredientLocation) {
    self.location = newLocation
  }
  
  func destination() -> IngredientLocation {
    switch self.location {
    case .pantry:
      return .grocery
    case .grocery:
      return .pantry
    case .recipe:
      return .grocery
    case .unknown:
      return .recipe
    }
  }
}
