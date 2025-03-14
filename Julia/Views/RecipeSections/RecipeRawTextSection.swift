//
//  RecipeRawTextSection.swift
//  Julia
//
//  Created by Claude on 3/2/25.
//

import SwiftUI

struct RecipeRawTextSection: View {
  let recipe: Recipe
  
  var rawTextString: String {
    recipe.rawText?.joined(separator: "\n") ?? ""
  }
  
  var body: some View {
    
    VStack(alignment: .leading, spacing: 8) {
      ForEach(recipe.rawText ?? [], id: \.self) { item in
        Text(item)
      }
      .font(.system(size: 12, design: .monospaced))
    }
    .frame(maxWidth: .infinity)
    .padding(6)
    .foregroundColor(.secondary)
    .background(.background.secondary)
    .navigationTitle("Recognized Text")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Copy") {
          UIPasteboard.general.string = rawTextString
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(red: 0.85, green: 0.92, blue: 1.0))
        .cornerRadius(8)
      }
      
    }
}
}

#Preview {
  RecipeRawTextSection(
    recipe: Recipe(
      title: "Sample Recipe",
      summary: "A delicious sample recipe",
      ingredients: [],
      instructions: [],
      rawText: ["Line 1: Sample recipe text", "Line 2: More sample text", "Line 3: Final line of text"]
    )
  )
  .padding()
}
