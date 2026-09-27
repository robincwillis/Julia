//
//  RecipeInstructionsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI
struct RecipeInstructionsSection: View {
  let recipe: Recipe

  private var sortedUnsectioned: [Step] {
    recipe.instructions.sorted { $0.position < $1.position }
  }

  private var sortedSections: [InstructionSection] {
    recipe.instructionSections.sorted { $0.position < $1.position }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Instructions")
        .font(.headline)
        .foregroundColor(Color.app.textPrimary)
        .padding(.bottom, 8)
      if recipe.instructions.isEmpty && recipe.instructionSections.isEmpty {
        Text("No instructions available")
          .foregroundColor(Color.app.labelPrimary)
          .padding(.vertical, 8)
      } else {
        VStack(alignment: .leading, spacing: 20) {
          if !sortedUnsectioned.isEmpty {
            stepList(sortedUnsectioned, startingAt: 1)
          }

          ForEach(sortedSections) { section in
            VStack(alignment: .leading, spacing: 12) {
              Text(section.name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.app.textSecondary)

              stepList(section.sortedSteps, startingAt: stepNumberOffset(before: section))
            }
          }
        }
      }
    }
  }

  // MARK: - Helpers

  /// Steps are numbered continuously across the recipe — unsectioned steps
  /// first, then each section in order — rather than restarting at 1 per
  /// section, so "Step 4" still means something when read aloud mid-recipe.
  private func stepNumberOffset(before section: InstructionSection) -> Int {
    var count = sortedUnsectioned.count
    for earlierSection in sortedSections {
      if earlierSection.id == section.id { break }
      count += earlierSection.steps.count
    }
    return count + 1
  }

  private func stepList(_ steps: [Step], startingAt startNumber: Int) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          // Step number - Primary button style
          ZStack {
            Circle()
              .fill(Color.app.secondary)
              .frame(width: 30, height: 30)
            Text("\(startNumber + index)")
              .font(.subheadline)
              .foregroundStyle(.white)
          }
          Text(step.value)
            .foregroundColor(Color.app.textPrimary)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }
}

#Preview {
  Previews.recipeComponent { recipe in
    RecipeInstructionsSection( recipe: recipe)
      .padding()
  }

}
