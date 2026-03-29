//
//  IngredientParser.swift
//  Julia
//
//  Created by Robin Willis on 11/11/24.
//

import Foundation
import CoreML
import NaturalLanguage

/// `IngredientParser` provides functionality to parse ingredient text input into
/// structured `Ingredient` objects and vice versa.
///
/// This class handles various input formats using a trained ML model:
/// - Simple name: "Salt"
/// - Quantity and name: "2 Apples"
/// - Quantity, unit, and name: "1.5 cups Flour"
/// - Fractions: "1/2 cup Sugar"
/// - Complex formats: "2-3 large eggs, beaten"
///
/// It also converts ingredients back to readable strings.
class IngredientParser {
    // MARK: - ML Model Integration
    
    /// ML model for ingredient classification
    private static var mlModel: NLModel?
    
    /// Token tags used by the classifier
    private enum TokenTag: String {
        case name = "name"
        case measurement = "measurement"  // corresponds to unit
        case quantity = "quantity"
        case comment = "comment"
        case marker = "marker"  // to be ignored
        case unknown = "unknown"
    }
    
    /// Initialize the ML model when first needed
    private static func loadMLModelIfNeeded() {
        guard mlModel == nil else { return }
        
        do {
            if let modelURL = Bundle.main.url(forResource: "IngredientClassifier", withExtension: "mlmodelc") {
                mlModel = try NLModel(contentsOf: modelURL)
                print("Successfully loaded IngredientClassifier model")
            } else {
                print("Error: IngredientClassifier.mlmodelc not found in bundle")
            }
        } catch {
            print("Error loading IngredientClassifier model: \(error)")
        }
    }
    
    // MARK: - Parsing Methods
    
    /// Creates an Ingredient object from a text input string and location.
    ///
    /// - Parameters:
    ///   - input: The text string to parse (e.g., "2 cups flour")
    ///   - location: The IngredientLocation where this ingredient belongs
    /// - Returns: A new Ingredient object if parsing succeeds, nil otherwise
    static func fromString(input: String, location: IngredientLocation) -> Ingredient? {
        // Load ML model if needed
        loadMLModelIfNeeded()
        
        // Ensure we have a valid input
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        // If ML model is available, use it for classification
        if let model = mlModel {
            return parseWithMLModel(input: input, location: location, model: model)
        } else {
            // Fallback to legacy parsing if ML model is unavailable
            return legacyParse(input: input, location: location)
        }
    }
    
    /// Parses ingredient text using the ML model
    ///
    /// - Parameters:
    ///   - input: The text string to parse
    ///   - location: The IngredientLocation where this ingredient belongs
    ///   - model: The NLModel to use for classification
    /// - Returns: A new Ingredient object if parsing succeeds, nil otherwise
    private static func parseWithMLModel(input: String, location: IngredientLocation, model: NLModel) -> Ingredient? {
        // Tokenize the input string
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = input
        
        var nameTokens: [String] = []
        var quantityTokens: [String] = []
        var measurementTokens: [String] = []
        var commentTokens: [String] = []
        
        // Tag each token in the string
        tagger.enumerateTags(in: input.startIndex..<input.endIndex, unit: .word, scheme: .tokenType) { _, tokenRange in
            let token = String(input[tokenRange])
            
            // Skip whitespace and punctuation except for fractions and decimals
            guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
            if token.rangeOfCharacter(from: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "/.-¼½¾"))) == nil {
                return true
            }
            
            // Classify the token using the ML model
            let predictedLabel = model.predictedLabel(for: token) ?? TokenTag.unknown.rawValue
            
            // Group tokens by their predicted labels
            switch predictedLabel {
            case TokenTag.name.rawValue:
                nameTokens.append(token)
            case TokenTag.quantity.rawValue:
                quantityTokens.append(token)
            case TokenTag.measurement.rawValue:
                measurementTokens.append(token)
            case TokenTag.comment.rawValue:
                commentTokens.append(token)
            case TokenTag.marker.rawValue:
                // Ignore markers
                break
            default:
                // For unknown tags, default to considering them part of the name
                nameTokens.append(token)
            }
            
