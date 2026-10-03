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
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)

        Section {
          Color.clear
            .frame(height: 90)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
    }
  }
  

}

#Preview("Ingredient List") {
  Previews.previewModels(with: { context in
    let ingredients = MockData.createSampleIngredients()
    for ingredient in ingredients {
      context.insert(ingredient)
    }
    return ingredients
  }) { ingredients in
    IngredientList(
      ingredients: ingredients,
      showAddSheet: { _ in /* Noop */ },
      removeIngredients: { _ in /* Noop */ },
      isSelected: { _ in .constant(false) }
    )
  }
}
