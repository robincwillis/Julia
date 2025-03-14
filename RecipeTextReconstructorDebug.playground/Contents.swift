import Foundation

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
    
    // Step 1: Filter out artifacts (lines < 3 chars or only numbers)
    let filteredLines = lines.filter { line in
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      
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
        var titleEndIndex = 0
        for (index, line) in filteredLines.enumerated() {
          if index == 0 {
            continue // Skip first line (already added)
          }
          
          let isLineUppercase = line == line.uppercased() && line != line.lowercased()
          if isLineUppercase {
            title += " " + line
            titleEndIndex = index
          } else {
            break
          }
        }
      }
    }
    
    // Step 3-5: Process remaining lines
    var currentLine = ""
    var i = 0
    
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
    return specialChars.contains(UnicodeScalar(String(firstChar))!)
  }
  
  // Helper function to check if string contains ingredient fraction characters
  private static func containsIngredientCharacter(_ text: String) -> Bool {
    let ingredientChars = "½⅓¼⅔¾⅕⅖⅗⅘⅙⅚⅐⅛⅜⅝⅞⅑⅒"
    let firstTwoChars = text.prefix(2)
    return firstTwoChars.contains(where: { ingredientChars.contains($0) })
  }
}
// Test data
let sampleLines = [
  "Chocolate Chip Cookies",
  "",
  "2 cups flour",
  "1 cup sugar",
  "1/2 cup butter",
  "",
  "1. Mix dry ingredients",
  "2. Add butter",
  "3. Bake at 350°F for 10 minutes"
]

// Run the reconstructor
let reconstructed = RecipeTextReconstructor.reconstructText(from: sampleLines)
print("Title: \(reconstructed.title)")
print("Lines: \(reconstructed.reconstructedLines)")
print("Artifacts: \(reconstructed.artifacts)")
//print("Lines for classifier: \(reconstructed.linesForClassifier)")

//// Test prepareForClassification
//let classifierLines = RecipeTextReconstructor.prepareForClassification(from: sampleLines)
//print("Classifier lines: \(classifierLines)")
