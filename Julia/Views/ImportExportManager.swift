import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Data Import/Export Manager

class ImportExportManager {
  
  // MARK: - Export Models
  
  // Export models for JSON serialization remain the same
  struct RecipeExport: Codable {
    let id: String
    let title: String
    let summary: String?
    let servings: Int?
    let tags: [String]
    let rawText: [String]?
    let source: String?
    let sourceType: String?
    let sourceTitle: String?
    let website: String?
    let author: String?
    let ingredients: [IngredientExport]
    let sections: [SectionExport]
    let timings: [TimingExport]
    let instructions: [StepExport]
    let notes: [NoteExport]
  }
  
  struct IngredientExport: Codable {
    let id: String
    let name: String
    let location: String
    let quantity: Double?
    let unit: String?
    let comment: String?
    let position: Int
  }
  
  struct SectionExport: Codable {
    let id: String
    let name: String
    let position: Int
    let ingredients: [IngredientExport]
  }
  
  struct TimingExport: Codable {
    let id: String
    let type: String
    let hours: Int
    let minutes: Int
  }
  
  struct StepExport: Codable {
    let id: String
    let value: String
    let position: Int
  }
  
  struct NoteExport: Codable {
    let id: String
    let text: String
    let position: Int
  }
  
  enum ImportError: Error, LocalizedError {
    case fileReadError(Error)
    case jsonDecodingError(Error)
    case recipeProcessingError(index: Int, error: Error)
    case contextSaveError(Error)
    
    var errorDescription: String? {
      switch self {
      case .fileReadError(let error):
        return "Failed to read recipe file: \(error.localizedDescription)"
      case .jsonDecodingError(let error):
        return "Failed to decode recipe data: \(error.localizedDescription)"
      case .recipeProcessingError(let index, let error):
        return "Failed to process recipe at index \(index): \(error.localizedDescription)"
      case .contextSaveError(let error):
        return "Failed to save recipes to database: \(error.localizedDescription)"
      }
    }
  }
  
  // MARK: - Export Functions
  
  /// Shows file exporter for recipes
  static func exportRecipes(context: ModelContext) async -> (URL?, Error?) {
    do {
      // Create the export file
      let url = try await createRecipesExport(context: context)
      return (url, nil)
    } catch {
      print("Export error: \(error.localizedDescription)")
      return (nil, error)
    }
  }
  
  /// Shows file exporter for ingredients
  static func exportIngredients(context: ModelContext) async -> (URL?, Error?) {
    do {
      // Create the export file
      let url = try await createIngredientsExport(context: context)
      return (url, nil)
    } catch {
      print("Export error: \(error.localizedDescription)")
      return (nil, error)
    }
  }
  
  /// Creates a JSON file with all recipes
  static func createRecipesExport(context: ModelContext) async throws -> URL {
    // Fetch all recipes
    let recipesDescriptor = FetchDescriptor<Recipe>()
    let recipes = try context.fetch(recipesDescriptor)
    
    // Convert to exportable format
    let exportRecipes = recipes.map { recipe in
      RecipeExport(
        id: recipe.id,
        title: recipe.title,
        summary: recipe.summary,
        servings: recipe.servings,
        tags: recipe.tags,
        rawText: recipe.rawText,
        source: recipe.source,
        sourceType: recipe.sourceType?.rawValue,
        sourceTitle: recipe.sourceTitle,
        website: recipe.website,
        author: recipe.author,
        ingredients: recipe.ingredients.map { exportIngredient($0) },
        sections: recipe.sections.map { section in
          SectionExport(
            id: section.id,
            name: section.name,
            position: section.position,
            ingredients: section.ingredients.map { exportIngredient($0) }
          )
        },
        timings: recipe.timings.map { timing in
          TimingExport(
            id: timing.id,
            type: timing.type,
            hours: timing.hours,
            minutes: timing.minutes
          )
        },
        instructions: recipe.instructions.map { step in
          StepExport(
            id: step.id,
            value: step.value,
            position: step.position
          )
        },
        notes: recipe.notes.map { note in
          NoteExport(
            id: note.id,
            text: note.text,
            position: note.position
          )
        }
      )
    }
    
    // Encode to JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try encoder.encode(exportRecipes)
    
    // Write to temporary file
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("Julia-Recipes-\(DateFormatter.compactDateTime.string(from: Date())).json")
    
    try jsonData.write(to: tempURL)
    return tempURL
  }
  
