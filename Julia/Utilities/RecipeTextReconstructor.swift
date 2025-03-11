//
//  RecipeTextReconstructor.swift
//  Julia
//
//  Created by Robin Willis on 3/10/25.
//

import Foundation
import SwiftData

class RecipeTextReconstructor {
  
  struct ReconstructedRecipe {
    var title: String
    var servingInfo: String
    var description: String
    var ingredients: [String]
    var instructions: [String]
    var notes: [String]
    var footnotes: [String]
    var rawText: [String]
    
    // Flatten the processed text into lines for the classifier
    var linesForClassifier: [String] {
      var result: [String] = []
      
      // Add title if present
      if !title.isEmpty {
        result.append(title)
      }
      
      // Add ingredients
      result.append(contentsOf: ingredients)
      
      // Add instructions
      result.append(contentsOf: instructions)
      
      // Add notes and footnotes if present
      if !notes.isEmpty {
        result.append(contentsOf: notes)
      }
      if !footnotes.isEmpty {
        result.append(contentsOf: footnotes)
      }
      
      return result
    }
    
    init() {
      title = ""
      servingInfo = ""
      description = ""
      ingredients = []
      instructions = []
      notes = []
      footnotes = []
      rawText = []
    }
  }
  
  // Process OCR text lines and prepare them for classification
  static func prepareForClassification(from lines: [String]) -> [String] {
    let reconstructed = reconstructRecipe(from: lines)
    return reconstructed.linesForClassifier
  }
  
  // Integration method to use with RecipeTextClassifier
  static func processAndClassify(lines: [String], classifier: RecipeTextClassifier, context: ModelContext) -> Recipe {
    // First reconstruct the text
    let reconstructed = reconstructRecipe(from: lines)
    
    // Then pass the reconstructed lines to the classifier
    let processedLines = reconstructed.linesForClassifier
    
    // Use the classifier to create a Recipe
    let recipe = classifier.createRecipeFromText(processedLines, context: context)
    
    // Add any additional information from reconstruction that wasn't handled by classifier
    if recipe.summary == nil && !reconstructed.description.isEmpty {
      recipe.summary = reconstructed.description
    }
    
    if reconstructed.notes.count > 0 || reconstructed.footnotes.count > 0 {
      let existingInstructions = recipe.instructions
      var updatedInstructions = existingInstructions
      
      // Add notes as additional instructions if not already included
      for note in reconstructed.notes {
        if !existingInstructions.contains(note) {
          updatedInstructions.append(note)
        }
      }
      
      // Add footnotes as additional instructions if not already included
      for footnote in reconstructed.footnotes {
        if !existingInstructions.contains(footnote) {
          updatedInstructions.append(footnote)
        }
      }
      
      recipe.instructions = updatedInstructions
    }
    
    return recipe
  }
  
