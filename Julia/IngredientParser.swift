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

    /// Parses an ingredient string, escalating to Foundation Models only where
    /// the heuristic is unsure.
    ///
    /// The heuristic runs first and always produces a usable result. A parse at
    /// or above `escalationThreshold` is returned immediately with no model
    /// call, so a well-formed "2 cups flour" costs nothing. Below it — an
    /// unrecognized unit, or a quantity the heuristic could not find at all —
    /// the model is asked instead, since those are the cases it reliably wins:
    /// space-separated mixed numbers ("1 1/2 cups flour"), parentheticals
    /// ("2 cups (250 g) flour"), and quantities that are not in first position.
    ///
    /// The heuristic result is the fallback throughout: if the model is
    /// unavailable or fails, the caller still gets the best heuristic parse
    /// rather than nothing.
    static func fromStringAsync(input: String, location: IngredientLocation) async -> Ingredient? {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        guard let scored = legacyParseScored(input: input, location: location) else {
            return nil
        }

        if scored.confidence >= escalationThreshold {
            return scored.ingredient
        }
        guard await FoundationModelsService.shared.isAvailable else {
            return scored.ingredient
        }

        do {
            return try await FoundationModelsIngredientParser().parse(input, location: location)
        } catch {
            print("FoundationModels ingredient parse failed, keeping heuristic result: \(error)")
            return scored.ingredient
        }
    }

    // MARK: - Heuristic Parsing

    private static func legacyParse(input: String, location: IngredientLocation) -> Ingredient? {
        legacyParseScored(input: input, location: location)?.ingredient
    }

    /// A heuristic parse plus how much to trust it, so `fromStringAsync` can
    /// spend a Foundation Models call only where the heuristic struggled.
    struct ScoredParse {
        let ingredient: Ingredient
        let confidence: Double
    }

    /// Parses below this escalate to Foundation Models when it is available.
    static let escalationThreshold = 0.7

    /// Exposes the heuristic's confidence for tests. Internal rather than
    /// private so `@testable import` can reach it; not part of the app's
    /// call graph.
    static func scoredParseForTesting(input: String, location: IngredientLocation) -> ScoredParse? {
        legacyParseScored(input: input, location: location)
    }

    /// Confidence is derived from *how* the parse resolved, not from any model:
    ///
    /// - `1.0` single word — no quantity or unit to get wrong
    /// - `1.0` quantity and a recognized unit both found
    /// - `1.0` quantity found with no candidate unit token at all ("2 eggs")
    /// - `0.6` quantity found but the candidate unit token was unrecognized,
    ///         so it got absorbed into the name ("2 cups (250 g) flour")
    /// - `0.3` `parseQuantity` failed outright and the whole string became the
    ///         name ("1 1/2 cups flour", where "1" parses but "1/2" is not a unit)
    ///
    /// Any of the above is capped at `0.6` if the resulting *name* still holds
    /// digits or a parenthetical — see `adjust(_:forName:)`.
    ///
    /// Note on the third case: the decision recorded in docs/TODO.md scores
    /// "quantity found, unit not recognized" at 0.6. That is read here as
    /// *there was a unit token and we failed to recognize it* — the parenthetical
    /// "(absorbed into name)". A two-word input has no unit slot to fail at, so
    /// "2 eggs" scores 1.0 rather than paying for a model call it does not need.
    private static func legacyParseScored(input: String, location: IngredientLocation) -> ScoredParse? {
        let components = input.split(separator: " ").map { String($0) }
        guard !components.isEmpty else { return nil }

        // Whole string fell through to the name — the heuristic found nothing.
        func unparsed() -> ScoredParse {
            ScoredParse(ingredient: Ingredient(name: input, location: location), confidence: 0.3)
        }

        /// A name that still contains digits or a parenthetical means content
        /// was left unparsed, even when quantity and unit both resolved.
        /// Without this, "2 cups (250 g) flour" scores 1.0 on the strength of
        /// "cups" and never escalates, leaving "(250 g) flour" as the name —
        /// one of the cases escalation exists to fix.
        func adjust(_ confidence: Double, forName name: String) -> Double {
            guard confidence > 0.6 else { return confidence }
            let hasResidue = name.contains(where: \.isNumber)
                || name.contains("(")
                || name.contains(")")
            return hasResidue ? 0.6 : confidence
        }

        switch components.count {
        case 1:
            return ScoredParse(
                ingredient: Ingredient(name: components[0], location: location),
                confidence: adjust(1.0, forName: components[0])
            )

        case 2:
            guard let quantity = parseQuantity(components[0]) else { return unparsed() }
            return ScoredParse(
                ingredient: Ingredient(name: components[1], location: location, quantity: quantity),
                confidence: adjust(1.0, forName: components[1])
            )

        default:
            guard let quantity = parseQuantity(components[0]) else { return unparsed() }
            let unitToken = components[1].lowercased()

            if MeasurementUnit(from: unitToken) != nil {
                let name = components.dropFirst(2).joined(separator: " ")
                return ScoredParse(
                    ingredient: Ingredient(name: name, location: location,
                                           quantity: quantity, unit: unitToken),
                    confidence: adjust(1.0, forName: name)
                )
            }

            // Unit token unrecognized, so it stays in the name — the parse is
            // usable but this is exactly where the heuristic tends to be wrong.
            let name = components.dropFirst(1).joined(separator: " ")
            return ScoredParse(
                ingredient: Ingredient(name: name, location: location, quantity: quantity),
                confidence: 0.6
            )
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
