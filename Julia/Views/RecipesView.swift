//
//  RecipesView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData

struct RecipesView: View {
  @Environment(\.modelContext) var modelContext
  @Query private var recipes: [Recipe]
  @State var showSheet = false
  
//  var body: some View {
//    Text("Hello")
//    List {
//      ForEach(recipes) { recipe in
//        Text("\(recipe.title)")
//        ForEach(recipe.ingredients) { ingredient in
//          Text("\(ingredient.name)")
//        }
//      }
//    }
//  }
  
  var body: some View {
    NavigationSplitView {
      VStack {
        RecipeList(recipes: recipes)
      }
      .navigationTitle("Recipes")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        Button(action: showAddSheet) {
          Image(systemName: "plus")
            .foregroundColor(.blue)
            .frame(width: 40, height: 40)
            .background(.tertiary)
            .clipShape(Circle())
        }
      }
      
    } detail: {
      Text("Select a Recipe")
    }
  }
  
  private func showAddSheet() {
    print(recipes)
    
    print("Button was tapped")
    showSheet = true
  }
}

#Preview {
  RecipesView()
    .modelContainer(DataController.previewContainer)
  
}