            return true
        }
        
        // Assemble the ingredient
        let name = nameTokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Process the quantity - handle ranges (e.g., "2-3") and fractions
        let quantityString = quantityTokens.joined(separator: " ")
        let quantity = parseQuantity(quantityString)
        
        // Process the unit/measurement
        let measurementString = measurementTokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Process the comment
        var comment: String? = nil
        if !commentTokens.isEmpty {
            comment = commentTokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Validate that we have at least a name
        guard !name.isEmpty else {
            return nil
        }
        
        // Create the ingredient
        return Ingredient(
            name: name,
            location: location,
            quantity: quantity,
            unit: measurementString.isEmpty ? nil : measurementString,
            comment: comment
        )
    }
    
    /// Parses a quantity string, handling fractions, decimals, and ranges
    ///
    /// - Parameter input: Quantity string to parse
    /// - Returns: Parsed Double value, or nil if parsing fails
    private static func parseQuantity(_ input: String) -> Double? {
        let processedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty check
        if processedInput.isEmpty {
            return nil
        }
        
        // Handle ranges like "2-3" by taking the average
        if processedInput.contains("-") {
            let parts = processedInput.split(separator: "-").map { parseFraction(String($0)) }
            if parts.count == 2, let min = parts[0], let max = parts[1] {
                return (min + max) / 2.0
            }
        }
        
        // Handle Unicode fractions
        let fractionMap: [Character: Double] = [
            "¼": 0.25,
            "½": 0.5,
            "¾": 0.75,
            "⅓": 1.0/3.0,
            "⅔": 2.0/3.0,
            "⅕": 0.2,
            "⅖": 0.4,
            "⅗": 0.6,
            "⅘": 0.8,
            "⅙": 1.0/6.0,
            "⅚": 5.0/6.0,
            "⅛": 0.125,
            "⅜": 0.375,
            "⅝": 0.625,
            "⅞": 0.875
        ]
        
        // If the string contains a Unicode fraction character
        for (char, value) in fractionMap {
            if processedInput.contains(char) {
                // Extract whole number part if present
                let components = processedInput.components(separatedBy: CharacterSet(charactersIn: String(fractionMap.keys)))
                if components.count > 0, let wholeNumber = Double(components[0].trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return wholeNumber + value
                }
                return value
            }
        }
        
        // Regular fraction or decimal parsing
        return parseFraction(processedInput)
    }
    
    /// Parses a fraction string (e.g., "1/2") or decimal string into a Double value.
    ///
    /// - Parameter input: A string representing a fraction (e.g., "1/2") or a decimal number.
    /// - Returns: The numeric value as a Double if parsable, nil otherwise.
    private static func parseFraction(_ input: String) -> Double? {
        let components = input.split(separator: "/").map {
            Double($0.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        // If input is a fraction (e.g., "1/2"), calculate the division
        if components.count == 2, let numerator = components[0], let denominator = components[1], denominator != 0 {
            return numerator / denominator
        }
        
        // Otherwise try to parse as a regular decimal number
        return Double(input.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    /// Legacy parsing method for backward compatibility
    ///
    /// - Parameters:
    ///   - input: The text string to parse
    ///   - location: The IngredientLocation where this ingredient belongs
    /// - Returns: A new Ingredient object if parsing succeeds, nil otherwise
    private static func legacyParse(input: String, location: IngredientLocation) -> Ingredient? {
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
    
    // MARK: - String Conversion
    
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
            ingredientString += formatQuantity(quantity)
            
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
        
        // Add comment if available
        if let comment = ingredient.comment, !comment.isEmpty {
            ingredientString += ", \(comment)"
        }
        
        return ingredientString
    }
    
    /// Formats a quantity value as a string, using fractions for common values
    ///
    /// - Parameter quantity: The quantity value to format
    /// - Returns: Formatted string representation
    private static func formatQuantity(_ quantity: Double) -> String {
        // Handle whole numbers
        if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", quantity)
        }
        
        // Check for common fractions and use special formatting
        let fractionMap: [Double: String] = [
            0.25: "¼",
            0.5: "½",
            0.75: "¾",
            1.0/3.0: "⅓",
            2.0/3.0: "⅔"
        ]
        
        // Extract whole number and fractional parts
        let wholePart = Int(quantity)
        let fractionalPart = quantity - Double(wholePart)
        
        // Check if the fractional part matches a common fraction
        if let fractionSymbol = fractionMap[round(fractionalPart * 100) / 100] {
            if wholePart > 0 {
                return "\(wholePart) \(fractionSymbol)"
            } else {
                return fractionSymbol
            }
        }
        
        // Default decimal formatting for other values
        return String(format: "%.2f", quantity).replacingOccurrences(of: ".00", with: "")
    }
}
