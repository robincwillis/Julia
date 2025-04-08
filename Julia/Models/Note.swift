//
//  Note.swift
//  Julia
//
//  Created by Robin Willis on 4/5/25.
//

import Foundation
import SwiftData

@Model
class Note: Identifiable {
  @Attribute(.unique) var id: String = UUID().uuidString
  var text: String
  var position: Int = 0  // Add position property to maintain order
  @Relationship(originalName: "notes") var recipe: Recipe?
  
  init(
    id: String = UUID().uuidString,
    text: String = "",
    position: Int = 0,
    recipe: Recipe? = nil
  ) {
    self.id = id
    self.text = text
    self.position = position
    self.recipe = recipe
  }
}
