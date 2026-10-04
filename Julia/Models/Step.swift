//
//  Step.swift
//  Julia
//
//  Created by Robin Willis on 4/5/25.
//

import Foundation
import SwiftData

@Model
class Step: Identifiable {
  @Attribute(.unique) var id: String = UUID().uuidString
  var value: String
  var position: Int = 0  // Add position property to maintain order
  @Relationship(originalName: "instructions") var recipe: Recipe?
  @Relationship var section: InstructionSection?

  init(
    id: String = UUID().uuidString,
    value: String = "",
    position: Int = 0,
    recipe: Recipe? = nil,
    section: InstructionSection? = nil
  ) {
    self.id = id
    self.value = value
    self.position = position
    self.recipe = recipe
    self.section = section
  }
}

