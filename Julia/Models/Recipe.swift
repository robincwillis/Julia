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
    var instructions : [String]
    @Relationship var ingredients: [Ingredient]
    // TODO: Ingredient Sections
    var rawText : [String]?
  
    init(id: String = UUID().uuidString, title: String, summary: String? = nil, ingredients: [Ingredient] = [], instructions: [String] = [], rawText: [String] = []) {
        self.id = id
        self.title = title
        self.summary = summary
        self.ingredients = ingredients
        self.instructions = instructions
        self.rawText = rawText
    }
  
  var description: String {
    return "Recipe(id: \(id), title: \(title), rawText: \(rawText)"
  }
    }
