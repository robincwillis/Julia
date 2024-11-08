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

//struct RecipeRow_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeRow(recipe: mockRecipes[0])
//    }
//}

//#Preview {
//  let mockRecipe = mockRecipes[0]
//  let recipe = Recipe(title: mockRecipe, content: <#T##String?#>, ingredients: <#T##[Ingredient]#>, steps: <#T##[String]#>)
//  RecipeRow()
//}
