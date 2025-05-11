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
    
    // Step 1: Filter out artifacts (lines < 3 chars or only numbers)
    let filteredLines = lines.filter { line in
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      
      // Skip empty lines but don't count as artifacts
      if trimmed.isEmpty {
        return false
      }
      
      // Check if line is too short
      if trimmed.count < 3 {
        artifacts.append(trimmed)
        return false
      }
      
      // Check if line is only numbers
      if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: trimmed)) {
        artifacts.append(trimmed)
        return false
      }
      
      return true
    }
    
    // Step 2: Extract title from the first non-artifact line
    if let firstLine = filteredLines.first {
      title = firstLine
      
      // Check if title is all uppercase
      let isAllUppercase = firstLine == firstLine.uppercased() && firstLine != firstLine.lowercased()
      
      if isAllUppercase {
        // Find consecutive uppercase lines and add to title
        //var titleEndIndex: Int
        for (index, line) in filteredLines.enumerated() {
          if index == 0 {
            continue // Skip first line (already added)
          }
          
          let isLineUppercase = line == line.uppercased() && line != line.lowercased()
          if isLineUppercase {
            title += " " + line
            //titleEndIndex = index
          } else {
            break
          }
        }
        
        // Include the title lines in reconstructed lines as well
        reconstructedLines.append(title)
      } else {
        // Include the title in reconstructed lines
        reconstructedLines.append(title)
      }
    }
    
    // Step 3-5: Process remaining lines
    var currentLine = ""
    var i = 0
    
    // Skip the title line(s) that we've already processed
    if !filteredLines.isEmpty {
      i = 1
    }
    
    while i < filteredLines.count {
      let line = filteredLines[i].trimmingCharacters(in: .whitespacesAndNewlines)
      
      // Skip empty lines
      if line.isEmpty {
        i += 1
        continue
      }
      
      // Check if line starts with criteria that indicates a new line
      let startsWithUppercase = line.first?.isUppercase ?? false
      let startsWithNumber = line.first?.isNumber ?? false
      let startsWithSymbol = startsWithSpecialCharacter(line)
      let startsWithIngredientChar = containsIngredientCharacter(line)
      
      if startsWithUppercase || startsWithNumber || startsWithSymbol || startsWithIngredientChar || currentLine.isEmpty {
        // If we have content in the current line, save it before starting a new one
        if !currentLine.isEmpty {
          reconstructedLines.append(currentLine)
          currentLine = ""
        }
        
        currentLine = line
        
        // If line ends with period, add it and reset currentLine
        if line.hasSuffix(".") {
          reconstructedLines.append(currentLine)
          currentLine = ""
        }
      } else {
        // Line starts with lowercase - append to current line
        if !currentLine.isEmpty {
          currentLine += " " + line
        } else {
          currentLine = line
        }
        
        // If line ends with period, add it and reset currentLine
        if line.hasSuffix(".") {
          reconstructedLines.append(currentLine)
          currentLine = ""
        }
      }
      
      i += 1
    }
    
    // Add final line if not empty
    if !currentLine.isEmpty {
      reconstructedLines.append(currentLine)
    }
    
    // Debug print to verify the results
    // print("*** RecipeTextReconstructor Results ***")
    // print("Title: \(title)")
    // print("Reconstructed Lines (\(reconstructedLines.count)): \(reconstructedLines)")
    // print("Artifacts (\(artifacts.count)): \(artifacts)")
    
    return TextReconstructorResult(
      title: title,
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
