//
//  IngredientParser.swift
//  Julia
//
//  Created by Robin Willis on 11/11/24.
//

import Foundation


class IngredientParser {
  
  static private func parseFraction(_ input: String) -> Double? {
    let components = input.split(separator: "/").map { Double($0) }
    
    // Ensure we have exactly two components and both are valid Doubles
    if components.count == 2, let numerator = components[0], let denominator = components[1], denominator != 0 {
      return numerator / denominator
    }
    
    return Double(input) // Return value if parsing fails
  }
  
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
      if let quantity = parseFraction(components[0]) {
        return Ingredient(name: components[1],  location: location, quantity: quantity)
      } else {
        return Ingredient(name: input, location: location)  // Invalid measurement
      }
      
    case 3:
      if let quantity = parseFraction(components[0]) {
        if let unit = MeasurementUnit(from:  String(components[1]).lowercased()) {
          // quantit + unit + name
          return Ingredient(name: components[2], location: location, quantity: quantity, unit: String(components[1]).lowercased())
        } else {
          // quantity + name
          let ingredientName = components.dropFirst(1).joined(separator: " ")
          return Ingredient(name: ingredientName, location: location, quantity: quantity)
          
        }
      } else {
        // just name
        return Ingredient(name: input, location: location)  // Invalid measurement
        
      }
      
    default:
      if let quantity = parseFraction(components[0]) {
        if let unit = MeasurementUnit(from:  String(components[1]).lowercased()) {
          // quantit + unit + name
          let ingredientName = components.dropFirst(2).joined(separator: " ")
          return Ingredient(name: ingredientName, location: location, quantity: quantity, unit: String(components[1]).lowercased())
        } else {
          // quantity + name
          let ingredientName = components.dropFirst(1).joined(separator: " ")
          return Ingredient(name: ingredientName, location: location, quantity: quantity)
          
        }
      } else {
        return Ingredient(name: input, location: location)  // Invalid format (too many components)
      }
      
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
