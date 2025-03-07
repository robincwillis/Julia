//
//  RecipeInstructionsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI
struct RecipeInstructionsSection: View {
  let recipe: Recipe
  
  var body: some View {
    if recipe.instructions.isEmpty {
      Text("No instructions available")
        .foregroundColor(.gray)
        .padding(.vertical, 8)
    } else {
      VStack(spacing: 6) {
        ForEach(Array(recipe.instructions.enumerated()), id: \.element) { index, step in
        HStack(alignment: .center, spacing: 6) {
          // Step number - Primary button style
          Text("\(index + 1)")
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(8)
            .background(Circle().fill(Color.blue))
            .frame(minWidth: 40)
          Text(step)
            .foregroundColor(.black)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    var body: some View {
        RecipeInstructionsSection(
          recipe: Recipe(
            title: "Sample Recipe",
            summary: "A delicious sample recipe",
            ingredients: [],
            instructions: ["Step 1", "Step 2"]
          )
        )
      }
    }
  return PreviewWrapper()
}
