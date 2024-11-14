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

//#Preview {
//  let container = DataController.previewContainer
//  let fetchDescriptor = FetchDescriptor<Ingredient>()
//  let ingredients = try! container.mainContext.fetch(fetchDescriptor)
//  @StateObject var ingredientManager = IngredientViewModel(location: IngredientLocation.pantry)
//  
//  func removeIngredients(from offsets: IndexSet) {
//    print("remove \(offsets)")
//  }
//  
//  return IngredientList(
//    ingredients:Array(ingredients[0..<10]),
//    ingredientManager: ingredientManager,
//    removeIngredients: removeIngredients
//  )
//}