  /// Creates a JSON file with standalone ingredients
  private static func createIngredientsExport(context: ModelContext) async throws -> URL {
    // Fetch standalone ingredients (not associated with recipes)
    let ingredientsDescriptor = FetchDescriptor<Ingredient>(
      predicate: #Predicate<Ingredient> { $0.recipe == nil && $0.section == nil }
    )
    let ingredients = try context.fetch(ingredientsDescriptor)
    
    // Convert to exportable format
    let exportIngredients = ingredients.map { exportIngredient($0) }
    
    // Encode to JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try encoder.encode(exportIngredients)
    
    // Write to temporary file
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("Julia-Ingredients-\(DateFormatter.compactDateTime.string(from: Date())).json")
    
    try jsonData.write(to: tempURL)
    return tempURL
  }
  
  /// Helper to convert an Ingredient to exportable format
  static func exportIngredient(_ ingredient: Ingredient) -> IngredientExport {
    return IngredientExport(
      id: ingredient.id,
      name: ingredient.name,
      location: ingredient.location.rawValue,
      quantity: ingredient.quantity,
      unit: ingredient.unit?.rawValue,
      comment: ingredient.comment,
      position: ingredient.position
    )
  }
  
  // MARK: - Import Functions
  
  /// Imports recipes from a JSON file
  static func importRecipesFile(from url: URL, context: ModelContext) async throws -> Int {
    // Read JSON data
    let data: Data
    do {
      data = try Data(contentsOf: url)
      print("Successfully read file data: \(data.count) bytes")
    } catch {
      print("Error reading file: \(error)")
      throw ImportError.fileReadError(error)
    }
    
    // Decode recipes
    let decoder = JSONDecoder()
    let importedRecipes: [RecipeExport]
    
    do {
      importedRecipes = try decoder.decode([RecipeExport].self, from: data)
      print("Successfully decoded \(importedRecipes.count) recipes")
    } catch {
      print("JSON decoding error: \(error)")
      // Print sample of data to debug
      if let sample = String(data: data.prefix(100), encoding: .utf8) {
        print("Data sample: \(sample)...")
      }
      throw ImportError.jsonDecodingError(error)
    }
    
    // Import each recipe
    var importedCount = 0
    for (index, importedRecipe) in importedRecipes.enumerated() {
      do {
        // Check if recipe already exists
        var existingRecipeDescriptor = FetchDescriptor<Recipe>(
          predicate: #Predicate<Recipe> { $0.id == importedRecipe.id }
        )
        existingRecipeDescriptor.fetchLimit = 1
        
        if let existingRecipe = try context.fetch(existingRecipeDescriptor).first {
          // Update existing recipe
          print("Updating existing recipe: \(importedRecipe.title)")
          updateRecipe(existingRecipe, from: importedRecipe, context: context)
        } else {
          // Create new recipe (already inserts into context)
          print("Creating new recipe: \(importedRecipe.title)")
          let _ = createRecipe(from: importedRecipe, context: context)
        }
        importedCount += 1
      } catch {
        print("Error processing recipe \(index): \(error)")
        throw ImportError.recipeProcessingError(index: index, error: error)
      }
    }
    
    // Save changes
    do {
      print("Saving changes to context")
      try context.save()
      print("Successfully saved \(importedCount) recipes")
      return importedCount
    } catch {
      print("Error saving to context: \(error)")
      throw ImportError.contextSaveError(error)
    }
  }
  
