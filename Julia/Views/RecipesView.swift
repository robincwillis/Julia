//
//  RecipesView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData

struct RecipesView: View {
  @Environment(\.modelContext) var context
  @Query private var recipes: [Recipe]
  @State var showAddSheet = false
  
  var body: some View {
    NavigationSplitView {
      VStack {
        RecipeList(recipes: recipes)
      }
      .navigationTitle("Recipes")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        Button(action: {
          showAddSheet.toggle()
        }) {
          Image(systemName: "plus")
            .foregroundColor(.blue)
            .frame(width: 40, height: 40)
            .background(Color(red: 0.85, green: 0.92, blue: 1.0))
            .clipShape(Circle())
        }
      
        
      }
      .sheet(isPresented: $showAddSheet) {
        AddRecipe()
      }
      
    } detail: {
      Text("Select a Recipe")
    }
  }
  
}

#Preview {
    RecipesView()
        .modelContainer(DataController.previewContainer)
}



