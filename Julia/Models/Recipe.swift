//
//  Recipe.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import Foundation
import SwiftData

@Model
class Recipe: Identifiable, Hashable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var title: String
    var content: String?
    var steps : [String]
    @Relationship var ingredients: [Ingredient]
    
    init(id: String = UUID().uuidString, title: String, content: String? = nil, ingredients: [Ingredient] = [], steps: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.ingredients = ingredients
        self.steps = steps
    }
    
}