  /// Imports standalone ingredients from a JSON file
  static func importIngredientsFile(from url: URL, context: ModelContext) async throws -> Int {
    // Read JSON data
    let data = try Data(contentsOf: url)
    
    // Decode ingredients
    let decoder = JSONDecoder()
    let importedIngredients = try decoder.decode([IngredientExport].self, from: data)
    
    // Import each ingredient
    for importedIngredient in importedIngredients {
      // Check if ingredient already exists
      var existingIngredientDescriptor = FetchDescriptor<Ingredient>(
        predicate: #Predicate<Ingredient> { $0.id == importedIngredient.id }
      )
      existingIngredientDescriptor.fetchLimit = 1
      
      if let existingIngredient = try context.fetch(existingIngredientDescriptor).first {
        // Update existing ingredient
        updateIngredient(existingIngredient, from: importedIngredient)
      } else {
        // Create new ingredient
        let ingredient = createIngredient(from: importedIngredient)
        context.insert(ingredient)
      }
    }
    
    // Save changes
    try context.save()
    return importedIngredients.count
  }
  
  /// Creates a new Recipe from imported data
  static func createRecipe(from importedRecipe: RecipeExport, context: ModelContext) -> Recipe {
    // First create and insert the recipe
    let recipe = Recipe(
      id: importedRecipe.id,
      title: importedRecipe.title,
      summary: importedRecipe.summary,
      servings: importedRecipe.servings,
      tags: importedRecipe.tags,
      rawText: importedRecipe.rawText ?? [],
      source: importedRecipe.source,
      sourceType: importedRecipe.sourceType.flatMap { SourceType(rawValue: $0) },
      sourceTitle: importedRecipe.sourceTitle,
      website: importedRecipe.website,
      author: importedRecipe.author
    )
    
    // Insert the recipe into the context first
    context.insert(recipe)
    
    // Create and insert ingredients first
    for importedIngredient in importedRecipe.ingredients {
      let ingredient = createIngredient(from: importedIngredient)
      context.insert(ingredient) // Insert into context before establishing relationship
      ingredient.recipe = recipe
      recipe.ingredients.append(ingredient)
    }
    
    // Create and insert sections with their ingredients
    for importedSection in importedRecipe.sections {
      let section = IngredientSection(
        id: importedSection.id,
        name: importedSection.name,
        position: importedSection.position
      )
      context.insert(section) // Insert into context before establishing relationship
      section.recipe = recipe
      
      // Create and insert section ingredients
      for importedIngredient in importedSection.ingredients {
        let ingredient = createIngredient(from: importedIngredient)
        context.insert(ingredient) // Insert into context before establishing relationship
        ingredient.section = section
        section.ingredients.append(ingredient)
      }
      
      recipe.sections.append(section)
    }
    
    // Create and insert timings
    for importedTiming in importedRecipe.timings {
      let timing = Timing(
        id: importedTiming.id,
        type: importedTiming.type,
        hours: importedTiming.hours,
        minutes: importedTiming.minutes
      )
      context.insert(timing) // Insert into context before establishing relationship
      timing.recipe = recipe
      recipe.timings.append(timing)
    }
    
    // Create and insert instructions
    for importedStep in importedRecipe.instructions {
      let step = Step(
        id: importedStep.id,
        value: importedStep.value,
        position: importedStep.position
      )
      context.insert(step) // Insert into context before establishing relationship
      step.recipe = recipe // Set the recipe relationship
      recipe.instructions.append(step)
    }
    
    // Create and insert notes
    for importedNote in importedRecipe.notes {
      let note = Note(
        id: importedNote.id,
        text: importedNote.text,
        position: importedNote.position
      )
      context.insert(note) // Insert into context before establishing relationship
      note.recipe = recipe // Set the recipe relationship
      recipe.notes.append(note)
    }
    
    return recipe
  }
  
