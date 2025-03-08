//
//  Ingredient.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//



import Foundation
import SwiftData

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
  
  var destination: IngredientLocation {
    switch self {
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

@Model
final class Ingredient: Identifiable, Hashable, Equatable, CustomStringConvertible {
    @Attribute(.unique) var id: String = UUID().uuidString
    var createdDate: Date
    var name: String
    var location: IngredientLocation
    var quantity: Double?
    var unit: MeasurementUnit?
    var comment: String?
    @Relationship(originalName: "ingredients") var recipe: Recipe?
    @Relationship(originalName: "ingredients") var section: IngredientSection?
  
    private var imageName: String?
  init(
    id: String = UUID().uuidString,
    name: String,
    location: IngredientLocation,
    quantity: Double? = nil,
    unit: String? = nil,
    comment: String? = nil,
    imageName: String? = nil,
    recipe: Recipe? = nil,
    section: IngredientSection? = nil
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
        self.section = section
    }
  
  var description: String {
    return "Ingredient(id: \(id), name: \(name), quantity: \(String(describing: quantity)), unit: \(String(describing: unit)), location: \(location.rawValue))"
  }
}

extension Ingredient {
  func moveTo(_ newLocation: IngredientLocation) {
    self.location = newLocation
  }
}
