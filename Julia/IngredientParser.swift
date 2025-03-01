//
//  IngredientParser.swift
//  Julia
//
//  Created by Robin Willis on 11/11/24.
//

import Foundation

/// `IngredientParser` provides functionality to parse ingredient text input into
/// structured `Ingredient` objects and vice versa.
///
/// This class handles various input formats:
/// - Simple name: "Salt"
/// - Quantity and name: "2 Apples"
/// - Quantity, unit, and name: "1.5 cups Flour"
/// - Fractions: "1/2 cup Sugar"
///
/// It also converts ingredients back to readable strings.
class IngredientParser {
  
  /// Parses a fraction string (e.g., "1/2") or decimal string into a Double value.
  ///
  /// - Parameter input: A string representing a fraction (e.g., "1/2") or a decimal number.
  /// - Returns: The numeric value as a Double if parsable, nil otherwise.
  static private func parseFraction(_ input: String) -> Double? {
    let components = input.split(separator: "/").map { Double($0) }
    
    // If input is a fraction (e.g., "1/2"), calculate the division
    if components.count == 2, let numerator = components[0], let denominator = components[1], denominator != 0 {
      return numerator / denominator
    }
    
    // Otherwise try to parse as a regular decimal number
    return Double(input)
  }
  
  /// Creates an Ingredient object from a text input string and location.
  ///
  /// Parses the input string in various formats:
  /// - Single word: Treated as the ingredient name
  /// - Two words: First as quantity, second as name
  /// - Three words: First as quantity, second as unit, third as name
  /// - More words: First as quantity, second as unit (if valid), rest as name
  ///
  /// - Parameters:
  ///   - input: The text string to parse (e.g., "2 cups flour")
  ///   - location: The IngredientLocation where this ingredient belongs
  /// - Returns: A new Ingredient object if parsing succeeds, nil otherwise
  static func fromString(input: String, location: IngredientLocation) -> Ingredient? {
    // Split the input by spaces
    let components = input.split(separator: " ").map { String($0) }
    
    // Handle based on the number of components
    switch components.count {
    case 1:
      // Case: Single word - "Salt"
      return Ingredient(name: components[0], location: location)
      
    case 2:
      // Case: Two words - "2 Apples"
      if let quantity = parseFraction(components[0]) {
        return Ingredient(name: components[1], location: location, quantity: quantity)
      } else {
        // Couldn't parse quantity, treat entire input as name
        return Ingredient(name: input, location: location)
      }
      
    case 3:
      // Case: Three words - "1/2 cup Sugar"
      if let quantity = parseFraction(components[0]) {
        if MeasurementUnit(from: String(components[1]).lowercased()) != nil {
          // Format: quantity + unit + name
          return Ingredient(name: components[2], 
                           location: location, 
                           quantity: quantity, 
                           unit: String(components[1]).lowercased())
        } else {
          // Second word not recognized as unit, treat components[1] and [2] as name
          let ingredientName = components.dropFirst(1).joined(separator: " ")
          return Ingredient(name: ingredientName, location: location, quantity: quantity)
        }
      } else {
        // Couldn't parse quantity, treat entire input as name
        return Ingredient(name: input, location: location)
      }
      
    default:
      // Case: Four or more words - "1 cup all purpose flour"
      if let quantity = parseFraction(components[0]) {
        if MeasurementUnit(from: String(components[1]).lowercased()) != nil {
          // Format: quantity + unit + multi-word name
          let ingredientName = components.dropFirst(2).joined(separator: " ")
          return Ingredient(name: ingredientName, 
                           location: location, 
                           quantity: quantity, 
                           unit: String(components[1]).lowercased())
        } else {
          // Format: quantity + multi-word name
          let ingredientName = components.dropFirst(1).joined(separator: " ")
          return Ingredient(name: ingredientName, location: location, quantity: quantity)
        }
      } else {
        // Couldn't parse quantity, treat entire input as name
        return Ingredient(name: input, location: location)
      }
    }
  }
  
  /// Converts an Ingredient object to a human-readable string.
  ///
  /// The resulting string follows these formats:
  /// - "Salt" (name only)
  /// - "2 Apples" (quantity and name)
  /// - "1.5 cups Flour" (quantity, unit, and name)
  ///
  /// - Parameter ingredient: The Ingredient object to convert
  /// - Returns: A formatted string representation of the ingredient, or empty string if nil
  static func toString(for ingredient: Ingredient?) -> String {
    guard let ingredient = ingredient else {
      return ""
    }
    var ingredientString = ""
    
    // Add quantity if available
    if let quantity = ingredient.quantity {
      ingredientString += "\(quantity)"
      
      // Add unit if available
      if let unit = ingredient.unit {
        ingredientString += " \(unit.rawValue)"
      }
    }
    
    // Add name, with space if needed
    if !ingredientString.isEmpty {
      ingredientString += " \(ingredient.name)"
    } else {
      ingredientString = ingredient.name
    }
    
    return ingredientString
  }
}