  /// Updates an existing Recipe with imported data
  private static func updateRecipe(_ recipe: Recipe, from importedRecipe: RecipeExport, context: ModelContext) {
    // Update basic properties
    recipe.title = importedRecipe.title
    recipe.summary = importedRecipe.summary
    recipe.servings = importedRecipe.servings
    recipe.tags = importedRecipe.tags
    recipe.rawText = importedRecipe.rawText
    recipe.source = importedRecipe.source
    recipe.sourceType = importedRecipe.sourceType.flatMap { SourceType(rawValue: $0) }
    recipe.sourceTitle = importedRecipe.sourceTitle
    recipe.website = importedRecipe.website
    recipe.author = importedRecipe.author
    
    // First, save copies of existing relationships to delete later
    let oldIngredients = recipe.ingredients
    let oldSections = recipe.sections
    let oldTimings = recipe.timings
    let oldInstructions = recipe.instructions
    let oldNotes = recipe.notes
    
    // Clear arrays without deleting objects yet
    recipe.ingredients = []
    recipe.sections = []
    recipe.timings = []
    recipe.instructions = []
    recipe.notes = []
    
    // Recreate relationships with proper context insertion
    for importedIngredient in importedRecipe.ingredients {
      let ingredient = createIngredient(from: importedIngredient)
      context.insert(ingredient) // Insert into context before establishing relationship
      ingredient.recipe = recipe
      recipe.ingredients.append(ingredient)
    }
    
    for importedSection in importedRecipe.sections {
      let section = IngredientSection(
        id: importedSection.id,
        name: importedSection.name,
        position: importedSection.position
      )
      context.insert(section) // Insert into context before establishing relationship
      section.recipe = recipe
      
      for importedIngredient in importedSection.ingredients {
        let ingredient = createIngredient(from: importedIngredient)
        context.insert(ingredient) // Insert into context before establishing relationship
        ingredient.section = section
        section.ingredients.append(ingredient)
      }
      
      recipe.sections.append(section)
    }
    
    for importedTiming in importedRecipe.timings {
      let timing = Timing(
        id: importedTiming.id,
        type: importedTiming.type,
        hours: importedTiming.hours,
        minutes: importedTiming.minutes
      )
      context.insert(timing) // Insert into context before establishing relationship
      timing.recipe = recipe
      recipe.timings.append(timing)
    }
    
    for importedStep in importedRecipe.instructions {
      let step = Step(
        id: importedStep.id,
        value: importedStep.value,
        position: importedStep.position
      )
      context.insert(step) // Insert into context before establishing relationship
      step.recipe = recipe
      recipe.instructions.append(step)
    }
    
    for importedNote in importedRecipe.notes {
      let note = Note(
        id: importedNote.id,
        text: importedNote.text,
        position: importedNote.position
      )
      context.insert(note) // Insert into context before establishing relationship
      note.recipe = recipe
      recipe.notes.append(note)
    }
    
    // Now safely delete old objects after new relationships are established
    for ingredient in oldIngredients {
      context.delete(ingredient)
    }
    
    for section in oldSections {
      // First delete section ingredients
      for ingredient in section.ingredients {
        context.delete(ingredient)
      }
      context.delete(section)
    }
    
    for timing in oldTimings {
      context.delete(timing)
    }
    
    for instruction in oldInstructions {
      context.delete(instruction)
    }
    
    for note in oldNotes {
      context.delete(note)
    }
  }
  
  /// Creates a new Ingredient from imported data
  static func createIngredient(from importedIngredient: IngredientExport) -> Ingredient {
    return Ingredient(
      id: importedIngredient.id,
      name: importedIngredient.name,
      location: IngredientLocation(rawValue: importedIngredient.location) ?? .unknown,
      quantity: importedIngredient.quantity,
      unit: importedIngredient.unit,
      comment: importedIngredient.comment,
      position: importedIngredient.position
    )
  }
  
  /// Updates an existing Ingredient with imported data
  private static func updateIngredient(_ ingredient: Ingredient, from importedIngredient: IngredientExport) {
    ingredient.name = importedIngredient.name
    ingredient.location = IngredientLocation(rawValue: importedIngredient.location) ?? .unknown
    ingredient.quantity = importedIngredient.quantity
    ingredient.unit = importedIngredient.unit.flatMap { MeasurementUnit(from: $0) }
    ingredient.comment = importedIngredient.comment
    ingredient.position = importedIngredient.position
  }
}

// MARK: - Helper Extensions

extension DateFormatter {
  static let compactDateTime: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmm"
    return formatter
  }()
}
