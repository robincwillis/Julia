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
        
        // Add spacer at the end for tab bar
        Section {
          Color.clear
            .frame(height: 90) // Height of tab bar + extra padding
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
      }
      .listStyle(.plain)
    }
  }
  

}

#Preview("Ingredient List") {
  Previews.previewModels(with: { context in
    // Create sample ingredients using MockData
    let ingredients = MockData.createSampleIngredients()
    
    // Insert ingredients into context
    for ingredient in ingredients {
      context.insert(ingredient)
    }
    
    return ingredients
  }) { ingredients in
    // Content closure receives the ingredients array
    IngredientList(
      ingredients: ingredients,
      showAddSheet: { _ in /* Noop */ },
      removeIngredients: { _ in /* Noop */ },
      isSelected: { _ in .constant(false) }
    )
  }
}
