//
//  MeasurementValue.swift
//  Julia
//
//  Created by Robin Willis on 3/8/25.
//

import SwiftUI

enum MeasurementValue: Double, CaseIterable, Codable {
  case quarter = 0.25
  case third = 0.333
  case half = 0.5
  case twoThirds = 0.667
  case threeQuarters = 0.75
  case one = 1.0
  case two = 2.0
  case three = 3.0
  case four = 4.0
  case five = 5.0
  case six = 6.0
  case seven = 7.0
  case eight = 8.0
  case nine = 9.0
  case zero = 0.0
  
  var displaySymbol: String {
    switch self {
    case .quarter: return "¼"
    case .third: return "⅓"
    case .half: return "½"
    case .twoThirds: return "⅔"
    case .threeQuarters: return "¾"
    case .one: return "1"
    case .two: return "2"
    case .three: return "3"
    case .four: return "4"
    case .five: return "5"
    case .six: return "6"
    case .seven: return "7"
    case .eight: return "8"
    case .nine: return "9"
    case .zero: return "0"
    }
  }
  
  static var fractions: [MeasurementValue] {
    [.quarter, .third, .half, .twoThirds, .threeQuarters]
  }
  
  static var numbers: [MeasurementValue] {
    [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero]
  }
}
