//
//  Recipe.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import Foundation
import SwiftData

@Model
class Recipe: Identifiable, Hashable, CustomStringConvertible {
    @Attribute(.unique) var id: String = UUID().uuidString
    var title: String
    var summary: String?
    var servings: Int?
    var instructions : [String]
    var notes: [String]?
    
    // Meta
    var rawText: [String]?
    var source: String?
  
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient] = []
    @Relationship(deleteRule: .cascade) var sections: [IngredientSection] = []
    @Relationship(deleteRule: .cascade) var timings: [Timing] = []
  
    init(
      id: String = UUID().uuidString,
      title: String,
      summary: String? = nil,
      ingredients: [Ingredient] = [],
      instructions: [String] = [],
      sections: [IngredientSection] = [],
      servings: Int? = nil,
      timings: [Timing] = [],
      notes: [String]? = nil,
      rawText: [String] = [],
      source: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.ingredients = ingredients
        self.instructions = instructions
        self.sections = sections
        self.servings = servings
        self.timings = timings
        self.notes = notes
        self.rawText = rawText
        self.source = source
    }
  
    var description: String {
        return "Recipe(id: \(id), title: \(title), rawText: \(String(describing: rawText))"
    }
    
    // Helper method to add a new section
    func addSection(name: String) -> IngredientSection {
        let newSection = IngredientSection(name: name, position: sections.count)
        sections.append(newSection)
        return newSection
    }
    
    // Helper method to get all ingredients (both sectioned and unsectioned)
    var allIngredients: [Ingredient] {
        var allIngredients = ingredients
        for section in sections {
            allIngredients.append(contentsOf: section.ingredients)
        }
        return allIngredients
    }
    
    // Get ingredients sorted by position
    var sortedIngredients: [Ingredient] {
        return ingredients.sorted { $0.position < $1.position }
    }
    
    // Helper method to move an ingredient to a section
    func moveIngredient(_ ingredient: Ingredient, toSection section: IngredientSection?) {
        // First remove the ingredient from its current location
        if let currentSection = ingredient.section {
            if let index = currentSection.ingredients.firstIndex(of: ingredient) {
                currentSection.ingredients.remove(at: index)
            }
        } else {
            if let index = ingredients.firstIndex(of: ingredient) {
                ingredients.remove(at: index)
            }
        }
        
        // Now add to the new section or to unsectioned ingredients
        if let newSection = section {
            ingredient.section = newSection
            newSection.ingredients.append(ingredient)
        } else {
            ingredient.section = nil
            ingredients.append(ingredient)
        }
    }
}
