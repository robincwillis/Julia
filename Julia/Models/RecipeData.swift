//
//  RecipeData.swift
//  Julia
//
//  Created by Robin Willis on 4/7/25.
//

import Foundation

// Centralize all recipe data in a single struct for easier management


struct RecipeData: Equatable {
  var id: String = UUID().uuidString 
  var title: String = ""
  var summary: [String] = []
  var timings: [String] = []
  var servings: [String] = []
  
  var ingredients: [String] = []
  var instructions: [String] = []
  var sections: [String] = []

  var rawText: [String] = []
  var notes: [String] = []

  var reconstructedText = ProcessingTextResult(title: "", reconstructedLines: [], artifacts: [])
  var classifiedLines: [(String, RecipeLineType, Double)] = []
  var skippedLines: [(String, RecipeLineType, Double)] = []

  var source: String? = nil
  var sourceType: String?  = nil
  var sourceTitle: String? = nil
  var author: String? = nil
  var website: String? = nil

  static func == (lhs: RecipeData, rhs: RecipeData) -> Bool {
    // Compare relevant properties
    return lhs.id == rhs.id // or whatever comparison makes sense
  }
  
  mutating func reset() {
    title = ""
    ingredients = []
    instructions = []
    summary = []
    timings = []
    servings = []
    notes = []
    source = nil
    sourceType = nil
    sourceTitle = nil
    website = nil
    author = nil
    reconstructedText = ProcessingTextResult(title: "", reconstructedLines: [], artifacts: [])
    classifiedLines = []
    skippedLines = []
  }
  
  // Convert extracted data to your SwiftData Recipe model
  public func convertToSwiftDataModel() -> Recipe {
    // Create basic Recipe object
    let summaryLines = self.summary.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    let recipe = Recipe(
      id: UUID().uuidString,
      title: self.title,
      summary: summaryLines.isEmpty ? nil : summaryLines.joined(separator: "\n"),
      ingredients: [], // Will populate below
      instructions: [],
      sections: [],
      servings: self.servings.isEmpty ? nil : Int(self.servings.first ?? ""),
      timings: [],
      notes: [],
      tags: [],
      rawText: self.rawText,
      source: self.source,
      sourceType: self.sourceType != nil ? SourceType(rawValue: self.sourceType!) : nil,
      sourceTitle: self.sourceTitle,
      website: self.website,
      author: self.author
    )

    // Create Ingredient objects for each ingredient string
    for ingredientText in self.ingredients {
      if let ingredient = IngredientParser.fromString(input: ingredientText, location: .recipe) {
        recipe.ingredients.append(ingredient)
      }
    }
    
    // Create step objects for each instruction string
    for instructionText in self.instructions {
      let step = Step(value: instructionText)
      recipe.instructions.append(step)
    }
    
    // Add timing objects
    for timingText in self.timings {
      // Parse timing text - format expected: "type: Xh Ymin" or similar
      let parts = timingText.components(separatedBy: ":")
      if parts.count >= 2 {
        let type = parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let timeValue = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        let (hours, minutes) = parseTimeString(timeValue)
        let timing = Timing(type: type, hours: hours, minutes: minutes)
        recipe.timings.append(timing)
      }
    }
    
    // Add notes
    for noteText in self.notes {
      let note = Note(text: noteText)
      recipe.notes.append(note)
    }
    
    // Create sections if needed
    if !self.sections.isEmpty {
      for (index, sectionName) in self.sections.enumerated() {
        let section = IngredientSection(
          name: sectionName,
          position: index
        )
        recipe.sections.append(section)
      }
    }
    
    return recipe
  }
  
  /// Async version that uses Foundation Models for richer ingredient parsing.
  public func convertToSwiftDataModelAsync() async -> Recipe {
    let summaryLinesAsync = self.summary.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    let recipe = Recipe(
      id: UUID().uuidString,
      title: self.title,
      summary: summaryLinesAsync.isEmpty ? nil : summaryLinesAsync.joined(separator: "\n"),
      ingredients: [],
      instructions: [],
      sections: [],
      servings: self.servings.isEmpty ? nil : Int(self.servings.first ?? ""),
      timings: [],
      notes: [],
      tags: [],
      rawText: self.rawText,
      source: self.source,
      sourceType: self.sourceType != nil ? SourceType(rawValue: self.sourceType!) : nil,
      sourceTitle: self.sourceTitle,
      website: self.website,
      author: self.author
    )

    for ingredientText in self.ingredients {
      if let ingredient = await IngredientParser.fromStringAsync(input: ingredientText, location: .recipe) {
        recipe.ingredients.append(ingredient)
      }
    }

    for instructionText in self.instructions {
      let step = Step(value: instructionText)
      recipe.instructions.append(step)
    }

    for timingText in self.timings {
      let parts = timingText.components(separatedBy: ":")
      if parts.count >= 2 {
        let type = parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let timeValue = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let (hours, minutes) = parseTimeString(timeValue)
        recipe.timings.append(Timing(type: type, hours: hours, minutes: minutes))
      }
    }

    for noteText in self.notes {
      recipe.notes.append(Note(text: noteText))
    }

    for (index, sectionName) in self.sections.enumerated() {
      recipe.sections.append(IngredientSection(name: sectionName, position: index))
    }

    return recipe
  }

  // Time-string patterns. Compiled once as statics rather than force-tried on
  // every call: these are literals that cannot fail at runtime, so `try!` was
  // both a needless crash risk and needless work per invocation.
  private static let hourPattern = try? NSRegularExpression(
    pattern: "(\\d+)\\s*h(our)?s?", options: .caseInsensitive
  )
  private static let minutePattern = try? NSRegularExpression(
    pattern: "(\\d+)\\s*m(in(ute)?s?)?", options: .caseInsensitive
  )
  private static let numberPattern = try? NSRegularExpression(
    pattern: "(\\d+)", options: []
  )

  /// First capture group of `pattern` in `text`, as an Int.
  private func firstNumber(_ pattern: NSRegularExpression?, in text: String) -> Int? {
    guard let pattern else { return nil }
    let range = NSRange(location: 0, length: text.utf16.count)
    guard let match = pattern.matches(in: text, options: [], range: range).first,
          let captured = Range(match.range(at: 1), in: text)
    else { return nil }
    return Int(text[captured])
  }

  // Helper method to parse time strings like "1 hour 15 minutes" or "45 min"
  private func parseTimeString(_ timeString: String) -> (Int, Int) {
    let hours = firstNumber(Self.hourPattern, in: timeString) ?? 0
    var minutes = firstNumber(Self.minutePattern, in: timeString) ?? 0

    // No unit found, but a bare number — assume minutes.
    if hours == 0 && minutes == 0 {
      minutes = firstNumber(Self.numberPattern, in: timeString) ?? 0
    }

    return (hours, minutes)
  }
}
