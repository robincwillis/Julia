//
//  RecipeBoundaryDetector.swift
//  Julia
//
//  Created by Robin Willis on 5/10/25.
//



import Foundation
import NaturalLanguage

class RecipeBoundaryDetector {
    
    struct RecipeSegment {
        let title: String
        let lines: [String]
        let startIndex: Int
        let endIndex: Int
        let titleConfidence: Double
    }
    
    // TODO: Move to Models, more comprehensive solution
    // Section headers that indicate recipe structure
    private let sectionHeaders = [
        "ingredients", "ingredient", "ingredients:", "ingredient list",
        "directions", "instructions", "method", "steps", "preparation",
        "notes", "tips", "serving", "servings", "yield", "yields",
        "prep time", "cook time", "total time", "equipment"
    ]
    
    // End markers that indicate recipe conclusion
    private let endMarkers = [
        "nutrition facts", "nutritional information", "calories",
        "© ", "copyright", "all rights reserved", "print recipe"
    ]
    
    /// Detect multiple recipes and their boundaries in text
    func detectRecipeBoundaries(in textLines: [String],
                              using classifier: RecipeTextClassifier) async -> [RecipeSegment] {
        var segments: [RecipeSegment] = []
        var currentSegmentStart = 0
        
        // Process lines to find recipe boundaries
        var index = 0
        while index < textLines.count {
            let line = textLines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            if line.isEmpty {
                index += 1
                continue
            }
            
            // Check if this could be a new recipe title
            let classification = classifier.classifyLine(line)
            let isTitleCandidate = classification.lineType == .title && classification.confidence > 0.5
            
            // Check if this is a section header or end marker
            let isSectionHeader = isSectionHeaderLine(line)
            let isEndMarker = isEndMarkerLine(line)
            
            // If we find a potential new recipe title (not at the start)
            if isTitleCandidate && index > currentSegmentStart + 3 {
                // Create segment for previous recipe
                if let title = findBestTitle(in: textLines[currentSegmentStart...index-1],
                                           using: classifier) {
                    let segment = RecipeSegment(
                        title: title.text,
                        lines: Array(textLines[currentSegmentStart..<index]),
                        startIndex: currentSegmentStart,
                        endIndex: index - 1,
                        titleConfidence: title.confidence
                    )
                    segments.append(segment)
                }
                currentSegmentStart = index
            }
            
            // If we find an end marker, possibly end current recipe
            if isEndMarker && index > currentSegmentStart + 5 {
                // Create segment up to this point
                if let title = findBestTitle(in: textLines[currentSegmentStart...index],
                                           using: classifier) {
                    let segment = RecipeSegment(
                        title: title.text,
                        lines: Array(textLines[currentSegmentStart...index]),
                        startIndex: currentSegmentStart,
                        endIndex: index,
                        titleConfidence: title.confidence
                    )
                    segments.append(segment)
                }
                currentSegmentStart = index + 1
            }
            
            index += 1
        }
        
        // Create final segment
        if currentSegmentStart < textLines.count {
            if let title = findBestTitle(in: textLines[currentSegmentStart...],
                                       using: classifier) {
                let segment = RecipeSegment(
                    title: title.text,
                    lines: Array(textLines[currentSegmentStart...]),
                    startIndex: currentSegmentStart,
                    endIndex: textLines.count - 1,
                    titleConfidence: title.confidence
                )
                segments.append(segment)
            }
        }
        
        return segments
    }
    
    /// Find the best title candidate in a range of lines
    private func findBestTitle(in lines: ArraySlice<String>,
                             using classifier: RecipeTextClassifier) -> (text: String, confidence: Double)? {
        var bestCandidate: (text: String, confidence: Double)?
        
        // Look through first 5 lines for best title
        for i in 0..<min(5, lines.count) {
            let index = lines.startIndex + i
            let line = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if line.isEmpty { continue }
            
            let classification = classifier.classifyLine(line)
            
            // Use multiple criteria for title detection
            var titleScore = 0.0
            
            // 1. Classifier confidence
            if classification.lineType == .title {
                titleScore += classification.confidence * 0.4
            }
            
            // 2. Position (earlier is better)
            titleScore += (5.0 - Double(i)) / 5.0 * 0.2
            
            // 3. Capitalization
            if isProperlyCapitalized(line) {
                titleScore += 0.2
            }
            
            // 4. Length (not too short, not too long)
            let wordCount = line.components(separatedBy: .whitespaces).count
            if wordCount >= 2 && wordCount <= 10 {
                titleScore += 0.2
            }
            
            if bestCandidate == nil || titleScore > bestCandidate!.confidence {
                bestCandidate = (text: line, confidence: titleScore)
            }
        }
        
        return bestCandidate
    }
    
    /// Check if a line is a section header
    private func isSectionHeaderLine(_ line: String) -> Bool {
        let lowercaseLine = line.lowercased()
        return sectionHeaders.contains { header in
            lowercaseLine.hasPrefix(header) || lowercaseLine == header
        }
    }
    
    /// Check if a line is an end marker
    private func isEndMarkerLine(_ line: String) -> Bool {
        let lowercaseLine = line.lowercased()
        return endMarkers.contains { marker in
            lowercaseLine.contains(marker)
        }
    }
    
    /// Check if line is properly capitalized (like a title)
    private func isProperlyCapitalized(_ text: String) -> Bool {
        // Check if it's title case or all caps
        let words = text.components(separatedBy: .whitespaces)
        
        // All caps check
        if text == text.uppercased() && text != text.lowercased() {
            return true
        }
        
        // Title case check
        var capitalizedCount = 0
        for word in words {
            if let first = word.first, first.isUppercase {
                capitalizedCount += 1
            }
        }
        
        return Double(capitalizedCount) / Double(words.count) > 0.6
    }
    
}
