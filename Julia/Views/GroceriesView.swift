//
//  GroceriesView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData


struct GroceriesView: View {
  //@ObservedObject var viewModel: GroceriesViewModel
  @Environment(\.modelContext) var modelContext
  @Query private var ingredients: [Ingredient]
  
  @Binding var showSheet: Bool
  
  @State private var ingredientName = ""
  @State private var selectedIngredients: [Ingredient] = []
  
  
  
  var body: some View {
    NavigationStack {
      ZStack {
        VStack {
          IngredientList(ingredients: ingredients, onSelect: addIngredient, onDeselect: removeIngredient)
        }
        .navigationTitle("Groceries")
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
        
      }
    }
    
  }
  
  private func showAddSheet() {
    print("Button was tapped")
    showSheet = true
  }
  
  func addItem() {
    guard !ingredientName.isEmpty else { return }
    let ingredient = Ingredient(name: ingredientName)
    //viewModel.addIngredient(ingredient: ingredient)
    showSheet = false
    ingredientName = ""
  }
  func addIngredient(to selection: Ingredient ) { 
    
  }
  func removeIngredient(from selection: Ingredient) {
    
  }
}

//struct GroceriesView_Previews: PreviewProvider {
//  static var previews: some View {
//    let viewModel = GroceriesViewModel(forPreview: true)
//  }
//}


#Preview {
  do {
    @State var showSheet = false
    return GroceriesView(showSheet: $showSheet)
      .modelContainer(DataController.previewContainer)
  } catch {
    return Text("Failed to create container: \(error.localizedDescription)")
  }
}
