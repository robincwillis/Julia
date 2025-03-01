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
    }
}

#Preview {
    let recipe = Recipe(
        title: "Sample Recipe",
        summary: "A sample recipe for preview",
        instructions: ["Step 1", "Step 2"]
    )
    return RecipeRow(recipe: recipe)
}
