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

#Preview("Ingredient Section List") {
  Previews.previewModels(with: { context in
    // Create sections
    let section1 = IngredientSection(name: "Main Ingredients", position: 0)
    let section2 = IngredientSection(name: "Sauce", position: 1)
    
    // Insert sections into context
    context.insert(section1)
    context.insert(section2)
    
    // Create ingredients
    let ingredient1 = Ingredient(name: "Chicken", location: .recipe, quantity: 2.0, unit: "pounds")
    let ingredient2 = Ingredient(name: "Olive Oil", location: .recipe, quantity: 2.0, unit: "tablespoons")
    
    // Insert ingredients into context and establish relationships
    context.insert(ingredient1)
    context.insert(ingredient2)
    ingredient1.section = section1
    ingredient2.section = section1	
    section1.ingredients = [ingredient1, ingredient2]
    
    // Create more ingredients
    let ingredient3 = Ingredient(name: "Tomato Sauce", location: .recipe, quantity: 1.0, unit: "cup")
    let ingredient4 = Ingredient(name: "Garlic", location: .recipe, quantity: 3.0, unit: "cloves")
    
    // Insert ingredients into context and establish relationships
    context.insert(ingredient3)
    context.insert(ingredient4)
    ingredient3.section = section2
    ingredient4.section = section2
    section2.ingredients = [ingredient3, ingredient4]
    
    // Return an array of sections for the preview
    return [section1, section2]
  }) { (sections: [IngredientSection]) in
    IngredientSectionList(
      sections: sections,
      selectableBinding: { _ in .constant(false) },
      toggleSelection: { _ in }
    )
    .padding()
  }
}
