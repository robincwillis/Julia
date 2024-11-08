//
//  RecipeList.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData

struct RecipeList: View {
    let recipes: [Recipe]
    var body: some View {

            List(recipes, id: \.id) { recipe in
              
                NavigationLink {
                    RecipeDetails(recipe: recipe)
                } label: {
                    RecipeRow(recipe: recipe)
                }
            }
        
    }
}

#Preview {
    let container = DataController.previewContainer
    let fetchDescriptor = FetchDescriptor<Recipe>()
    let recipes = try! container.mainContext.fetch(fetchDescriptor)
    return RecipeList(recipes: recipes)
}
