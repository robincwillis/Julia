//
//  RecipePostProcessor.swift
//  Julia
//
//  Created by Robin Willis on 5/10/25.
//

import Foundation

/// Post-processes recipe data to clean, standardize, and format consistently
class RecipePostProcessor {
    
    /// Post-process classified recipe data
    func postProcess(recipeData: RecipeData) -> RecipeData {
        var processed = recipeData
        
        // Clean title
        processed.title = cleanTitle(recipeData.title)
        
        // Clean and standardize ingredients
        processed.ingredients = recipeData.ingredients.map { cleanIngredient($0) }
        
        // Clean instructions
        processed.instructions = recipeData.instructions.map { cleanInstruction($0) }
        
        // Clean summary
        processed.summary = recipeData.summary.map { cleanText($0) }
        
        // Standardize timings
        processed.timings = recipeData.timings.map { standardizeTime($0) }
        
        // Standardize servings
        processed.servings = recipeData.servings.map { standardizeServing($0) }
        
        return processed
    }
    
    /// Clean title text
    private func cleanTitle(_ title: String) -> String {
        var cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common prefixes
        let prefixes = ["recipe for", "how to make", "recipe:", "make:"]
        for prefix in prefixes {
            if cleaned.lowercased().hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        
        // Remove trailing punctuation
        if cleaned.hasSuffix(":") || cleaned.hasSuffix(".") {
            cleaned = String(cleaned.dropLast())
        }
        
        // Proper capitalization
        cleaned = properlyCapitalize(cleaned)
        
        return cleaned
    }
    
    /// Clean ingredient text
    private func cleanIngredient(_ ingredient: String) -> String {
        var cleaned = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove leading bullets, numbers, etc.
        cleaned = removeLeadingMarkers(cleaned)
        
        // Standardize units
        cleaned = standardizeUnits(cleaned)
        
        // Fix spacing around fractions
        cleaned = fixFractionSpacing(cleaned)
        
        return cleaned
    }
    
    /// Clean instruction text
    private func cleanInstruction(_ instruction: String) -> String {
        var cleaned = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove leading step numbers or bullets
        cleaned = removeLeadingStepMarkers(cleaned)
        
        // Ensure sentence ends with period
        if !cleaned.hasSuffix(".") && !cleaned.hasSuffix("!") && !cleaned.hasSuffix("?") {
            cleaned += "."
        }
        
        // Capitalize first letter
        if let first = cleaned.first, first.isLowercase {
            cleaned = cleaned.prefix(1).uppercased() + cleaned.dropFirst()
        }
        
        return cleaned
    }
    
    /// Clean general text
    private func cleanText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fix multiple spaces
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return cleaned
    }
    
    /// Standardize time format
    private func standardizeTime(_ time: String) -> String {
        var standardized = time.lowercased()
        
        // Convert abbreviations to full words
        let timeAbbreviations: [String: String] = [
            "min": "minutes",
            "mins": "minutes",
            "hr": "hour",
            "hrs": "hours",
            "sec": "seconds",
            "secs": "seconds"
        ]
        
        for (abbrev, full) in timeAbbreviations {
            standardized = standardized.replacingOccurrences(of: "\\b\(abbrev)\\b",
                                                          with: full,
                                                          options: .regularExpression)
        }
        
        // Ensure proper format: "X minutes", "X hours"
        if let range = standardized.range(of: "\\d+\\s*(minute|hour|second)",
                                        options: .regularExpression) {
            let match = String(standardized[range])
            let components = match.components(separatedBy: .whitespaces)
            if components.count == 2 {
                let number = components[0]
                let unit = components[1]
                
                // Pluralize if needed
                if let num = Int(number), num != 1 && !unit.hasSuffix("s") {
                    standardized = "\(number) \(unit)s"
                }
            }
        }
        
        return standardized.capitalized
    }
    
