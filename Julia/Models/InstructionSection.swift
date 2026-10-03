//
//  InstructionSection.swift
//  Julia
//

import Foundation
import SwiftData

@Model
final class InstructionSection: Identifiable, Hashable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var name: String
    var position: Int
    @Relationship(deleteRule: .cascade) var steps: [Step] = []
    @Relationship(originalName: "instructionSections") var recipe: Recipe?

    init(id: String = UUID().uuidString, name: String, position: Int = 0, steps: [Step] = [], recipe: Recipe? = nil) {
        self.id = id
        self.name = name
        self.position = position
        self.steps = steps
        self.recipe = recipe
    }

    var sortedSteps: [Step] {
        return steps.sorted { $0.position < $1.position }
    }
}
