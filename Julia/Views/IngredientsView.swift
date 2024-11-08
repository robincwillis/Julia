//
//  IngredientsView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData

struct IngredientsView: View {
  @Environment(\.modelContext) var modelContext
  @Query private var ingredients: [Ingredient]
    
  @State private var selectedIngredients: [Ingredient] = []
  
  var body: some View {
    NavigationStack {
      VStack {
        IngredientList(ingredients: ingredients, onSelect: self.selectIngredient, onDeselect: self.deselectIngredient)
      }
      .navigationTitle("Ingredients")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        Button {
          
        } label : {
          Image(systemName: "plus")
        }
        Menu {
          Button("Remove Ingredient", action: removeIngredients)
          Button("Add Ingredient", action: addIngredient)
          Button("Move to Groceries", action: moveToGroceries)
        } label: {
          Image(systemName: "ellipsis")
            .rotationEffect(.degrees(90))
        }
      }
    }
    
  }
  
  private func selectIngredient(ingredient: Ingredient) {
    
  }
  
  private func deselectIngredient(ingredient: Ingredient) {
    
  }
  
  func addIngredient() {
  }
  
  func moveToGroceries() {
    print("Button was tapped")
  }
  
  func removeIngredients() {
    
  }
  
}

#Preview {
  do {
    return IngredientsView()
      .modelContainer(DataController.previewContainer)
  } catch {
    return Text("Failed to create container: \(error.localizedDescription)")
  }
}
