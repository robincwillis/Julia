//
//  RecipeDetails.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI

struct RecipeDetails: View {
    var recipe: Recipe
    var body: some View {
        ScrollView {
            VStack (alignment: .leading, spacing: 32) {
//                Text(recipe.title)
//                    .font(.largeTitle)
//                    .padding(.bottom, 20)
                
                if let description = recipe.content {
                    Text(description)
                }
                
                Text("Ingredients")
                    .font(.headline)
                    .padding(.bottom, 10)
                
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                  IngredientRow(ingredient: ingredient)
                }
                
                Divider()
                Text("Steps")
                    .font(.headline)
                    .padding(.top, 20)
                
                ForEach(recipe.steps, id: \.self) { step in
                    Text(step)
                        .padding(.bottom, 5)
                }
                Spacer()
            }
            .padding()
            
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

//struct RecipeDetails_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            RecipeDetails(recipe: mockRecipes[0])
//        }
//    }
//}
