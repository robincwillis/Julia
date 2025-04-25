//
//  MeasurementUnit.swift
//  Julia
//
//  Created by Robin Willis on 11/12/24.
//

import SwiftUI

// Fluid ounce (fl oz)
// Pint (pt)
// Quart (qt)
// Gallon (gal)

// Income ...
// Clove
// Sprig
// 

enum MeasurementUnit: String, CaseIterable, Codable {
  case item, teaspoon, tablespoon, cup,
       ounce, pound, gram, kilogram,
       pint, quart, gallon, liter,
       can, bunch, piece, pinch,
       clove, jar, bottle, container
  
  init?(from string: String?) {
    switch string?.lowercased() {
      
    case "itm", "item", "items":
      self = .item
    case "tsp", "teaspoon", "teaspoons" :
      self = .teaspoon
    case "tbs", "tbsp", "tablespoon", "tablespoons":
      self = .tablespoon
    case "c", "cup", "cups":
      self = .cup

    case "oz", "ounce", "ounces":
      self = .ounce
    case "lb", "pound", "pounds", "lbs":
      self = .pound
    case "g", "gram", "grams":
      self = .gram
    case "kg", "kilogram", "kilograms":
      self = .kilogram

    case "pt", "pint", "pints":
      self = .pint
    case "qt", "quart", "quarts":
      self = .liter
    case "gal", "gallon", "gallons":
      self = .gallon
    case "l", "liter", "liters":
      self = .liter

    case "clv", "clove", "cloves":
      self = .clove
    case  "bn", "bunch", "bunches":
      self = .bunch
    case "pc", "piece", "pieces":
      self = .piece
    case "pn", "pinch", "pinches":
      self = .pinch

    case "cn", "can", "cans":
      self = .can
    case "jar", "jars":
      self = .jar
    case "btl", "bottle", "bottles":
      self = .bottle
    case "ctr", "cont", "container", "containers":
      self = .container
      
      
    // Head
      
    default:
      return nil
    }
  }
  
  var displayName: String {
    switch self {
    case .item: return "item"
    case .teaspoon: return "teaspoon"
    case .tablespoon: return "tablespoon"
    case .cup: return "cup"

    case .ounce: return "ounce"
    case .pound: return "pound"
    case .gram: return "gram"
    case .kilogram: return "kilogram"

    case .pint: return "pint"
    case .quart: return "quart"
    case .liter: return "liter"
    case .gallon: return "gallon"
      
    case .clove: return "clove"
    case .bunch: return "bunch"
    case .piece: return "piece"
    case .pinch: return "pinch"

    case .can: return "can"
    case .jar: return "jar"
    case .bottle: return "bottle"
    case .container: return "container"
    }
  }
  
  var pluralName: String {
    switch self {
    case .item: return "items"
    case .teaspoon: return "teaspoons"
    case .tablespoon: return "tablespoons"
    case .cup: return "cups"
      
    case .ounce: return "ounces"
    case .pound: return "pounds"
    case .gram: return "grams"
    case .kilogram: return "kilograms"
      
    case .pint: return "pints"
    case .quart: return "quarts"
    case .liter: return "liters"
    case .gallon: return "gallons"
      

    case .clove: return "cloves"
    case .bunch: return "bunches"
    case .piece: return "pieces"
    case .pinch: return "pinches"
    
    case .can: return "cans"
    case .jar: return "jars"
    case .bottle: return "bottles"
    case .container: return "containers"
    }
  }
  
  var shortHand: String {
    switch self {
    case .item: return "itm"
    case .teaspoon: return "tsp"
    case .tablespoon: return "tbsp"
    case .cup: return "c"

    case .ounce: return "oz"
    case .pound: return "lb"
    case .gram: return "g"
    case .kilogram: return "kg"

    case .pint: return "pt"
    case .quart: return "qt"
    case .liter: return "lt"
    case .gallon: return "gal"
      
    case .clove: return "clv"
    case .bunch: return "bn"
    case .piece: return "pc"
    case .pinch: return "pn"
      
    case .can: return "cn"
    case .jar: return "jar"
    case .bottle: return "btl"
    case .container: return "ctr"
    }
  }
}
