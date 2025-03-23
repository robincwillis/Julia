//
//  PreviewHelpers.swift
//  Julia
//
//  Created by Robin Willis on 3/22/25.
//

import SwiftUI
import SwiftData

/// Preview helper utilities
struct PreviewHelpers {

  
  // Basic preview with ModelContainer attached
  @MainActor
  static func preview<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
      .modelContainer(DataController.previewContainer)
  }
  
  // Preview helper that provides a ModelContext to the content builder
  @MainActor
  static func preview<Content: View>(@ViewBuilder content: @escaping (ModelContext) -> Content) -> some View {
    PreviewWithContext(content: content)
      .modelContainer(DataController.previewContainer)
  }
  
  // Helper for creating previews with specific models
  @MainActor
  static func preview<Content: View, Model: PersistentModel>(
    with model: @escaping (ModelContext) -> Model,
    @ViewBuilder content: @escaping (Model) -> Content
  ) -> some View {
    PreviewWithModel(modelProvider: model, content: content)
      .modelContainer(DataController.previewContainer)
  }
  
  /// Helper for views that need arrays of specific model objects
  @MainActor
  static func previewModels<Content: View, Model: PersistentModel>(
    with modelProvider: @escaping (ModelContext) -> [Model],
    @ViewBuilder content: @escaping ([Model]) -> Content
  ) -> some View {
    PreviewWithModels(modelProvider: modelProvider, content: content)
      .modelContainer(DataController.previewContainer)
  }
  
  // Creates a preview with a basic recipe
  @MainActor
  static func recipeComponent<Content: View>(
    @ViewBuilder content: @escaping (Recipe) -> Content
  ) -> some View {
    preview { context in
      // Create a recipe within the provided context
      let recipe = Recipe(
        title: "Sample Recipe",
        summary: "A delicious sample recipe",
        ingredients: [],
        instructions: ["Step 1: Mix ingredients", "Step 2: Cook thoroughly"],
        rawText: ["Line 1: Sample recipe text", "Line 2: More sample text", "Line 3: Final line of text"]
      )
      
      // Insert recipe first
      context.insert(recipe)
      
      // Add some ingredients to the recipe
      let ingredient1 = Ingredient(name: "Flour", location: .recipe, quantity: 2, unit: "cup")
      let ingredient2 = Ingredient(name: "Sugar", location: .recipe, quantity: 1, unit: "cup")
      recipe.ingredients = [ingredient1, ingredient2]
      
      // Return the content with the created recipe
      return content(recipe)
    }
  }
  
  /// Creates a preview with a recipe that has sections
  @MainActor
  static func sectionedRecipeComponent<Content: View>(
    @ViewBuilder content: @escaping (Recipe) -> Content
  ) -> some View {
    preview { context in
      // Create recipe with sections
      let recipe = Recipe(
        title: "Structured Recipe",
        summary: "A recipe with organized sections",
        instructions: ["Follow each section carefully"]
      )
      
      // Insert the recipe first
      context.insert(recipe)
      
      // Create sections with ingredients
      let section1 = IngredientSection(name: "Main Ingredients", position: 0)
      section1.recipe = recipe  // Set relationship to recipe
      
      let section2 = IngredientSection(name: "Sauce", position: 1)
      section2.recipe = recipe  // Set relationship to recipe
      
      // Add sections to context
      context.insert(section1)
      context.insert(section2)
      
      // Now add ingredients to sections
      let ingredient1 = Ingredient(name: "Chicken", location: .recipe, quantity: 2, unit: "pounds")
      let ingredient2 = Ingredient(name: "Olive Oil", location: .recipe, quantity: 2, unit: "tablespoons")
      ingredient1.section = section1
      ingredient2.section = section1
      section1.ingredients = [ingredient1, ingredient2]
      
      let ingredient3 = Ingredient(name: "Tomato Sauce", location: .recipe, quantity: 1, unit: "cup")
      let ingredient4 = Ingredient(name: "Garlic", location: .recipe, quantity: 3, unit: "cloves")
      ingredient3.section = section2
      ingredient4.section = section2
      section2.ingredients = [ingredient3, ingredient4]
      
      // Set relationship for recipe
      recipe.sections = [section1, section2]
      
      return content(recipe)
    }
  }
  
  /// Creates a customizable recipe preview
  @MainActor
  static func customRecipe<Content: View>(
    title: String = "Custom Recipe",
    summary: String? = "Custom recipe description",
    hasIngredients: Bool = true,
    hasSections: Bool = false,
    hasTimings: Bool = false,
    ingredientCount: Int = 3,
    instructionCount: Int = 3,
    @ViewBuilder content: @escaping (Recipe) -> Content
  ) -> some View {
    preview { context in
      // Create base recipe
      let recipe = Recipe(
        title: title,
        summary: summary,
        ingredients: [],
        instructions: (1...instructionCount).map { "Step \($0): Instruction text here." }
      )
      
      // Insert recipe first
      context.insert(recipe)
      
      // Add ingredients if requested
      if hasIngredients {
        let ingredients = (1...ingredientCount).map { i in
          Ingredient(
            name: "Ingredient \(i)",
            location: .recipe,
            quantity: Double(i),
            unit: ["cup", "tablespoon", "teaspoon"][i % 3]
          )
        }
        recipe.ingredients = ingredients
      }
      
      // Add sections if requested
      if hasSections {
        let section1 = IngredientSection(name: "Main Ingredients", position: 0)
        section1.recipe = recipe
        
        let section2 = IngredientSection(name: "Sauce", position: 1)
        section2.recipe = recipe
        
        context.insert(section1)
        context.insert(section2)
        
        let sectionIngredients1 = [
          Ingredient(name: "Section Ingredient 1", location: .recipe, quantity: 1, unit: "cup"),
          Ingredient(name: "Section Ingredient 2", location: .recipe, quantity: 2, unit: "tablespoon")
        ]
        
        let sectionIngredients2 = [
          Ingredient(name: "Section Ingredient 3", location: .recipe, quantity: 3, unit: "teaspoon"),
          Ingredient(name: "Section Ingredient 4", location: .recipe, quantity: 4, unit: "cup")
        ]
        
        for ingredient in sectionIngredients1 {
          ingredient.section = section1
        }
        
        for ingredient in sectionIngredients2 {
          ingredient.section = section2
        }
        
        section1.ingredients = sectionIngredients1
        section2.ingredients = sectionIngredients2
        recipe.sections = [section1, section2]
      }
      
      // Add timings if requested
      if hasTimings {
        let prepTime = Timing(type: "Prep", hours: 0, minutes: 15)
        let cookTime = Timing(type: "Cook", hours: 0, minutes: 30)
        
        context.insert(prepTime)
        context.insert(cookTime)
        
        recipe.timings = [prepTime, cookTime]
      }
      
      return content(recipe)
    }
  }
}


