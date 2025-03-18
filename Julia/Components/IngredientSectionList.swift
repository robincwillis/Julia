//
//  IngredientSectionList.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftUI

struct IngredientSectionList: View {
    let sections: [IngredientSection]
    let selectableBinding: (Ingredient) -> Binding<Bool>
    let toggleSelection: (Ingredient) -> Void
    
    var body: some View {
      ForEach(sections.sorted(by: { $0.position < $1.position })) { section in
          VStack(alignment: .leading, spacing: 8) {
              Text(section.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
                  
              
              if section.ingredients.isEmpty {
                  Text("No ingredients in this section")
                      .foregroundColor(.gray)
                      .padding(.vertical, 8)
              } else {
                  ForEach(section.ingredients) { ingredient in
                    IngredientRow(ingredient: ingredient, section: section)
                          .selectable(selected: selectableBinding(ingredient))
                          .contentShape(Rectangle())
                          .onTapGesture {
                              toggleSelection(ingredient)
                          }
                  }
              }
          }
      }
  
    }
}

#Preview {
    let section1 = IngredientSection(name: "Main Ingredients", position: 0)
    let section2 = IngredientSection(name: "Sauce", position: 1)
    
    let ingredient1 = Ingredient(name: "Chicken", location: .recipe, quantity: 2.0, unit: "pounds")
    let ingredient2 = Ingredient(name: "Olive Oil", location: .recipe, quantity: 2.0, unit: "tablespoons")
    section1.ingredients.append(ingredient1)
    section1.ingredients.append(ingredient2)
    
    let ingredient3 = Ingredient(name: "Tomato Sauce", location: .recipe, quantity: 1.0, unit: "cup")
    let ingredient4 = Ingredient(name: "Garlic", location: .recipe, quantity: 3.0, unit: "cloves")
    section2.ingredients.append(ingredient3)
    section2.ingredients.append(ingredient4)
    
    return IngredientSectionList(
        sections: [section1, section2],
        selectableBinding: { _ in .constant(false) },
        toggleSelection: { _ in }
    )
    .padding()
}
