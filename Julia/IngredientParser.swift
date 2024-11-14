//
//  IngredientParser.swift
//  Julia
//
//  Created by Robin Willis on 11/11/24.
//

import Foundation


class IngredientParser {
  
  static func fromString(input: String, location: IngredientLocation) -> Ingredient? {
    // Split the input by spaces
    let components = input.split(separator: " ").map { String($0) }
    
    // Handle based on the number of components
    switch components.count {
    case 1:
      // Only the name
      return Ingredient(name: components[0], location: location)
      
    case 2:
      // First component: measurement, second: name
      if let quantity = Double(components[0]) {
        return Ingredient(name: components[1],  location: location, quantity: quantity)
      } else {
        return Ingredient(name: input, location: location)  // Invalid measurement
      }
      
    case 3:
      let quantity = Double(components[0])
      // let unit = String(components[1])
      let unit = MeasurementUnit(rawValue: components[1].lowercased())
      
      // First component: measurement, second: unit, third: name
      if quantity != nil, unit != nil {
        return Ingredient(name: components[2], location: location, quantity: quantity, unit: unit?.rawValue)
      } else {
        return Ingredient(name: input, location: location)  // Invalid format (either measurement or unit)
      }
      
    default:
      return Ingredient(name: input, location: location)  // Invalid format (too many components)
    }
  }
  
  static func toString(for ingredient: Ingredient?) -> String {
    guard let ingredient = ingredient else {
      return ""
    }
    var ingredientString = ""
    
    if let quantity = ingredient.quantity {
      ingredientString += "\(quantity)"
      
      if let unit = ingredient.unit {
        ingredientString += " \(unit.rawValue)"
      }
    }
    
    if !ingredientString.isEmpty {
      ingredientString += " \(ingredient.name)"
    } else {
      ingredientString = ingredient.name
    }
    
    return ingredientString
  }
}