/// Helper view that provides context to content builder
private struct PreviewWithContext<Content: View>: View {
  var content: (ModelContext) -> Content
  
  @Environment(\.modelContext) private var context
  
  var body: some View {
    content(context)
  }
}

/// Helper view that manages model creation and provides it to content
private struct PreviewWithModel<Content: View, Model: PersistentModel>: View {
  var modelProvider: (ModelContext) -> Model
  var content: (Model) -> Content
  
  @Environment(\.modelContext) private var context
  @State private var model: Model?
  
  var body: some View {
    Group {
      if let model = model {
        content(model)
      } else {
        ProgressView()
          .onAppear {
            // Create the model when the view appears
            let newModel = modelProvider(context)
            self.model = newModel
          }
      }
    }
  }
}

/// Helper view that manages model array creation and provides it to content
private struct PreviewWithModels<Content: View, Model: PersistentModel>: View {
  var modelProvider: (ModelContext) -> [Model]
  var content: ([Model]) -> Content
  
  @Environment(\.modelContext) private var context
  @State private var models: [Model]?
  
  var body: some View {
    Group {
      if let models = models {
        content(models)
      } else {
        ProgressView()
          .onAppear {
            // Create the models when the view appears
            let newModels = modelProvider(context)
            self.models = newModels
          }
      }
    }
  }
}
		

//// Simple container wrapper
public struct PreviewContainer<Content: View>: View {
  let content: Content
  
  public init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
  
  public var body: some View {
    content
      .modelContainer(DataController.previewContainer)
  }
}

/// Preview container that loads data before displaying content
public struct LoadablePreviewContainer<Content: View, T>: View {
  let content: (T) -> Content
  let loader: () async -> T
  
  @State private var data: T?
  @State private var isLoading = true
  
  public init(loader: @escaping () async -> T, @ViewBuilder content: @escaping (T) -> Content) {
    self.content = content
    self.loader = loader
  }
  
  public var body: some View {
    Group {
      if let data = data {
        content(data)
      } else {
        ProgressView("Loading preview data...")
      }
    }
    .task {
      if data == nil {
        data = await loader()
        isLoading = false
      }
    }
    .modelContainer(DataController.previewContainer)
  }
}


// Easy-to-use preview extensions for SwiftUI views
extension View {
  // Attach the preview container to this view
  func previewContainer() -> some View {
    self.modelContainer(DataController.previewContainer)
  }
}

// Alias for the PreviewHelpers struct
typealias Previews = PreviewHelpers
