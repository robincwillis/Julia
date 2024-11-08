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
    var onSelect: (Ingredient) -> Void
    var onDeselect: (Ingredient) -> Void
    
    //@Environment(\.modelContext) private var context
    
    var body: some View {
        VStack (spacing: 32) {
            List(ingredients, id: \.id) { ingredient in
                IngredientRow(ingredient: ingredient)
            }
        }
    }
}

#Preview {
  let container = DataController.previewContainer
  let fetchDescriptor = FetchDescriptor<Ingredient>()
  let ingredients = try! container.mainContext.fetch(fetchDescriptor)
  return IngredientList(ingredients:ingredients, onSelect: { _ in }, onDeselect: { _ in })
}


