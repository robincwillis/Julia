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
    let recipe = Recipe(
      id: UUID().uuidString,
      title: self.title,
      summary: self.summary.isEmpty ? nil : self.summary.joined(separator: "\n"),
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
  
  // Helper method to parse time strings like "1 hour 15 minutes" or "45 min"
  private func parseTimeString(_ timeString: String) -> (Int, Int) {
    var hours = 0
    var minutes = 0
    
    // Look for hours
    let hourPattern = try! NSRegularExpression(pattern: "(\\d+)\\s*h(our)?s?", options: .caseInsensitive)
    let hourMatches = hourPattern.matches(in: timeString, options: [], range: NSRange(location: 0, length: timeString.utf16.count))
    
    if let match = hourMatches.first, let range = Range(match.range(at: 1), in: timeString) {
      hours = Int(timeString[range]) ?? 0
    }
    
    // Look for minutes
    let minutePattern = try! NSRegularExpression(pattern: "(\\d+)\\s*m(in(ute)?s?)?", options: .caseInsensitive)
    let minuteMatches = minutePattern.matches(in: timeString, options: [], range: NSRange(location: 0, length: timeString.utf16.count))
    
    if let match = minuteMatches.first, let range = Range(match.range(at: 1), in: timeString) {
      minutes = Int(timeString[range]) ?? 0
    }
    
    // If no specific pattern found but it's just a number, assume minutes
    if hours == 0 && minutes == 0 {
      let numberPattern = try! NSRegularExpression(pattern: "(\\d+)", options: [])
      let numberMatches = numberPattern.matches(in: timeString, options: [], range: NSRange(location: 0, length: timeString.utf16.count))
      
      if let match = numberMatches.first, let range = Range(match.range(at: 1), in: timeString) {
        minutes = Int(timeString[range]) ?? 0
      }
    }
    
    return (hours, minutes)
  }
}
