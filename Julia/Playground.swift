import SwiftUI
import SwiftData

struct SimpleTitleScrollView: View {
  let recipe: Recipe
  
  @State private var selectedIngredients: Set<Ingredient> = []
  @State private var titleIsVisible: Bool = false
  @State private var titlePosition: CGFloat = 100
  @State private var titleHeight: CGFloat = 0
  @State private var titleOpacity: Double = 1.0  // New state for title opacity

  
  init(recipe: Recipe) {
    self.recipe = recipe
  }
  
  var body: some View {
    ZStack(alignment: .top) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          // Title Starts Here
          GeometryReader { geometry in
            Text(recipe.title)
              .font(.largeTitle)
              .fontWeight(.bold)
              .padding(.horizontal)
              .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
              .background(
                // Background for height measurement - simpler approach
                GeometryReader { geo -> Color in
                  DispatchQueue.main.async {
                    self.titleHeight = geo.size.height
                    print("Title height captured: \(self.titleHeight)")
                  }
                  return Color.clear
                }
              )
              .onChange(of: geometry.frame(in: .named("scrollContainer")).minY) { oldValue, newValue in
                titlePosition = newValue
                titleIsVisible = newValue > -titleHeight
                
                if newValue >= 0 {
                  // Fully visible
                  titleOpacity = 1.0
                } else if newValue <= -titleHeight {
                  // Fully scrolled out
                  titleOpacity = 0.0
                } else {
                  titleOpacity = 1.0 - (-newValue / (titleHeight - 20))
                }
                
                print("Title position: \(newValue)")
              }

          }
          .frame(height: titleHeight)
          .frame(maxWidth: .infinity)
          .background(.red)
          .opacity(titleOpacity)

          // Main content starts here
          VStack(alignment: .leading, spacing: 16) {
            // Recipe summary section
            if let summary = recipe.summary {
              Text("Summary")
                .font(.headline)
                .foregroundColor(.gray)
              Text(summary)
                .font(.body)
            }
            
            // Ingredients section
            RecipeIngredientsSection(
              recipe: recipe,
              selectableBinding: selectableBinding(for:),
              toggleSelection: toggleSelection(for:)
            )
            
            // Instructions section
            RecipeInstructionsSection(recipe: recipe)
            
            // Add more sections as needed
          }
          .padding()
        }
      }
      //.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .coordinateSpace(name: "scrollContainer")
    //.frame(maxWidth: .infinity, maxHeight: .infinity)

    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(!titleIsVisible ? recipe.title : "")
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(!titleIsVisible ? recipe.title : "")
          .font(.headline)
          .foregroundColor(.primary)
          
      }
    }
  }
  
  private func selectableBinding(for ingredient: Ingredient) -> Binding<Bool> {
    Binding(
      get: { selectedIngredients.contains(ingredient) },
      set: { isSelected in
        if isSelected {
          selectedIngredients.insert(ingredient)
        } else {
          selectedIngredients.remove(ingredient)
        }
      }
    )
  }
  
  private func toggleSelection(for ingredient: Ingredient) {
    if selectedIngredients.contains(ingredient) {
      selectedIngredients.remove(ingredient)
    } else {
      selectedIngredients.insert(ingredient)
    }
  }
}

#Preview {
  let container = DataController.previewContainer
  let fetchDescriptor = FetchDescriptor<Recipe>()
  
  let previewRecipe: Recipe
  
  do {
    let recipes = try container.mainContext.fetch(fetchDescriptor)
    if let firstRecipe = recipes.first {
      previewRecipe = firstRecipe
    } else {
      // Fallback if no recipes found
      previewRecipe = Recipe(
        title: "Homemade Classic Margherita Pizza",
        summary: "A delicious traditional Italian pizza with simple ingredients.",
        ingredients: [],
        instructions: ["Prepare the dough", "Add sauce", "Top with cheese", "Bake until perfect"]
      )
    }
  } catch {
    print("Error fetching recipes: \(error)")
    // Error fallback
    previewRecipe = Recipe(
      title: "Sample Recipe",
      summary: "A delicious sample recipe",
      ingredients: [],
      instructions: ["Step 1: Mix ingredients", "Step 2: Cook thoroughly"]
    )
  }
  
  return NavigationStack {
    SimpleTitleScrollView(recipe: previewRecipe)
      .modelContainer(container)
  }
}
