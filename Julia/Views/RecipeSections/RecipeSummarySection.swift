//
//  RecipeTitleSection.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI

struct RecipeSummarySection: View {
    let recipe: Recipe
    var body: some View {
      if let summary = recipe.summary {
        Text("Summary")
          .font(.headline)
          .foregroundColor(.gray)
        Text(summary)
          .font(.body)
      }
    }
}


#Preview {
    struct PreviewWrapper: View {
        @State private var title = "Sample Recipe"
        @State private var summary: String? = "A delicious sample recipe"
        @FocusState private var focused: Bool
        
        var body: some View {
            RecipeSummarySection(
                recipe: Recipe(
                    title: "Sample Recipe",
                    summary: "A delicious sample recipe",
                    ingredients: [],
                    instructions: []
                )
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}
