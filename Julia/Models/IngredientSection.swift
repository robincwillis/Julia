//
//  IngredientSection.swift
//  Julia
//
//  Created by Robin Willis on 2/28/25.
//

import Foundation
import SwiftData

@Model
final class IngredientSection: Identifiable, Hashable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var name: String
    var position: Int
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient] = []
    @Relationship(originalName: "sections") var recipe: Recipe?
    
    init(id: String = UUID().uuidString, name: String, position: Int = 0, ingredients: [Ingredient] = [], recipe: Recipe? = nil) {
        self.id = id
        self.name = name
        self.position = position
        self.ingredients = ingredients
        self.recipe = recipe
    }
    
    // Get ingredients sorted by position
    var sortedIngredients: [Ingredient] {
        return ingredients.sorted { $0.position < $1.position }
    }
}