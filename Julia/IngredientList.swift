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
    @ObservedObject var ingredientManager: IngredientViewModel

    var body: some View {
        VStack (spacing: 32) {
          List(ingredients) { ingredient in
            IngredientRow(ingredient: ingredient)
              .selectable(selected: ingredientManager.isSelected(ingredient))
            }
        }
        //.padding(.top, 10)
    }
}

#Preview {
  let container = DataController.previewContainer
  let fetchDescriptor = FetchDescriptor<Ingredient>()
  let ingredients = try! container.mainContext.fetch(fetchDescriptor)
  @StateObject var ingredientManager = IngredientViewModel()
  return IngredientList(ingredients:Array(ingredients[0..<10]), ingredientManager: ingredientManager)
}

