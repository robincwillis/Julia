import Foundation
import SwiftUI

extension Double {
  func toFractionString() -> String {
    // Handle whole numbers
    let wholePart = Int(self)
    let fractionalPart = self - Double(wholePart)
    
    // If it's a whole number, just return the integer
    if fractionalPart == 0 {
      return String(format: "%.0f", self)
    }
    
    // Use a small epsilon to account for floating point precision issues
    let epsilon = 0.05
    
    // Check for the specific fractions we need to support
    let findFraction: (Double) -> MeasurementValue? = { value in
      for fraction in MeasurementValue.fractions {
        if abs(value - fraction.rawValue) < epsilon {
          return fraction
        }
      }
      return nil
    }
    
    // Check if the fractional part matches one of our supported fractions
    if let fraction = findFraction(fractionalPart) {
      if wholePart > 0 {
        return "\(wholePart) \(fraction.displaySymbol)"
      } else {
        return fraction.displaySymbol
      }
    }
    
    // If it's not one of our supported fractions, just return a decimal
    if wholePart > 0 {
      return String(format: "%.1f", self)
    } else {
      return String(format: "%.1f", self)
    }
  }
}
