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
    @Relationship(.cascade) var ingredients: [Ingredient] = []
    
    init(id: String = UUID().uuidString, name: String, position: Int = 0, ingredients: [Ingredient] = []) {
        self.id = id
        self.name = name
        self.position = position
        self.ingredients = ingredients
    }
}