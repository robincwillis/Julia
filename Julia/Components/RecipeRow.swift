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
        ingredients: [],
        instructions: ["Step 1", "Step 2"],
        sections: [],
        servings: 2,
        rawText: ["Sample Recipe", "A sample recipe"]
    )
    return RecipeRow(recipe: recipe)
}
