import SwiftUI
import SwiftData

struct SimpleTitleScrollView<Content: View>: View {
  let title: String
  let content: Content
  
  @State private var titleIsVisible: Bool = true
  @State private var titleRect: CGRect = .zero
  
  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        // Title that will be tracked for visibility
        Text(title)
          .font(.largeTitle)
          .fontWeight(.bold)
          .padding(.horizontal)
          .padding(.top, 8)
          .padding(.bottom, 12)
          .background(GeometryReader { geo in
            Color.clear.onAppear {
              print("Title height: \(geo.size.height)")
            }
          })
        
        // Main content
        content
          .padding(.top, 8)
      }
    }
    .coordinateSpace(name: "scrollView")
    .onPreferenceChange(ViewRectKey.self) { rect in
      titleRect = rect
      print(rect.minY)
      // Title is visible if the bottom of the title is above the top of the screen
      titleIsVisible = rect.minY > 0
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(title)
          .font(.headline)
          .foregroundColor(.red)
          .opacity(titleIsVisible ? 0 : 0.25)
          .animation(.easeInOut(duration: 0.2), value: titleIsVisible)
      }
    }
  }
}

// Preference key to track view rect
struct ViewRectKey: PreferenceKey {
  static var defaultValue: CGRect = .zero
  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}

// Example implementation
struct RecipeWithScrollingTitle: View {
  let recipe: Recipe
  @State private var selectedIngredients: Set<Ingredient> = []
  
  // Helper functions for ingredients selection
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
  
  var body: some View {
    SimpleTitleScrollView(title: recipe.title) {
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
    RecipeWithScrollingTitle(recipe: previewRecipe)
      .modelContainer(container)
  }
}