  // Main function to reconstruct recipe text from an array of lines
  static func reconstructRecipe(from lines: [String]) -> ReconstructedRecipe {
    var recipe = ReconstructedRecipe()
    recipe.rawText = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    var currentSection = "unknown"
    var currentParagraph: [String] = []
    var inInstructionSection = false
    
    var i = 0
    while i < lines.count {
      var line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
      
      // Skip empty lines
      if line.isEmpty {
        i += 1
        continue
      }
      
      // Skip page numbers or headers at the bottom
      if i > lines.count - 3 && (line.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil ||
                                 isPageHeader(line)) {
        i += 1
        continue
      }
      
      // Identify title (usually at the top, shorter line)
      if i < 5 && recipe.title.isEmpty && line.split(separator: " ").count <= 5 && !isAllLowercase(line) {
        recipe.title = line
        currentSection = "description"
        i += 1
        continue
      }
      
      // Identify start of numbered instructions
      if line.matches(regex: "^1\\.\\s") {
        inInstructionSection = true
        currentSection = "instructions"
        if !currentParagraph.isEmpty {
          recipe.description += currentParagraph.joined(separator: " ")
          currentParagraph = []
        }
        currentParagraph = [line]
        i += 1
        continue
      }
      
      // Continue with numbered instructions
      if inInstructionSection && line.matches(regex: "^\\d+\\.\\s") {
        if !currentParagraph.isEmpty {
          recipe.instructions.append(currentParagraph.joined(separator: " "))
          currentParagraph = [line]
        } else {
          currentParagraph = [line]
        }
        i += 1
        continue
      }
      
      // Handle footnotes (lines starting with asterisk)
      if line.hasPrefix("*") {
        recipe.footnotes.append(line)
        i += 1
        continue
      }
      
      // Handle notes (usually after instructions, starting with "Note:")
      if line.hasPrefix("Note:") {
        recipe.notes.append(line)
        i += 1
        continue
      }
      
      // Identify serving info (usually at the end of instructions)
      if let servingMatch = line.range(of: "Serves\\s+\\d+[-\\s]?\\d*", options: .regularExpression) {
        recipe.servingInfo = String(line[servingMatch])
        // Remove serving info from line if there's other content
        line = line.replacingOccurrences(of: recipe.servingInfo, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If line is now empty, advance counter
        if line.isEmpty {
          i += 1
          continue
        }
        // Otherwise continue processing the line
      }
      
      // Handle continuation of instructions
      if inInstructionSection && !line.matches(regex: "^\\d+\\.\\s") {
        // Check if this line might be an ingredient that got misplaced
        if currentParagraph.isEmpty || !line.matches(regex: "^([\\d¼½¾⅓⅔]+\\s*[\\w\\-]+|[\\d¼½¾⅓⅔]+|a\\s+few|a\\s+pinch)") {
          // This is likely continuation of an instruction
          currentParagraph.append(line)
        } else {
          // This might be an ingredient that appears after previous step
          recipe.ingredients.append(line)
        }
        i += 1
        continue
      }
      
      // Handle ingredients (typically before instructions, often with measurements)
      if !inInstructionSection && line.matches(regex: "^([\\d¼½¾⅓⅔]+\\s*[\\w\\-]+|[\\d¼½¾⅓⅔]+|a\\s+few|a\\s+pinch)") {
        if !currentParagraph.isEmpty {
          recipe.description += currentParagraph.joined(separator: " ")
          currentParagraph = []
        }
        currentSection = "ingredients"
        recipe.ingredients.append(line)
        i += 1
        continue
      }
      
      // Handle description text (anything before ingredients/instructions)
      if currentSection == "unknown" || currentSection == "description" {
        currentSection = "description"
        
        // Check if the current line starts a new paragraph
        if !currentParagraph.isEmpty && isFirstLetterUppercase(line) && currentParagraph.last!.hasSuffix(".") {
          recipe.description += currentParagraph.joined(separator: " ") + " "
          currentParagraph = [line]
        } else {
          // Handle hyphenated words at line breaks
          if !currentParagraph.isEmpty && currentParagraph.last!.hasSuffix("-") {
            // Remove hyphen and join with next line without space
            let lastIndex = currentParagraph.count - 1
            let lastLine = currentParagraph[lastIndex]
            currentParagraph[lastIndex] = String(lastLine.dropLast()) + line
          } else {
            currentParagraph.append(line)
          }
        }
        
        i += 1
        continue
      }
      
      // Default case - just advance
      i += 1
    }
    
    // Add the last paragraph if it exists
    if !currentParagraph.isEmpty {
      if currentSection == "description" {
        recipe.description += currentParagraph.joined(separator: " ")
      } else if currentSection == "instructions" {
        recipe.instructions.append(currentParagraph.joined(separator: " "))
      }
    }
    
    // Process ingredients to handle multi-line ingredients
    recipe.ingredients = processIngredients(recipe.ingredients)
    
    return recipe
  }
  
  // Process ingredients to combine multi-line ingredients
  private static func processIngredients(_ ingredients: [String]) -> [String] {
    var processedIngredients: [String] = []
    var currentIngredient: [String] = []
    
    for item in ingredients {
      // Check if this starts with a measurement or looks like a new ingredient
      if item.matches(regex: "^([\\d¼½¾⅓⅔]+\\s*[\\w\\-]+|[\\d¼½¾⅓⅔]+|a\\s+few|a\\s+pinch)") {
        // Save previous ingredient if it exists
        if !currentIngredient.isEmpty {
          processedIngredients.append(currentIngredient.joined(separator: " "))
        }
        // Start new ingredient
        currentIngredient = [item]
      } else {
        // This is a continuation of the previous ingredient
        currentIngredient.append(item)
      }
    }
    
    // Add the last ingredient
    if !currentIngredient.isEmpty {
      processedIngredients.append(currentIngredient.joined(separator: " "))
    }
    
    return processedIngredients
  }
  
  // Utility functions
  private static func isPageHeader(_ text: String) -> Bool {
    return text.matches(regex: "^\\d+\\s+\\w+")
  }
  
  private static func isAllLowercase(_ text: String) -> Bool {
    return text == text.lowercased()
  }
  
  private static func isFirstLetterUppercase(_ text: String) -> Bool {
    guard let firstChar = text.first else { return false }
    return String(firstChar) == String(firstChar).uppercased()
  }
}

// Extension to add regex matching to String
extension String {
  func matches(regex: String) -> Bool {
    return self.range(of: regex, options: .regularExpression) != nil
  }
}
