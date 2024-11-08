//
//  Double+Extensions.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import Foundation


extension Double {
    func toFractionString() -> String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self) // Return the whole number as a string
        }
        let epsilon = 1.0E-6
        var numerator = self
        var denominator: Double = 1.0

        while abs(numerator.rounded() - numerator) > epsilon {
            numerator *= 10
            denominator *= 10
        }

        let gcdValue = gcd(Int(numerator), Int(denominator))
        return "\(Int(numerator) / gcdValue)/\(Int(denominator) / gcdValue)"
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        if b == 0 {
            return a
        } else {
            return gcd(b, a % b)
        }
    }
}
