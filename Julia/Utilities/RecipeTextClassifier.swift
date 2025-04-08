//
//  RecipeTextClassifier.swift
//  Julia
//
//  Created by Robin Willis on 3/1/25.
//

import Foundation
import CoreML
import NaturalLanguage
import SwiftData

/// Represents the type of line in a recipe text
enum RecipeLineType: String, CaseIterable {
  case title = "title"
  case ingredient = "ingredient"
  case instruction = "instruction"
  case serving = "serving"
  case summary = "summary"
  case time = "time"
  case unknown = "unknown"
}

/// Represents a classified line of text from a recipe
struct RecipeTextLine {
  let text: String
  let lineType: RecipeLineType
  let confidence: Double
}

/// Handles classification of recipe text lines using CoreML
class RecipeTextClassifier {
  private var model: NLModel?
  let confidenceThreshold: Double
  
  init(
    confidenceThreshold: Double = 0.65
  ) {
    self.confidenceThreshold = confidenceThreshold
    loadModel()
  }
  
  private func loadModel() {
    do {
      // Load the RecipeClassifier model
      if let modelURL = Bundle.main.url(forResource: "RecipeClassifier", withExtension: "mlmodelc") {
        model = try NLModel(contentsOf: modelURL)
      } else {
        print("Error: RecipeClassifier.mlmodelc not found in bundle")
      }
    } catch {
      print("Error loading RecipeClassifier model: \(error)")
    }
  }
  
  /// Classifies a single line of text from a recipe
  /// - Parameter text: The line of text to classify
  /// - Returns: The classified RecipeTextLine with type and confidence
  func classifyLine(_ text: String) -> RecipeTextLine {
    guard let model = model else {
      return RecipeTextLine(text: text, lineType: .unknown, confidence: 0.0)
    }
    
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedText.isEmpty {
      return RecipeTextLine(text: text, lineType: .unknown, confidence: 1.0)
    }
    
    // Get the predicted label and convert to RecipeLineType
    let predictedLabel = model.predictedLabel(for: trimmedText) ?? "unknown"
    let lineType = RecipeLineType(rawValue: predictedLabel) ?? .unknown
    
    // Get confidence scores for all labels
    var confidence = 0.5 // Default confidence
    
    // The predictedLabelHypotheses method returns a dictionary of [String: Double]
    let predictions = model.predictedLabelHypotheses(for: trimmedText, maximumCount: 1)
    if let score = predictions[predictedLabel] {
      confidence = score
    }
    
    return RecipeTextLine(text: trimmedText, lineType: lineType, confidence: confidence)
  }
  
  /// Processes a complete recipe text and organizes it into structured data
  /// - Parameter lines: Array of text lines from OCR
  /// - Returns: Structured data for creating a Recipe object
  func processRecipeText(_ lines: [String]) -> (title: String, ingredients: [String], instructions: [String], summary: [String], servings: [String], timings: [String], skipped: [(String, RecipeLineType, Double)], classified: [(String, RecipeLineType, Double)]) {
    var title = "New Recipe"
    var ingredients: [String] = []
    var instructions: [String] = []
    var summary: [String] = []
    var servings: [String] = []
    var timings: [String] = []
    var skippedLines: [(String, RecipeLineType, Double)] = []
    var classifiedLines: [(String, RecipeLineType, Double)] = []
    
    // Process each line
    for line in lines {
      let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmedLine.isEmpty { continue }
      
      let classification = classifyLine(trimmedLine)
      
      // Track all classified lines
      classifiedLines.append((trimmedLine, classification.lineType, classification.confidence))
      
      // Only include lines that meet the confidence threshold
      if classification.confidence >= confidenceThreshold {
        switch classification.lineType {
        case .title:
          if title == "New Recipe" { // Only set title if not already set
            title = trimmedLine
          }
        case .ingredient:
          ingredients.append(trimmedLine)
        case .instruction:
          instructions.append(trimmedLine)
        case .summary:
          summary.append(trimmedLine)
        case .time:
          timings.append(trimmedLine)
        case .serving:
          servings.append(trimmedLine)
        case .unknown:
          // Skip unknown lines
          skippedLines.append((trimmedLine, classification.lineType, classification.confidence))
          break
        }
      } else {
        // Lines below confidence threshold are ignored
        skippedLines.append((trimmedLine, classification.lineType, classification.confidence))
        print("Skipping low confidence line: \(trimmedLine) (\(classification.lineType), \(classification.confidence))")
      }
    }
    
    return (title, ingredients, instructions, summary, timings, servings, skippedLines, classifiedLines)
  }
  
  /// Converts the processed text directly into a Recipe object
  /// - Parameters:
  ///   - lines: Array of text lines from OCR
  ///   - context: SwiftData model context
  /// - Returns: A Recipe object populated with the structured data
  func createRecipeFromText(_ lines: [String], context: ModelContext) -> Recipe {
    let processed = processRecipeText(lines)
    
    // Create the recipe
    let recipe = Recipe(
      title: processed.title,
      summary: processed.summary.joined(separator: " "),
      ingredients: [],
      instructions: [],
      sections: [],
      rawText: lines
    )
    
    // Create ingredients and add them to the recipe
    for ingredientText in processed.ingredients {
      if let ingredient = IngredientParser.fromString(input: ingredientText, location: .recipe) {
        recipe.ingredients.append(ingredient)
      }
    }
    
    // Create instructiosn and add them to the recipe
    for instructionText in processed.instructions {
      let step = Step(value: instructionText)
      recipe.instructions.append(step)
    }
    
    // Insert into context
    context.insert(recipe)
    
    return recipe
  }
}