    /// Standardize serving format
    private func standardizeServing(_ serving: String) -> String {
        var standardized = serving.lowercased()
        
        // Convert common formats
        standardized = standardized.replacingOccurrences(of: "serves", with: "Serves")
        standardized = standardized.replacingOccurrences(of: "yields", with: "Yields")
        standardized = standardized.replacingOccurrences(of: "makes", with: "Makes")
        
        // Ensure format: "Serves X" or "Makes X servings"
        if !standardized.hasPrefix("serves") &&
           !standardized.hasPrefix("yields") &&
           !standardized.hasPrefix("makes") {
            if let match = standardized.range(of: "\\d+", options: .regularExpression) {
                let number = String(standardized[match])
                standardized = "Serves \(number)"
            }
        }
        
        return standardized
    }
    
    // MARK: - Helper Methods
    
    /// Remove leading bullets, numbers, etc.
    private func removeLeadingMarkers(_ text: String) -> String {
        var cleaned = text
        
        // Remove leading bullets
        let bulletPattern = "^[•\\-*\\+]\\s*"
        cleaned = cleaned.replacingOccurrences(of: bulletPattern, with: "", options: .regularExpression)
        
        // Remove leading numbers with dot or parentheses
        let numberPattern = "^\\d+[\\.)\\s]*"
        cleaned = cleaned.replacingOccurrences(of: numberPattern, with: "", options: .regularExpression)
        
        return cleaned
    }
    
    /// Remove leading step markers from instructions
    private func removeLeadingStepMarkers(_ text: String) -> String {
        var cleaned = text
        
        // Remove "Step X:" patterns
        let stepPattern = "^Step\\s+\\d+[:.]?\\s*"
        cleaned = cleaned.replacingOccurrences(of: stepPattern, with: "", options: [.regularExpression, .caseInsensitive])
        
        // Remove leading numbers
        let numberPattern = "^\\d+[\\.)\\s]*"
        cleaned = cleaned.replacingOccurrences(of: numberPattern, with: "", options: .regularExpression)
        
        return cleaned
    }
    
    /// Standardize measurement units
    private func standardizeUnits(_ text: String) -> String {
        var standardized = text
        
        let unitMappings: [String: String] = [
            "tbsp": "tablespoon",
            "tbs": "tablespoon",
            "tsp": "teaspoon",
            "tsps": "teaspoons",
            "oz": "ounce",
            "lb": "pound",
            "lbs": "pounds",
            "g": "gram",
            "kg": "kilogram",
            "ml": "milliliter",
            "l": "liter",
            "c": "cup",
            "pt": "pint",
            "qt": "quart",
            "gal": "gallon"
        ]
        
        for (abbrev, full) in unitMappings {
            // Use word boundaries to avoid partial matches
            let pattern = "\\b\(abbrev)\\b"
            standardized = standardized.replacingOccurrences(of: pattern, with: full, options: [.regularExpression, .caseInsensitive])
        }
        
        return standardized
    }
    
    /// Fix spacing around fractions
    private func fixFractionSpacing(_ text: String) -> String {
        var fixed = text
        
        // Fraction characters that need fixing
        let fractions = ["½", "⅓", "¼", "⅔", "¾", "⅕", "⅖", "⅗", "⅘", "⅙", "⅚", "⅛", "⅜", "⅝", "⅞"]
        
        for fraction in fractions {
            // Ensure space before fraction if preceded by digit
            fixed = fixed.replacingOccurrences(of: "(\\d)\(fraction)", with: "$1 \(fraction)", options: .regularExpression)
            
            // Ensure space after fraction if followed by word
            fixed = fixed.replacingOccurrences(of: "\(fraction)([A-Za-z])", with: "\(fraction) $1", options: .regularExpression)
        }
        
        return fixed
    }
    
    /// Properly capitalize text (for titles)
    private func properlyCapitalize(_ text: String) -> String {
        // If it's all caps, convert to title case
        if text == text.uppercased() && text != text.lowercased() {
            return text.capitalized
        }
        
        // Otherwise, ensure first letter is capitalized
        if let first = text.first, first.isLowercase {
            return text.prefix(1).uppercased() + text.dropFirst()
        }
        
        return text
    }
}
