import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
class ImportExportManager {

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
    let instructionSections: [InstructionSectionExport]?
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

  struct InstructionSectionExport: Codable {
    let id: String
    let name: String
    let position: Int
    let steps: [StepExport]
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

  static func exportRecipes(context: ModelContext) async -> (URL?, Error?) {
    do {
      let url = try await createRecipesExport(context: context)
      return (url, nil)
    } catch {
      print("Export error: \(error.localizedDescription)")
      return (nil, error)
    }
  }

  static func exportIngredients(context: ModelContext) async -> (URL?, Error?) {
    do {
      let url = try await createIngredientsExport(context: context)
      return (url, nil)
    } catch {
      print("Export error: \(error.localizedDescription)")
      return (nil, error)
    }
  }

  static func createRecipesExport(context: ModelContext) async throws -> URL {
    let recipesDescriptor = FetchDescriptor<Recipe>()
    let recipes = try context.fetch(recipesDescriptor)

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
        instructionSections: recipe.instructionSections.map { section in
          InstructionSectionExport(
            id: section.id,
            name: section.name,
            position: section.position,
            steps: section.steps.map { step in
              StepExport(
                id: step.id,
                value: step.value,
                position: step.position
              )
            }
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

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try encoder.encode(exportRecipes)

    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("Julia-Recipes-\(DateFormatter.compactDateTime.string(from: Date())).json")

    try jsonData.write(to: tempURL)
    return tempURL
  }

  private static func createIngredientsExport(context: ModelContext) async throws -> URL {
    let ingredientsDescriptor = FetchDescriptor<Ingredient>(
      predicate: #Predicate<Ingredient> { $0.recipe == nil && $0.section == nil }
    )
    let ingredients = try context.fetch(ingredientsDescriptor)

    let exportIngredients = ingredients.map { exportIngredient($0) }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try encoder.encode(exportIngredients)

    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("Julia-Ingredients-\(DateFormatter.compactDateTime.string(from: Date())).json")

    try jsonData.write(to: tempURL)
    return tempURL
  }

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

  static func importRecipesFile(from url: URL, context: ModelContext) async throws -> Int {
    let data: Data
    do {
      data = try Data(contentsOf: url)
      print("Successfully read file data: \(data.count) bytes")
    } catch {
      print("Error reading file: \(error)")
      throw ImportError.fileReadError(error)
    }

    let decoder = JSONDecoder()
    let importedRecipes: [RecipeExport]

    do {
      importedRecipes = try decoder.decode([RecipeExport].self, from: data)
      print("Successfully decoded \(importedRecipes.count) recipes")
    } catch {
      print("JSON decoding error: \(error)")
      if let sample = String(data: data.prefix(100), encoding: .utf8) {
        print("Data sample: \(sample)...")
      }
      throw ImportError.jsonDecodingError(error)
    }

    var importedCount = 0
    for (index, importedRecipe) in importedRecipes.enumerated() {
      do {
        var existingRecipeDescriptor = FetchDescriptor<Recipe>(
          predicate: #Predicate<Recipe> { $0.id == importedRecipe.id }
        )
        existingRecipeDescriptor.fetchLimit = 1

        if let existingRecipe = try context.fetch(existingRecipeDescriptor).first {
          print("Updating existing recipe: \(importedRecipe.title)")
          updateRecipe(existingRecipe, from: importedRecipe, context: context)
        } else {
          print("Creating new recipe: \(importedRecipe.title)")
          let _ = createRecipe(from: importedRecipe, context: context)
        }
        importedCount += 1
      } catch {
        print("Error processing recipe \(index): \(error)")
        throw ImportError.recipeProcessingError(index: index, error: error)
      }
    }

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

  static func importIngredientsFile(from url: URL, context: ModelContext) async throws -> Int {
    let data = try Data(contentsOf: url)

    let decoder = JSONDecoder()
    let importedIngredients = try decoder.decode([IngredientExport].self, from: data)

    for importedIngredient in importedIngredients {
      var existingIngredientDescriptor = FetchDescriptor<Ingredient>(
        predicate: #Predicate<Ingredient> { $0.id == importedIngredient.id }
      )
      existingIngredientDescriptor.fetchLimit = 1

      if let existingIngredient = try context.fetch(existingIngredientDescriptor).first {
        updateIngredient(existingIngredient, from: importedIngredient)
      } else {
        let ingredient = createIngredient(from: importedIngredient)
        context.insert(ingredient)
      }
    }

    try context.save()
    return importedIngredients.count
  }

  static func createRecipe(from importedRecipe: RecipeExport, context: ModelContext) -> Recipe {
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

    context.insert(recipe)

    for importedIngredient in importedRecipe.ingredients {
      let ingredient = createIngredient(from: importedIngredient)
      context.insert(ingredient)
      ingredient.recipe = recipe
      recipe.ingredients.append(ingredient)
    }

    for importedSection in importedRecipe.sections {
      let section = IngredientSection(
        id: importedSection.id,
        name: importedSection.name,
        position: importedSection.position
      )
      context.insert(section)
      section.recipe = recipe

      for importedIngredient in importedSection.ingredients {
        let ingredient = createIngredient(from: importedIngredient)
        context.insert(ingredient)
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
      context.insert(timing)
      timing.recipe = recipe
      recipe.timings.append(timing)
    }

    for importedStep in importedRecipe.instructions {
      let step = Step(
        id: importedStep.id,
        value: importedStep.value,
        position: importedStep.position
      )
      context.insert(step)
      step.recipe = recipe
      recipe.instructions.append(step)
    }

    for importedSection in importedRecipe.instructionSections ?? [] {
      let section = InstructionSection(
        id: importedSection.id,
        name: importedSection.name,
        position: importedSection.position
      )
      context.insert(section)
      section.recipe = recipe

      for importedStep in importedSection.steps {
        let step = Step(
          id: importedStep.id,
          value: importedStep.value,
          position: importedStep.position
        )
        context.insert(step)
        step.section = section
        section.steps.append(step)
      }

      recipe.instructionSections.append(section)
    }

    for importedNote in importedRecipe.notes {
      let note = Note(
        id: importedNote.id,
        text: importedNote.text,
        position: importedNote.position
      )
      context.insert(note)
      note.recipe = recipe
      recipe.notes.append(note)
    }

    return recipe
  }

  private static func updateRecipe(_ recipe: Recipe, from importedRecipe: RecipeExport, context: ModelContext) {
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

    let oldIngredients = recipe.ingredients
    let oldSections = recipe.sections
    let oldTimings = recipe.timings
    let oldInstructions = recipe.instructions
    let oldInstructionSections = recipe.instructionSections
    let oldNotes = recipe.notes

    recipe.ingredients = []
    recipe.sections = []
    recipe.timings = []
    recipe.instructions = []
    recipe.instructionSections = []
    recipe.notes = []

    for importedIngredient in importedRecipe.ingredients {
      let ingredient = createIngredient(from: importedIngredient)
      context.insert(ingredient)
      ingredient.recipe = recipe
      recipe.ingredients.append(ingredient)
    }

    for importedSection in importedRecipe.sections {
      let section = IngredientSection(
        id: importedSection.id,
        name: importedSection.name,
        position: importedSection.position
      )
      context.insert(section)
      section.recipe = recipe

      for importedIngredient in importedSection.ingredients {
        let ingredient = createIngredient(from: importedIngredient)
        context.insert(ingredient)
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
      context.insert(timing)
      timing.recipe = recipe
      recipe.timings.append(timing)
    }

    for importedStep in importedRecipe.instructions {
      let step = Step(
        id: importedStep.id,
        value: importedStep.value,
        position: importedStep.position
      )
      context.insert(step)
      step.recipe = recipe
      recipe.instructions.append(step)
    }

    for importedSection in importedRecipe.instructionSections ?? [] {
      let section = InstructionSection(
        id: importedSection.id,
        name: importedSection.name,
        position: importedSection.position
      )
      context.insert(section)
      section.recipe = recipe

      for importedStep in importedSection.steps {
        let step = Step(
          id: importedStep.id,
          value: importedStep.value,
          position: importedStep.position
        )
        context.insert(step)
        step.section = section
        section.steps.append(step)
      }

      recipe.instructionSections.append(section)
    }

    for importedNote in importedRecipe.notes {
      let note = Note(
        id: importedNote.id,
        text: importedNote.text,
        position: importedNote.position
      )
      context.insert(note)
      note.recipe = recipe
      recipe.notes.append(note)
    }

    for ingredient in oldIngredients {
      context.delete(ingredient)
    }

    for section in oldSections {
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

    for section in oldInstructionSections {
      for step in section.steps {
        context.delete(step)
      }
      context.delete(section)
    }

    for note in oldNotes {
      context.delete(note)
    }
  }

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

  private static func updateIngredient(_ ingredient: Ingredient, from importedIngredient: IngredientExport) {
    ingredient.name = importedIngredient.name
    ingredient.location = IngredientLocation(rawValue: importedIngredient.location) ?? .unknown
    ingredient.quantity = importedIngredient.quantity
    ingredient.unit = importedIngredient.unit.flatMap { MeasurementUnit(from: $0) }
    ingredient.comment = importedIngredient.comment
    ingredient.position = importedIngredient.position
  }
}

extension DateFormatter {
  static let compactDateTime: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmm"
    return formatter
  }()
}
