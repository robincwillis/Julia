//
//  IngredientViewModel.swift
//  Julia
//
//  Created by Robin Willis on 7/3/24.
//



import Combine
import SwiftUI


class IngredientViewModel : ObservableObject {

  @Published var selectedIngredients: Set<Ingredient> = []
  
  func toggleSelection(for ingredient: Ingredient) {
    if selectedIngredients.contains(ingredient) {
      selectedIngredients.remove(ingredient)
    } else {
      selectedIngredients.insert(ingredient)
    }
  }
  
  func clearSelection() {
    selectedIngredients.removeAll()
  }
  
  var hasSelection: Bool {
    !selectedIngredients.isEmpty
  }
  

  
  // Example of new functionality made easier by having the full Ingredient
//  func groupSelectedByFirstLetter() -> [Character: [Ingredient]] {
//    Dictionary(
//      grouping: selectedIngredients,
//      by: { Character(String($0.name.prefix(1))) }
//    )
//  }
  
  func moveToGroceries(ingredient: Ingredient) {
  }
  
  func moveToIngredients(grocery: Ingredient) {
  }
}


extension IngredientViewModel {
  func isSelected(_ ingredient: Ingredient) -> Binding<Bool> {
    Binding(
      get: { self.selectedIngredients.contains(ingredient) },
      //set: { _ in self.toggleSelection(for: ingredient) }
      set: { isSelected in
        if isSelected {
          self.selectedIngredients.insert(ingredient)
        } else {
          self.selectedIngredients.remove(ingredient)
        }
      }
    )
  }
  
}

// extension IngredientViewModel{
//   convenience init(forPreview: Bool = true) {
//      self.init()
//      //Hard code your mock data for the preview here
//     // self.ingredients = mockIngredients
//      // self.groceries = mockIngredients
//   }
// }

