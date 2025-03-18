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
    VStack(alignment: .leading, spacing: 8) {
      Text("Instructions")
        .font(.headline)
        .foregroundColor(.primary)
        .padding(.bottom, 8)
      if recipe.instructions.isEmpty {
        Text("No instructions available")
          .foregroundColor(.gray)
          .padding(.vertical, 8)
      } else {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(Array(recipe.instructions.enumerated()), id: \.element) { index, step in
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              // Step number - Primary button style
              ZStack {
                Circle()
                  .fill(Color(red: 0.85, green: 0.92, blue: 1.0))
                  .frame(width: 40, height: 40)
                Text("\(index + 1)")
                  .font(.subheadline)
                  .foregroundColor(.blue)
              }
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
