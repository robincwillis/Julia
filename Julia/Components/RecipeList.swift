import SwiftUI
import SwiftData

struct RecipeList: View {
    let recipes: [Recipe]
    var body: some View {
        List {
            ForEach(recipes) { recipe in
                NavigationLink(value: recipe) {
                    RecipeRow(recipe: recipe)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparatorTint(Color.app.offWhite400)

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

#Preview("Recipe List") {
  Previews.previewModels(with: { context in
    let recipe1 = Recipe(
      title: "Chocolate Chip Cookies",
      summary: "Classic homemade cookies with chocolate chips",
      instructions: [
        Step(value:"Mix ingredients"),
        Step(value:"Bake at 350°F for 12 minutes")
      ]
    )
    
    let recipe2 = Recipe(
      title: "Pasta Primavera",
      summary: "Light pasta dish with spring vegetables",
      instructions: [
        Step(value:"Cook pasta"),
        Step(value:"Sauté vegetables"),
        Step(value:"Combine and serve")
      ]
    )
    
    let recipe3 = Recipe(
      title: "Greek Salad",
      summary: "Fresh Mediterranean salad with feta cheese",
      instructions: [
        Step(value:"Chop vegetables"),
        Step(value:"Add dressing"),
        Step(value:"Top with feta")
      ]
    )
    
    context.insert(recipe1)
    context.insert(recipe2)
    context.insert(recipe3)
    return [recipe1, recipe2, recipe3]
  }) { recipes in
    RecipeList(recipes: recipes)
  }
}
