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
       pint, quart, gallon, liter, milliliter,
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
      self = .quart
    case "gal", "gallon", "gallons":
      self = .gallon
    case "l", "liter", "liters":
      self = .liter
    case "ml", "milliliter", "milliliters":
      self = .milliliter

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
    case .milliliter: return "milliliter"
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
    case .milliliter: return "milliliters"
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
    case .milliliter: return "ml"
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

enum UnitSystem: String, CaseIterable {
  case imperial, metric
}

extension MeasurementUnit {
  /// The measurement system this unit belongs to. `nil` for count-based
  /// units (item, piece, clove, etc.) that have no metric/imperial
  /// equivalent and so aren't affected by a unit system conversion.
  var unitSystem: UnitSystem? {
    switch self {
    case .teaspoon, .tablespoon, .cup, .pint, .quart, .gallon, .ounce, .pound:
      return .imperial
    case .milliliter, .liter, .gram, .kilogram:
      return .metric
    case .item, .can, .bunch, .piece, .pinch, .clove, .jar, .bottle, .container:
      return nil
    }
  }

  /// Base-unit conversion factor: milliliters for volume units, grams for
  /// weight units. `nil` for count-based units.
  private var baseUnitsPerUnit: Double? {
    switch self {
    // Volume, in milliliters
    case .teaspoon: return 4.92892
    case .tablespoon: return 14.7868
    case .cup: return 236.588
    case .pint: return 473.176
    case .quart: return 946.353
    case .gallon: return 3785.41
    case .milliliter: return 1
    case .liter: return 1000
    // Weight, in grams
    case .ounce: return 28.3495
    case .pound: return 453.592
    case .gram: return 1
    case .kilogram: return 1000
    case .item, .can, .bunch, .piece, .pinch, .clove, .jar, .bottle, .container:
      return nil
    }
  }

  private var isVolume: Bool {
    switch self {
    case .teaspoon, .tablespoon, .cup, .pint, .quart, .gallon, .milliliter, .liter:
      return true
    default:
      return false
    }
  }

  /// Converts a quantity in this unit to the "nicest" (largest whole-ish)
  /// unit in the target system. Returns `nil` for count-based units, which
  /// have no metric/imperial equivalent. Returns the unit unchanged if it's
  /// already in the target system.
  func converted(_ quantity: Double, to targetSystem: UnitSystem) -> (unit: MeasurementUnit, quantity: Double)? {
    guard let currentSystem = unitSystem, let perUnit = baseUnitsPerUnit else { return nil }
    guard currentSystem != targetSystem else { return (self, quantity) }

    let baseAmount = quantity * perUnit

    let candidates: [MeasurementUnit]
    switch (isVolume, targetSystem) {
    case (true, .metric): candidates = [.liter, .milliliter]
    case (true, .imperial): candidates = [.gallon, .quart, .pint, .cup, .tablespoon, .teaspoon]
    case (false, .metric): candidates = [.kilogram, .gram]
    case (false, .imperial): candidates = [.pound, .ounce]
    }

    // Pick the largest candidate unit whose converted quantity is at least
    // 1, so a gallon of liquid reads as "3.8 L" rather than "3785 mL".
    for candidate in candidates {
      guard let candidatePerUnit = candidate.baseUnitsPerUnit else { continue }
      let convertedQuantity = baseAmount / candidatePerUnit
      if convertedQuantity >= 1 {
        return (candidate, convertedQuantity)
      }
    }
    // Amount is smaller than the smallest candidate (e.g. a pinch of
    // something) — fall back to the smallest unit rather than showing a
    // quantity under 1 in a larger unit.
    guard let smallest = candidates.last, let smallestPerUnit = smallest.baseUnitsPerUnit else { return nil }
    return (smallest, baseAmount / smallestPerUnit)
  }
}
