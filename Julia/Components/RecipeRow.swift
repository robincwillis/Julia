//
//  RecipeRow.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI

struct RecipeRow: View {
    let recipe: Recipe
    var body: some View {
        Text("\(recipe.title)")
        .lineLimit(1)
        .truncationMode(.tail)
        .foregroundColor(Color.app.textPrimary)
    }
}

#Preview("Recipe Row") {
  Previews.recipeComponent { recipe in
    RecipeRow(recipe: recipe)
  }
}
