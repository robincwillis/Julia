
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
  case section_title = "section_title"  // New: Section headers like "For the sauce:"
  case note = "note"                    // New: Notes and tips
  case source = "source"                // New: Source attribution
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
  func processRecipeText(_ lines: [String]) -> (
    title: String,
    ingredients: [String],
    instructions: [String],
    summary: [String],
    servings: [String],
    timings: [String],
    sectionTitles: [String],
    notes: [String],
    source: [String],
    skipped: [(String, RecipeLineType, Double)],
    classified: [(String, RecipeLineType, Double)]
  ) {
    var title = "New Recipe"
    var ingredients: [String] = []
    var instructions: [String] = []
    var summary: [String] = []
    var servings: [String] = []
    var timings: [String] = []
    var sectionTitles: [String] = []
    var notes: [String] = []
    var source: [String] = []
    var skippedLines: [(String, RecipeLineType, Double)] = []
    var classifiedLines: [(String, RecipeLineType, Double)] = []
    
    // Find the most confident title
    var bestTitleConfidence = 0.0
    
    // First pass: classify all lines and find the best title candidate
    for line in lines {
      let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmedLine.isEmpty { continue }
      
      let classification = classifyLine(trimmedLine)
      
      // Track all classified lines
      classifiedLines.append((trimmedLine, classification.lineType, classification.confidence))
      
      // Check if this is the most confident title we've seen
      if classification.lineType == .title && classification.confidence > bestTitleConfidence {
        bestTitleConfidence = classification.confidence
        if classification.confidence >= confidenceThreshold {
          title = trimmedLine
        }
      }
    }
    
    // Second pass: process all lines except for the one we identified as the title
    for (line, lineType, confidence) in classifiedLines {
      // Skip the title line we already processed
      if lineType == .title && line == title && confidence == bestTitleConfidence {
        continue
      }
      
      // Only include lines that meet the confidence threshold
      if confidence >= confidenceThreshold {
        switch lineType {
        case .title:
          // If it's not our best title but still a title, add it to summary
          summary.append(line)
        case .ingredient:
          ingredients.append(line)
        case .instruction:
          instructions.append(line)
        case .summary:
          summary.append(line)
        case .time:
          timings.append(line)
        case .serving:
          servings.append(line)
        case .section_title:
          sectionTitles.append(line)
        case .note:
          notes.append(line)
        case .source:
          source.append(line)
        case .unknown:
          // Skip unknown lines
          skippedLines.append((line, lineType, confidence))
        }
      } else {
        // Lines below confidence threshold are tracked but not used
        skippedLines.append((line, lineType, confidence))
        print("Skipping low confidence line: \(line) (\(lineType), \(confidence))")
      }
    }
    
    return (title, ingredients, instructions, summary, timings, servings, sectionTitles, notes, source, skippedLines, classifiedLines)
  }
  
  /// Converts the processed text directly into a Recipe object
  /// - Parameters:
  ///   - lines: Array of text lines from OCR
  ///   - context: SwiftData model context
  /// - Returns: A Recipe object populated with the structured data
  func createRecipeFromText(_ lines: [String], context: ModelContext) -> Recipe {
    let processed = processRecipeText(lines)
    
    // Create summary by combining summary texts and notes
    var combinedSummary = processed.summary.joined(separator: " ")
    
    // Add source information to summary if available
    if !processed.source.isEmpty {
      if !combinedSummary.isEmpty {
        combinedSummary += "\n\nSource: " + processed.source.joined(separator: " ")
      } else {
        combinedSummary = "Source: " + processed.source.joined(separator: " ")
      }
    }
    
    // Create the recipe
    let recipe = Recipe(
      title: processed.title,
      summary: combinedSummary.isEmpty ? nil : combinedSummary,
      ingredients: [],
      instructions: [],
      sections: [],
      rawText: lines
    )
    
    // Process sections and ingredients
    var currentSection: IngredientSection? = nil
    var position = 0
    
    // First pass: Create sections
    for sectionTitle in processed.sectionTitles {
      let newSection = IngredientSection(
        name: sectionTitle,
        position: position
      )
      position += 1
      recipe.sections.append(newSection)
    }
    
    // Second pass: Process ingredients and associate with sections when possible
    for ingredientText in processed.ingredients {
      // Try to determine if this ingredient belongs in a section
      let matchedSection = recipe.sections.first { section in
        // Simple heuristic: if the section name is found within the ingredient text
        // or if the ingredient text contains common patterns like "for the sauce"
        return ingredientText.localizedCaseInsensitiveContains(section.name) ||
               (ingredientText.localizedCaseInsensitiveContains("for the") &&
                section.name.localizedCaseInsensitiveContains("for the"))
      }
      
      if let ingredient = IngredientParser.fromString(input: ingredientText, location: .recipe) {
        ingredient.position = position
        position += 1
        
        if let section = matchedSection {
          section.ingredients.append(ingredient)
          ingredient.section = section
        } else {
          recipe.ingredients.append(ingredient)
        }
      }
    }
    
    // Handle instructions, adding position information
    position = 0
    for instructionText in processed.instructions {
      let step = Step(value: instructionText, position: position)
      position += 1
      recipe.instructions.append(step)
    }
    
    // Add notes separately if appropriate for your data model
    if !processed.notes.isEmpty && recipe.summary != nil {
      recipe.summary! += "\n\nNotes: " + processed.notes.joined(separator: "\n")
    } else if !processed.notes.isEmpty {
      recipe.summary = "Notes: " + processed.notes.joined(separator: "\n")
    }
    
    // Insert into context
    context.insert(recipe)
    
    return recipe
  }
}
