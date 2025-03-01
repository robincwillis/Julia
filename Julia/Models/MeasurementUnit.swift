//
//  MeasurementUnit.swift
//  Julia
//
//  Created by Robin Willis on 11/12/24.
//

import SwiftUI


enum MeasurementUnit: String, CaseIterable, Codable {
  
  case pound, ounce, liter, cup, tablespoon, teaspoon, piece, pinch, gram, kilogram
  
  init?(from string: String?) {
    switch string?.lowercased() {
    case "lb", "pound", "pounds", "lbs":
      self = .pound
    case "oz", "ounce", "ounces":
      self = .ounce
    case "l", "liter", "liters":
      self = .liter
    case "c", "cup", "cups":
      self = .cup
    case "tbs", "tbsp", "tablespoon", "tablespoons":
      self = .tablespoon
    case "tsp", "teaspoon", "teaspoons" :
      self = .teaspoon
    case "p", "piece", "pieces":
      self = .piece
    case "pinch", "pinches":
      self = .pinch
    case "g", "gram", "grams":
      self = .gram
    case "kg", "kilogram", "kilograms":
      self = .kilogram
      
    default:
      return nil
    }
  }
  
  var displayName: String {
    switch self {
    case .pound: return "pound"
    case .ounce: return "ounce"
    case .liter: return "liter"
    case .cup: return "cup"
    case .tablespoon: return "tablespoon"
    case .teaspoon: return "teaspoon"
    case .piece: return "piece"
    case .pinch:  return "pinch"
    case .gram: return "gram"
    case .kilogram: return "kilogram"
    }
  }
  
  var shortHand: String {
    switch self {
    case .pound: return "lb"
    case .ounce: return "oz"
    case .liter: return "l"
    case .cup: return "c"
    case .tablespoon: return "tbsp"
    case .teaspoon: return "tsp"
    case .piece: return "pc"
    case .pinch:  return "pn"
    case .gram: return "g"
    case .kilogram: return "kg"
    }
  }

  
}
