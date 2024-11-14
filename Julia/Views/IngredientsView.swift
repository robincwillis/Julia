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
    print(ingredients)
    return NavigationStack {
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
                  Button("Remove Ingredients", action: {
                    removeIngredients(from: selectedIndexSet)
                  })
                  Button("Move to Pantry", action: {
                    moveIngredients(from: selectedIndexSet)
                  })
                  Button("Clear Ingredients", action: {
                    do {
                      try context.delete(model: Ingredient.self)
                    } catch {
                      print("errror")
                    }
                    
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
    //.onChange(of: currentIngredient) {
      //print("ingredientManager current Ingredient changed")
//      print(currentIngredient as Any)
//      currentIngredient = ingredientManager.currentIngredient
//      if ingredientManager.currentIngredient != nil {
//        print("ingredientManager currentIngredient is defined")
//      } else {
//        print("ingredientManager why did this change to nothing")
//      }
  //  }
    
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
    print("Remove Ingredients")
    do {
      for index in selection {
        print(index)
        context.delete(allIngredients[index])
      }
      
      
      try context.save()
      selectedIngredients.removeAll()
    } catch {
      print("Error: \(error.localizedDescription)")
    }
  }
  
  func moveIngredients(from selection: IndexSet) {
    print("Move Ingredients")
    do {
      for index in selection {
        let newLocation  = allIngredients[index].destination()
        print(newLocation)
        print(allIngredients[index])
        allIngredients[index].moveTo(newLocation)
      }
      try context.save()
      selectedIngredients.removeAll()
    } catch {
      print("Error: \(error.localizedDescription)")
    }
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
