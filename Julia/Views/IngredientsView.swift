//
//  IngredientsView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData

struct IngredientsView: View {
  let location: IngredientLocation
  @State private var showBottomSheet = false
  @State private var currentIngredient: Ingredient?

  @Environment(\.modelContext) var context
  @Query() var allIngredients: [Ingredient]

  @State var selectedIngredients: [Ingredient] = []
  @State private var hasSelection = false
  @State private var showingErrorAlert = false
  @State private var errorMessage = ""
  
  private var ingredients: [Ingredient] {
    allIngredients.filter { $0.location == location }
  }
  
  private var selectedIndexSet: IndexSet {
    IndexSet(selectedIngredients.compactMap { ingredient in
      allIngredients.firstIndex(of: ingredient)
    })
  }
  
  func isSelected(for ingredient: Ingredient) -> Binding<Bool> {
    Binding(
      get: { selectedIngredients.contains(ingredient) },
      set: { isSelected in
        if isSelected {
          selectedIngredients.append(ingredient)
        } else {
          selectedIngredients.removeAll { $0 == ingredient }
        }
      }
    )
  }
  
  var body: some View {
    NavigationStack {
      ZStack {
        VStack {
          IngredientList(
            ingredients: ingredients,
            showAddSheet: showAddSheet,
            removeIngredients: removeIngredients,
            isSelected: isSelected
          )
        }
        .navigationTitle(location.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            HStack {
              
              Button {
                showAddSheet()
              } label: {
                Image(systemName: "plus")
                  .foregroundColor(.blue)
                  .frame(width: 40, height: 40)
                  .background(Color(red: 0.85, green: 0.92, blue: 1.0))
                  .clipShape(Circle())
                  .animation(.snappy, value: hasSelection)
                  .transition(.move(edge: .leading))
              }
              
              if hasSelection {
                Menu {
                  Button("Move to \(location.destination.title)", systemImage: "folder", action: {
                    moveIngredients(from: selectedIndexSet)
                  })
                  Button("Remove Ingredients", systemImage: "trash", role: .destructive, action: {
                    removeIngredients(from: selectedIndexSet)
                  })
                  Button("Clear Ingredients", systemImage: "clear", role: .destructive, action: {
                    clearAllIngredients()
                  })
                } label: {
                  Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                  //.rotationEffect(.degrees(90))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0.85, green: 0.92, blue: 1.0))
                    .clipShape(Circle())
                    .animation(.snappy, value: hasSelection)
                    .transition(.opacity)
                }
              }
            }
          }
        }
        
        
        FloatingBottomSheet(
          isPresented: $showBottomSheet,
          showHideTabBar: true
        ) {
          IngredientEditor(
            ingredientLocation: location,
            ingredient: $currentIngredient,
            showBottomSheet: $showBottomSheet
          )
        }
      }
    }
    .onChange(of: selectedIngredients) {
      withAnimation {
        hasSelection = !selectedIngredients.isEmpty
      }
    }
    .alert("Error", isPresented: $showingErrorAlert) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(errorMessage)
    }
  }
  
  func showAddSheet(ingredient: Ingredient? = nil) {
    // If an ingredient was passed, it means we're editing an existing one
    if let ingredient = ingredient {
      currentIngredient = ingredient
    } else {
      currentIngredient = nil
    }
    
    // Show the bottom sheet after setting the ingredient state
    showBottomSheet = true
  }
  
  func removeIngredients(from selection: IndexSet) {
      for index in selection {
        context.delete(allIngredients[index])
      }
      selectedIngredients.removeAll()

  }
  
  func moveIngredients(from selection: IndexSet) {
    do {
      for index in selection {
        allIngredients[index].moveTo(location.destination)
      }
      try context.save()
      selectedIngredients.removeAll()
    } catch {
      handleDataError(error)
    }
  }
  
  func clearAllIngredients() {
    do {
      try context.delete(model: Ingredient.self)
      selectedIngredients.removeAll()
    } catch {
      handleDataError(error)
    }
  }
  
  private func handleDataError(_ error: Error) {
    print("Data operation error: \(error.localizedDescription)")
    
    // Show user-facing alert using SwiftUI
    errorMessage = "There was a problem: \(error.localizedDescription)"
    showingErrorAlert = true
  }
}

#Preview {
  @State var currentIngredient: Ingredient? = nil
  @State var showBottomSheet = false
  return IngredientsView(
    location: IngredientLocation.grocery
  )
      .modelContainer(DataController.previewContainer)
}
