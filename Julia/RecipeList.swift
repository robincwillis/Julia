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
        List {
            ForEach(recipes, id: \.id) { recipe in
                NavigationLink {
                    RecipeDetails(recipe: recipe)
                } label: {
                    RecipeRow(recipe: recipe)
                }
            }
            
            // Add spacer at the end for tab bar
            Section {
                Color.clear
                    .frame(height: 90) // Height of tab bar + extra padding
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    let container = DataController.previewContainer
    let fetchDescriptor = FetchDescriptor<Recipe>()
    let recipes = try! container.mainContext.fetch(fetchDescriptor)
    return RecipeList(recipes: recipes)
}
