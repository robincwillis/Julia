import Foundation
import SwiftData
import SwiftUI

struct TextReconstructorResult {
  var title: String
  var reconstructedLines: [String]
  var artifacts: [String]
}

class RecipeTextReconstructor {
  // Main function to reconstruct recipe text from an array of lines
  static func reconstructText(from lines: [String]) -> TextReconstructorResult {
    var title = ""
    var reconstructedLines: [String] = []
    var artifacts: [String] = []
    
    // Skip if empty
    if lines.isEmpty {
      return TextReconstructorResult(title: "", reconstructedLines: [], artifacts: [])
    }
    
    // Step 1: Process and preserve ALL lines, just store very short ones or numeric-only ones as artifacts
    var processedLines: [(String, Bool)] = []
    
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      
      // Skip empty lines without adding to artifacts
      if trimmed.isEmpty {
        continue
      }
      
      // Mark as artifact if line is too short or only numbers, but keep it in the processed lines
      let isArtifact = trimmed.count < 3 ||
                       CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: trimmed))
      
      if isArtifact {
        artifacts.append(trimmed)
      }
      
      processedLines.append((trimmed, isArtifact))
    }
    
    // Step 2: Join lines by context rather than assuming title position
    var currentLine = ""
    
    for (i, (line, isArtifact)) in processedLines.enumerated() {
      // Always include artifact lines without joining them
      if isArtifact {
        // First save any current line buffer
        if !currentLine.isEmpty {
          reconstructedLines.append(currentLine)
          currentLine = ""
        }
        
        reconstructedLines.append(line)
        continue
      }
      
      // Check if line starts with criteria that indicates a new line
      let startsWithUppercase = line.first?.isUppercase ?? false
      let startsWithNumber = line.first?.isNumber ?? false
      let startsWithSymbol = startsWithSpecialCharacter(line)
      let startsWithIngredientChar = containsIngredientCharacter(line)
      let isProbablyNewLine = startsWithUppercase || startsWithNumber ||
                              startsWithSymbol || startsWithIngredientChar
      
      // If this seems like a new line or we have no current line
      if isProbablyNewLine || currentLine.isEmpty {
        // Save any previous content
        if !currentLine.isEmpty {
          reconstructedLines.append(currentLine)
          currentLine = ""
        }
        
        currentLine = line
        
        // If line ends with a sentence-ending punctuation, it's complete
        if line.hasSuffix(".") || line.hasSuffix("!") || line.hasSuffix("?") {
          reconstructedLines.append(currentLine)
          currentLine = ""
        }
      } else {
        // This line continues the previous line
        if !currentLine.isEmpty {
          currentLine += " " + line
        } else {
          currentLine = line
        }
        
        // If line ends with a sentence-ending punctuation, it's complete
        if line.hasSuffix(".") || line.hasSuffix("!") || line.hasSuffix("?") {
          reconstructedLines.append(currentLine)
          currentLine = ""
        }
      }
    }
    
    // Add final line if not empty
    if !currentLine.isEmpty {
      reconstructedLines.append(currentLine)
    }
    
    // No longer attempt to determine the title here
    // The actual title will be determined by the classifier
    
    // Debug print to verify the results
    print("*** RecipeTextReconstructor Results ***")
    print("Reconstructed Lines (\(reconstructedLines.count)): \(reconstructedLines)")
    print("Artifacts (\(artifacts.count)): \(artifacts)")
    
    return TextReconstructorResult(
      title: title, // This will now be empty, letting the classifier determine the title
      reconstructedLines: reconstructedLines,
      artifacts: artifacts
    )
  }
  
  // Helper function to check if string starts with a special character (dash, bullet, etc.)
  private static func startsWithSpecialCharacter(_ text: String) -> Bool {
    guard let firstChar = text.first else { return false }
    let specialChars = CharacterSet(charactersIn: "-•*–—⁃․⁌⁍◦◘○●◎✓✔✗✘❋❖")
    
    // Need to convert Character to UnicodeScalar for contains check
    guard let unicodeScalar = firstChar.unicodeScalars.first else { return false }
    return specialChars.contains(unicodeScalar)
  }
  
  // Helper function to check if string contains ingredient fraction characters
  private static func containsIngredientCharacter(_ text: String) -> Bool {
    let ingredientChars = "½⅓¼⅔¾⅕⅖⅗⅘⅙⅚⅐⅛⅜⅝⅞⅑⅒"
    let firstTwoChars = text.prefix(2)
    return firstTwoChars.contains(where: { ingredientChars.contains($0) })
  }
}
