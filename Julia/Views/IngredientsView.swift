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
  
  @Binding var showBottomSheet: Bool

  // Manage all Ingredient View State here
  @StateObject private var ingredientManager = IngredientViewModel()
  @State private var hasSelection = false

  private var selectedIngredients: Set<Ingredient> {
    ingredientManager.selectedIngredients
  }

  
  var body: some View {
    NavigationStack {
      VStack {
        IngredientList(
          ingredients: ingredients,
          ingredientManager: ingredientManager
        )
      }
      .navigationTitle("Ingredients")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          HStack {
            Button {
              showAddSheet()
            } label : {
              Image(systemName: "plus")
                .foregroundColor(.white)
              
                .frame(width: 40, height: 40)
                .background(.blue)
                .clipShape(Circle())
                .animation(.snappy, value: hasSelection)
                .transition(.move(edge: .leading))
            }
            if hasSelection {
              Menu {
                Button("Remove Ingredients", action: removeIngredients)
                Button("Move to Groceries", action: moveToGroceries)
              } label: {
                Image(systemName: "ellipsis")
                  .rotationEffect(.degrees(90))
                  .foregroundColor(.blue)
                  .frame(width: 40, height: 40)
                  .background(.tertiary)
                  .clipShape(Circle())
                  .animation(.snappy, value: hasSelection)
                  .transition(.opacity)
              }
            }
          }
        }
      }
      
    }
    .onChange(of: selectedIngredients) {
      withAnimation {
        hasSelection = !selectedIngredients.isEmpty
      }
    }
    
  }
  
  
  func showAddSheet() {
    showBottomSheet = true
  }
  
  func moveToGroceries() {
  }
  
  func removeIngredients() {
    print("remove these ingredients \(ingredientManager.selectedIngredients)");
    
    
  }
  
}

#Preview {
  @State var showBottomSheet = false
  return IngredientsView(showBottomSheet: $showBottomSheet)
      .modelContainer(DataController.previewContainer)
}
