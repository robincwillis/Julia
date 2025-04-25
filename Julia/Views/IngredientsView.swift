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
  
  @State private var showSuccessAlert = false
  @State private var showErrorAlert = false
  @State private var errorMessage = ""
  @State private var loadedCount = 0
  
  
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
          if ingredients.isEmpty {
            EmptyIngredientsView(location: location) {
              loadSampleData()
            }
          } else {
            IngredientList(
              ingredients: ingredients,
              showAddSheet: showAddSheet,
              removeIngredients: removeIngredients,
              isSelected: isSelected
            )
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
      .background(Color.app.backgroundPrimary)
      .navigationTitle(location.title)
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          HStack {
            
            Button {
              showAddSheet()
            } label: {
              Image(systemName: "plus")
                .foregroundColor(Color.app.primary)
                .frame(width: 40, height: 40)
                .background(.white)
                .clipShape(Circle())
                .animation(.snappy, value: hasSelection)
                .transition(.move(edge: .leading))
            }
            
            if hasSelection {
              Menu {
                Button("Move to \(location.destination.title)", systemImage: "folder", action: {
                  moveIngredients(from: selectedIndexSet)
                })
                .tint(Color.app.primary)
                
                Button("Select All", systemImage: "checklist.checked", action: selectAll)
                  .tint(Color.app.primary)
                
                Button("Clear Selection", systemImage: "xmark.circle", action: clearSelection)
                  .tint(Color.app.primary)
                
                Button("Remove Ingredients", systemImage: "trash", role: .destructive, action: {
                  removeIngredients(from: selectedIndexSet)
                })
                .tint(Color.app.danger)
                Button("Clear Ingredients", systemImage: "clear", role: .destructive, action: {
                  clearAllIngredients()
                })
                .tint(Color.app.danger)
                
              } label: {
                Image(systemName: "ellipsis")
                  .font(.system(size: 14))
                  .foregroundColor(Color.app.primary)
                  .frame(width: 40, height: 40)
                  .background(Color.white)
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
    .alert("Ingredients Added", isPresented: $showSuccessAlert) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("Added \(loadedCount) ingredients to your \(location.rawValue).")
    }
    .alert("Error", isPresented: $showErrorAlert) {
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
  
  private func selectAll() {
    for ingredient in ingredients {
      if !selectedIngredients.contains(ingredient) {
        selectedIngredients.append(ingredient)
      }
    }
  }
  
  private func clearSelection() {
    selectedIngredients.removeAll()
    
  }
  
  private func removeIngredients(from selection: IndexSet) {
    for index in selection {
      context.delete(allIngredients[index])
    }
    selectedIngredients.removeAll()
    
  }
  
  private func moveIngredients(from selection: IndexSet) {
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
  
  private func clearAllIngredients() {
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
    showErrorAlert = true
  }
  
  private func loadSampleData() {
    Task {
      do {
        let count = try await SampleDataLoader.loadSampleData(
          type: location == .pantry ? .pantryIngredients : .groceryIngredients,
          context: context
        )
        
        await MainActor.run {
          loadedCount = count
          showSuccessAlert = true
        }
      } catch {
        errorMessage = "Error loading sample data: \(error.localizedDescription)"
        print(errorMessage)
        showErrorAlert = true
      }
    }
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
