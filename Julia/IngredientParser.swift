//
//  IngredientParser.swift
//  Julia
//

import Foundation

/// `IngredientParser` provides functionality to parse ingredient text input into
/// structured `Ingredient` objects and vice versa.
///
/// Synchronous path (`fromString`) uses heuristic parsing for speed.
/// Async path (`fromStringAsync`) uses Foundation Models for richer accuracy.
class IngredientParser {

    // MARK: - Parsing Methods

    /// Parses an ingredient string synchronously using heuristic rules.
    /// Used as a lightweight fallback or for batch operations where FM is overkill.
    static func fromString(input: String, location: IngredientLocation) -> Ingredient? {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return legacyParse(input: input, location: location)
    }

    /// Parses an ingredient string using Foundation Models for rich structured output.
    /// Falls back to heuristic parsing if Foundation Models is unavailable.
    static func fromStringAsync(input: String, location: IngredientLocation) async -> Ingredient? {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        guard await FoundationModelsService.shared.isAvailable else {
            return legacyParse(input: input, location: location)
        }
        do {
            return try await FoundationModelsIngredientParser().parse(input, location: location)
        } catch {
            print("FoundationModels ingredient parse failed, falling back: \(error)")
            return legacyParse(input: input, location: location)
        }
    }

    // MARK: - Heuristic Parsing

    private static func legacyParse(input: String, location: IngredientLocation) -> Ingredient? {
        let components = input.split(separator: " ").map { String($0) }

        switch components.count {
        case 1:
            return Ingredient(name: components[0], location: location)

        case 2:
            if let quantity = parseQuantity(components[0]) {
                return Ingredient(name: components[1], location: location, quantity: quantity)
            }
            return Ingredient(name: input, location: location)

        case 3:
            if let quantity = parseQuantity(components[0]) {
                if MeasurementUnit(from: components[1].lowercased()) != nil {
                    return Ingredient(name: components[2], location: location,
                                     quantity: quantity, unit: components[1].lowercased())
                }
                let name = components.dropFirst(1).joined(separator: " ")
                return Ingredient(name: name, location: location, quantity: quantity)
            }
            return Ingredient(name: input, location: location)

        default:
            if let quantity = parseQuantity(components[0]) {
                if MeasurementUnit(from: components[1].lowercased()) != nil {
                    let name = components.dropFirst(2).joined(separator: " ")
                    return Ingredient(name: name, location: location,
                                     quantity: quantity, unit: components[1].lowercased())
                }
                let name = components.dropFirst(1).joined(separator: " ")
                return Ingredient(name: name, location: location, quantity: quantity)
            }
            return Ingredient(name: input, location: location)
        }
    }

    // MARK: - Quantity Parsing

    private static func parseQuantity(_ input: String) -> Double? {
        let processedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !processedInput.isEmpty else { return nil }

        if processedInput.contains("-") {
            let parts = processedInput.split(separator: "-").map { parseFraction(String($0)) }
            if parts.count == 2, let min = parts[0], let max = parts[1] {
                return (min + max) / 2.0
            }
        }

        let fractionMap: [Character: Double] = [
            "¼": 0.25, "½": 0.5, "¾": 0.75,
            "⅓": 1.0/3.0, "⅔": 2.0/3.0,
            "⅕": 0.2, "⅖": 0.4, "⅗": 0.6, "⅘": 0.8,
            "⅙": 1.0/6.0, "⅚": 5.0/6.0,
            "⅛": 0.125, "⅜": 0.375, "⅝": 0.625, "⅞": 0.875
        ]
        for (char, value) in fractionMap {
            if processedInput.contains(char) {
                let components = processedInput.components(
                    separatedBy: CharacterSet(charactersIn: String(fractionMap.keys))
                )
                if let wholeString = components.first,
                   let whole = Double(wholeString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return whole + value
                }
                return value
            }
        }
        return parseFraction(processedInput)
    }

    private static func parseFraction(_ input: String) -> Double? {
        let components = input.split(separator: "/").map {
            Double($0.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if components.count == 2, let n = components[0], let d = components[1], d != 0 {
            return n / d
        }
        return Double(input.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - String Conversion

    /// Converts an `Ingredient` object back to a human-readable string.
    static func toString(for ingredient: Ingredient?) -> String {
        guard let ingredient else { return "" }
        var result = ""
        if let quantity = ingredient.quantity {
            result += formatQuantity(quantity)
            if let unit = ingredient.unit {
                result += " \(unit.rawValue)"
            }
        }
        result = result.isEmpty ? ingredient.name : "\(result) \(ingredient.name)"
        if let comment = ingredient.comment, !comment.isEmpty {
            result += ", \(comment)"
        }
        return result
    }

    private static func formatQuantity(_ quantity: Double) -> String {
        if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", quantity)
        }
        let fractionMap: [Double: String] = [
            0.25: "¼", 0.5: "½", 0.75: "¾", 1.0/3.0: "⅓", 2.0/3.0: "⅔"
        ]
        let whole = Int(quantity)
        let frac = quantity - Double(whole)
        if let symbol = fractionMap[round(frac * 100) / 100] {
            return whole > 0 ? "\(whole) \(symbol)" : symbol
        }
        return String(format: "%.2f", quantity).replacingOccurrences(of: ".00", with: "")
    }
}
