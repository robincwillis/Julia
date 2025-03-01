//
//  IngredientList.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData

struct IngredientList: View {
  let ingredients: [Ingredient]
  let showAddSheet: ((Ingredient?) -> Void)?
  let removeIngredients: ((IndexSet) -> Void)
  let isSelected: (Ingredient) -> Binding<Bool>

  var body: some View {
    VStack (spacing: 32) {
      List {
        ForEach(ingredients) { ingredient in
          IngredientRow(
            ingredient: ingredient,
            onTap: showAddSheet
          )
          .selectable(selected: isSelected(ingredient))
        }
        .onDelete(perform: removeIngredients)
      }
    }
  }
  

}

#Preview {
  let container = DataController.previewContainer
  let fetchDescriptor = FetchDescriptor<Ingredient>()
  
  do {
    let ingredients = try container.mainContext.fetch(fetchDescriptor)
    // let selectedIngredients = Set<Ingredient>()
    
    func showAddSheet(_ ingredient: Ingredient?) {
      // Preview only
    }
    
    func removeIngredients(from offsets: IndexSet) {
      // Preview only
    }
    
    func isSelected(_ ingredient: Ingredient) -> Binding<Bool> {
      .constant(false)
    }
    
    return IngredientList(
      ingredients: ingredients.prefix(10).map { $0 },
      showAddSheet: showAddSheet,
      removeIngredients: removeIngredients,
      isSelected: isSelected
    )
  } catch {
    return Text("Failed to load ingredients: \(error.localizedDescription)")
  }
}

