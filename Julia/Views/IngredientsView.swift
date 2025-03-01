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
  @Binding var showBottomSheet: Bool
  @Binding var currentIngredient: Ingredient? 

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
                  .foregroundColor(.white)
                  .frame(width: 40, height: 40)
                  .background(.blue)
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
    .alert("Error", isPresented: $showingErrorAlert) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(errorMessage)
    }
  }
  
  func showAddSheet(ingredient: Ingredient? = nil) {
    guard let ingredient = ingredient else {
      showBottomSheet = true  // Show the sheet even if there's no ingredient
      return
    }
    currentIngredient = ingredient
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
    location: IngredientLocation.grocery,
    showBottomSheet: $showBottomSheet,
    currentIngredient: $currentIngredient
  )
      .modelContainer(DataController.previewContainer)
}
