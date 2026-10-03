//
//  Recipe.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import Foundation
import SwiftData

enum RecipeFocusedField: Hashable {
  case none
  case title
  case summary
  case timings
  case servings
  case rawText
  case ingredientName(String) // can include IDs if needed
  case ingredientQuantity(String)
  case instruction(String) // id of the instruction
  case note(String) // id of the instruction
}

extension RecipeFocusedField {
  var needsDoneButton: Bool {
    switch self {
    case .servings, .summary, .instruction, .rawText, .note:
      return true
    default:
      return false
    }
  }
}


enum SourceType: String, Codable, CaseIterable {
  case photo = "photo"
  case website = "website"
  case book = "book"
  case manual = "manual"
  case unknown = "unknown"
  
  var displayName: String {
    switch self {
    case .photo: return "Photo"
    case .website: return "Website"
    case .book: return "Book/Publication"
    case .manual: return "Manually Entered"
    case .unknown: return "Unknown"
    }
  }
}


@Model
class Recipe: Identifiable, Hashable, CustomStringConvertible {
    @Attribute(.unique) var id: String = UUID().uuidString
    var title: String
    var summary: String?
    var servings: Int?


  
    var tags: [String]
    var rawText: [String]?
    var source: String?
    var sourceType: SourceType?
    var sourceTitle: String?
    var website: String?
    var author: String?
    
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient] = []
    @Relationship(deleteRule: .cascade) var sections: [IngredientSection] = []
    @Relationship(deleteRule: .cascade) var timings: [Timing] = []
    @Relationship(deleteRule: .cascade) var instructions: [Step] = []
    @Relationship(deleteRule: .cascade) var instructionSections: [InstructionSection] = []
    @Relationship(deleteRule: .cascade) var notes: [Note] = []
    @Relationship(deleteRule: .cascade) var images: [ImageItem] = []

    init(
      id: String = UUID().uuidString,
      title: String,
      summary: String? = nil,
      ingredients: [Ingredient] = [],
      instructions: [Step] = [],
      sections: [IngredientSection] = [],
      instructionSections: [InstructionSection] = [],
      servings: Int? = nil,
      timings: [Timing] = [],
      notes: [Note] = [],
      tags: [String] = [],
      rawText: [String] = [],
      source: String? = nil,
      sourceType: SourceType? = nil,
      sourceTitle: String? = nil,
      website: String? = nil,
      author: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.ingredients = ingredients
        self.instructions = instructions
        self.sections = sections
        self.instructionSections = instructionSections
        self.servings = servings
        self.timings = timings
        self.notes = notes
        self.tags = tags
        self.rawText = rawText
        self.source = source
        self.sourceType = sourceType
        self.sourceTitle = sourceTitle
        self.website = website
        self.author = author
    }
  
    var description: String {
        return "Recipe(id: \(id), title: \(title), rawText: \(String(describing: rawText))"
    }
    
    func addSection(name: String) -> IngredientSection {
        let newSection = IngredientSection(name: name, position: sections.count)
        sections.append(newSection)
        return newSection
    }

    func addInstructionSection(name: String) -> InstructionSection {
        let newSection = InstructionSection(name: name, position: instructionSections.count)
        instructionSections.append(newSection)
        return newSection
    }

    var allIngredients: [Ingredient] {
        var allIngredients = ingredients
        for section in sections {
            allIngredients.append(contentsOf: section.ingredients)
        }
        return allIngredients
    }

    var sortedIngredients: [Ingredient] {
        return ingredients.sorted { $0.position < $1.position }
    }

    func moveIngredient(_ ingredient: Ingredient, toSection section: IngredientSection?) {
        if let currentSection = ingredient.section {
            if let index = currentSection.ingredients.firstIndex(of: ingredient) {
                currentSection.ingredients.remove(at: index)
            }
        } else {
            if let index = ingredients.firstIndex(of: ingredient) {
                ingredients.remove(at: index)
            }
        }

        if let newSection = section {
            ingredient.section = newSection
            newSection.ingredients.append(ingredient)
        } else {
            ingredient.section = nil
            ingredients.append(ingredient)
        }
    }

    var allInstructions: [Step] {
        var all = instructions
        for section in instructionSections {
            all.append(contentsOf: section.steps)
        }
        return all
    }

    var sortedInstructions: [Step] {
        return instructions.sorted { $0.position < $1.position }
    }

    func moveStep(_ step: Step, toSection section: InstructionSection?) {
        if let currentSection = step.section {
            if let index = currentSection.steps.firstIndex(of: step) {
                currentSection.steps.remove(at: index)
            }
        } else {
            if let index = instructions.firstIndex(of: step) {
                instructions.remove(at: index)
            }
        }

        if let newSection = section {
            step.section = newSection
            newSection.steps.append(step)
        } else {
            step.section = nil
            instructions.append(step)
        }
    }
}
