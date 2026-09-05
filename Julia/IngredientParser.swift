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
    /// - `1.0` the whole string was accounted for — a bare item, or a quantity
    ///         with a recognized unit, with anything left over captured as a
    ///         comment rather than dumped in the name
    /// - `0.6` a quantity was found but the token after it was not a unit, so
    ///         it stayed in the name
    /// - `0.3` no quantity found at all; the whole string became the name
    ///
    /// A two-word input has no unit slot to fail at, so "2 eggs" scores 1.0
    /// rather than paying for a model call it does not need.
    private static func legacyParseScored(input: String, location: IngredientLocation) -> ScoredParse? {
        // Peel off the parts that are not quantity/unit/name before tokenizing.
        // Doing this first is what lets a parenthetical or a trailing note stop
        // polluting the name — previously "2 cups (250 g) flour" produced a name
        // of "(250 g) flour".
        let (withoutParens, parenComment) = extractParenthetical(input)
        let (core, trailingComment) = extractTrailingComment(withoutParens)
        let comment = [parenComment, trailingComment]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        let commentOrNil = comment.isEmpty ? nil : comment

        var components = core.split(separator: " ").map(String.init)
        guard !components.isEmpty else {
            // Nothing but a comment — keep the original so nothing is lost.
            return ScoredParse(
                ingredient: Ingredient(name: input, location: location),
                confidence: 0.3
            )
        }

        // Whole string fell through to the name — the heuristic found nothing.
        func unparsed() -> ScoredParse {
            ScoredParse(
                ingredient: Ingredient(name: input, location: location),
                confidence: 0.3
            )
        }

        /// A name that still contains digits means content was left unparsed,
        /// even when quantity and unit both resolved.
        func adjust(_ confidence: Double, forName name: String) -> Double {
            guard confidence > 0.6 else { return confidence }
            return name.contains(where: \.isNumber) ? 0.6 : confidence
        }

        // "1 1/2 cups flour" — a whole number followed by a fraction is one
        // quantity spelled across two tokens. Very common in recipes, and
        // previously parsed as quantity 1 with a name of "1/2 cups flour".
        var quantity = parseQuantity(components[0])
        if components.count > 1,
           let whole = Double(components[0]), whole == whole.rounded(),
           let fraction = slashFraction(components[1]) {
            quantity = whole + fraction
            components.remove(at: 1)
        }

        guard let quantity else {
            // No leading quantity. A single token is a plain item; anything
            // longer is something the heuristic could not read.
            if components.count == 1 {
                return ScoredParse(
                    ingredient: Ingredient(name: components[0], location: location,
                                           comment: commentOrNil),
                    confidence: 1.0
                )
            }
            return unparsed()
        }

        // Quantity with no room for a unit — "2 eggs".
        guard components.count > 2 else {
            let name = components.count > 1 ? components[1] : ""
            guard !name.isEmpty else { return unparsed() }
            return ScoredParse(
                ingredient: Ingredient(name: name, location: location,
                                       quantity: quantity, comment: commentOrNil),
                confidence: adjust(1.0, forName: name)
            )
        }

        let unitToken = components[1].lowercased()
        if MeasurementUnit(from: unitToken) != nil {
            let name = components.dropFirst(2).joined(separator: " ")
            return ScoredParse(
                ingredient: Ingredient(name: name, location: location,
                                       quantity: quantity, unit: unitToken,
                                       comment: commentOrNil),
                confidence: adjust(1.0, forName: name)
            )
        }

        // Unit token unrecognized, so it stays in the name — usable, but this is
        // where the heuristic tends to be wrong, so escalate if we can.
        let name = components.dropFirst(1).joined(separator: " ")
        return ScoredParse(
            ingredient: Ingredient(name: name, location: location,
                                   quantity: quantity, comment: commentOrNil),
            confidence: 0.6
        )
    }

    // MARK: - Splitting off non-name content

    /// Pulls a single parenthetical out of `input`, returning the remainder and
    /// its contents. "2 cups (250 g) flour" → ("2 cups flour", "250 g").
    private static func extractParenthetical(_ input: String) -> (String, String?) {
        guard let open = input.firstIndex(of: "("),
              let close = input.firstIndex(of: ")"),
              open < close
        else { return (input, nil) }

        let inner = String(input[input.index(after: open)..<close])
            .trimmingCharacters(in: .whitespaces)
        var remainder = input
        remainder.removeSubrange(open...close)
        // Collapse the double space the removal leaves behind.
        let cleaned = remainder
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
        return (cleaned, inner.isEmpty ? nil : inner)
    }

    /// Splits a trailing ", note" off the end. "3 large eggs, room temperature"
    /// → ("3 large eggs", "room temperature").
    ///
    /// Only the last comma is considered, and only when what follows contains no
    /// digits — "1 lb chicken, 2 breasts" is more likely a botched quantity than
    /// a note, and is better left for the model.
    private static func extractTrailingComment(_ input: String) -> (String, String?) {
        guard let comma = input.lastIndex(of: ",") else { return (input, nil) }
        let note = String(input[input.index(after: comma)...])
            .trimmingCharacters(in: .whitespaces)
        guard !note.isEmpty, !note.contains(where: \.isNumber) else { return (input, nil) }
        let head = String(input[input.startIndex..<comma]).trimmingCharacters(in: .whitespaces)
        guard !head.isEmpty else { return (input, nil) }
        return (head, note)
    }

    /// "1/2" → 0.5. Nil for anything that is not a simple slash fraction, so a
    /// whole number is not mistaken for one.
    private static func slashFraction(_ input: String) -> Double? {
        let parts = input.split(separator: "/")
        guard parts.count == 2,
              let numerator = Double(parts[0]),
              let denominator = Double(parts[1]),
              denominator != 0
        else { return nil }
        return numerator / denominator
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
