//
//  GroceriesView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData


struct GroceriesView: View {
  @Binding var showBottomSheet: Bool
  
  @Environment(\.modelContext) var modelContext
  @Query private var ingredients: [Ingredient]
  @ObservedObject private var ingredientManager = IngredientViewModel()
  
  @State private var hasSelection = false
  
  private var selectedIngredients: Set<Ingredient> {
    ingredientManager.selectedIngredients
  }
  
  
  var body: some View {
    NavigationStack {
      ZStack {
        VStack {
          IngredientList(
            ingredients: ingredients,
            ingredientManager: ingredientManager
          )
        }
        .navigationTitle("Groceries")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            HStack {
              
              Button(action: showAddSheet) {
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
                  Button("Move to Pantry", action: moveToPantry)
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
    }
    .onChange(of: selectedIngredients) {
      withAnimation {
        hasSelection = !selectedIngredients.isEmpty
      }
    }
    
  }
  
  private func showAddSheet() {
    print("Button was tapped")
    showBottomSheet = true
  }
  
  func removeIngredients() { // from selection: Ingredient
    
  }
  
  func moveToPantry() {
    
  }
}

#Preview {
  @State var showBottomSheet = false
  return GroceriesView(showBottomSheet: $showBottomSheet)
    .modelContainer(DataController.previewContainer)
  
}

//  return Text("Failed to create container: \(error.localizedDescription)")

