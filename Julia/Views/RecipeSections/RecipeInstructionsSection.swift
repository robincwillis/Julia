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
        .foregroundColor(Color.app.textPrimary)
        .padding(.bottom, 8)
      if recipe.instructions.isEmpty {
        Text("No instructions available")
          .foregroundColor(Color.app.textLabel)
          .padding(.vertical, 8)
      } else {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(Array(recipe.instructions.enumerated()), id: \.element) { index, step in
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              // Step number - Primary button style
              ZStack {
                Circle()
                  .fill(.blue)
                  .frame(width: 30, height: 30)
                Text("\(index + 1)")
                  .font(.subheadline)
                  .foregroundColor(.white)
              }
              Text(step.value)
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
  Previews.recipeComponent { recipe in
    RecipeInstructionsSection( recipe: recipe)
      .padding()
  }

}
