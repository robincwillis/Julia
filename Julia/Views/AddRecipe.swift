//
//  AddRecipe.swift
//  Julia
//
//  Created by Robin Willis on 11/10/24.
//

import SwiftUI
import SwiftData
import UIKit // For UIPasteboard

// @State private var tags = []

struct AddRecipe: View {
  @Environment(\.modelContext) var context
  @Environment(\.dismiss) var dismiss
  
  var recipe: Recipe?
  var recognizedText: [String]?
  var ingredientLocation: IngredientLocation = .recipe
  
  // State variables for recipe data
  @State private var title = ""
  @State private var summary: String? = nil
  @State private var servings: Int? = nil
  @State private var ingredients = [Ingredient]()
  @State private var sections = [IngredientSection]()
  @State private var instructions = [Step]()
  @State private var timings = [Timing]()
  
  @State private var notes: [Note] = []
  @State private var tags: [String] = []
  
  @State private var source: String = ""
  @State private var sourceTitle: String = ""
  @State private var author: String = ""
  @State private var website: String = ""
  @State private var sourceType: SourceType = .manual
  
  @State private var rawText: String = ""
  
  // State for managing UI
  @State private var selectedIngredient: Ingredient?
  @State private var selectedSection: IngredientSection?
  @State private var showIngredientEditor = false
  
  @State private var focusedField: RecipeFocusedField = .none
  
  
  init(recognizedText: [String]? = [], recipe: Recipe? = nil) {
    self.recognizedText = recognizedText
    self._rawText = State(initialValue: recognizedText?.joined(separator: "\n") ?? "")
    
    self.recipe = recipe
    
    // Set initial state based on existing recipe or empty values
    if let existingRecipe = recipe {
      _title = State(initialValue: existingRecipe.title)
      _summary = State(initialValue: existingRecipe.summary)
      _servings = State(initialValue: existingRecipe.servings)
      _ingredients = State(initialValue: existingRecipe.ingredients)
      _sections = State(initialValue: existingRecipe.sections)
      _instructions = State(initialValue: existingRecipe.instructions)
      _timings = State(initialValue: existingRecipe.timings )
    }
  }
  
  var currentStrings: [String] {
    rawText
      .components(separatedBy: "\n")
      .filter { !$0.isEmpty }  // Optional: remove empty lines
  }
  
  private var ingredientEditorSheet: some View {
    FloatingBottomSheet(
      isPresented: $showIngredientEditor,
      showHideTabBar: false
    ) {
      IngredientEditor(
        ingredientLocation: ingredientLocation,
        ingredient: $selectedIngredient,
        recipe: recipe,
        section: selectedSection,
        showBottomSheet: $showIngredientEditor
      )
    }
  }
  
  var body: some View {
    ZStack {
      NavigationStack {
        Form {
          
          RecipeEditSummarySection(
            title: $title,
            summary: $summary,
            servings: $servings,
            focusedField: $focusedField
          )
          
          RecipeEditTimingsSection(
            timings: $timings
          )
          
          RecipeEditIngredientsSection(
            ingredients: $ingredients,
            sections: $sections,
            selectedIngredient: $selectedIngredient,
            selectedSection: $selectedSection,
            showIngredientEditor: $showIngredientEditor
          )
          
          // Instructions Section
          RecipeEditInstructionsSection(
            instructions: $instructions,
            focusedField: $focusedField
          )
          
          RecipeEditNotesSection(
            notes: $notes,
            focusedField: $focusedField
          )
          
          RecipeEditTagsSection(
            tags: $tags
          )
          
          RecipeEditSourceSection(
            source: $source,
            sourceTitle: $sourceTitle,
            author: $author,
            website: $website,
            sourceType: $sourceType
          )
          
          RecipeEditRawTextSection(
            rawText: $rawText,
            focusedField: $focusedField
          )
          
        }
        .scrollContentBackground(.hidden)
        .background(Color.app.backgroundSecondary)
        .navigationTitle(recipe == nil ? "Add Recipe" : "Edit Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          if focusedField.needsDoneButton {
            ToolbarItemGroup(placement: .keyboard) {
              HStack (spacing: 6) {
                if focusedField == .servings {
                  Button("Clear") {
                    servings = nil
                    if let existingRecipe = recipe {
                      existingRecipe.servings = nil
                    }
                  }.foregroundColor(.red)
                }
                
                Spacer()
                
                if focusedField == .rawText {
                  Button("Paste") {
                    if let clipboardString = UIPasteboard.general.string {
                      rawText += clipboardString
                    }
                  }
                  .foregroundColor(.white)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 3)
                  .background(Color.app.primary)
                  .cornerRadius(12)
                  .padding(.vertical, 3)
                  
                }
                
                Button("Done") {
                  hideKeyboard()
                }
                .padding(.horizontal)
              }
            }
          }
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              dismiss()
            }
          }
          
          ToolbarItem(placement: .primaryAction) {
            Button(recipe == nil ? "Save" : "Update") {
              saveRecipe()
              dismiss()
            }
            .disabled(title.isEmpty)
          }
          
        }
      }
      ingredientEditorSheet
    }
    
    .onChange(of: showIngredientEditor) { oldValue, newValue in
      // Only execute when the sheet is being dismissed
      if oldValue == true && newValue == false {
        // If we have a new ingredient that was added to the recipe but not to our local array
        if let newIngredient = selectedIngredient,
           newIngredient.recipe == recipe &&
            newIngredient.section == nil &&
            !ingredients.contains(where: { $0.id == newIngredient.id }) {
          // Add the ingredient to our local array
          ingredients.append(newIngredient)
        }
        
        // Clear the selection after handling everything
        selectedIngredient = nil
        selectedSection = nil
      }
    }
  }
  
  // TODO Update with all the New Fields
  private func saveRecipe() {
    // Validate required fields
    guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      print("Title is required")
      return
    }
    
    do {
      var newRecipe: Recipe
      
      // Determine if we're updating an existing recipe or creating a new one
      if let existingRecipe = recipe {
        // Update existing recipe
        print("Updating existing recipe")
        newRecipe = existingRecipe
        newRecipe.title = title
        
        // Update all fields
        newRecipe.summary = summary
        newRecipe.servings = servings
        newRecipe.instructions = instructions
        newRecipe.notes = notes
        newRecipe.tags = tags
        
        // Handle metadata
        newRecipe.source = source
        newRecipe.sourceType = sourceType
        newRecipe.sourceTitle = sourceTitle
        newRecipe.website = website
        newRecipe.author = author
        
        // Handle raw text
        if !rawText.isEmpty {
          let lines = rawText.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
          newRecipe.rawText = lines.isEmpty ? nil : lines
        } else {
          newRecipe.rawText = nil
        }
        
        // Clear relationships to rebuild them
        newRecipe.ingredients.removeAll()
        newRecipe.sections.removeAll()
        newRecipe.timings.removeAll()
        
      } else {
        // Parse raw text into lines if provided
        let textLines: [String] = !rawText.isEmpty ?
        rawText.components(separatedBy: .newlines)
          .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        : []
        
        // Create new recipe with all available data
        newRecipe = Recipe(
          title: title,
          summary: summary,
          ingredients: [],
          instructions: instructions,
          sections: [],
          servings: servings,
          timings: [],
          notes: notes,
          tags: tags,
          rawText: textLines,
          source: source,
          sourceType: sourceType,
          sourceTitle: sourceTitle,
          website: website,
          author: author
        )
        
        context.insert(newRecipe)
      }
      
      // Handle ingredients
      for ingredient in ingredients {
        // Ensure proper relationship
        ingredient.recipe = newRecipe
        ingredient.section = nil
        newRecipe.ingredients.append(ingredient)
      }
      
      // Handle sections and their ingredients
      for (index, section) in sections.enumerated() {
        // Update position to maintain order
        section.position = index
        
        // Ensure proper relationship
        section.recipe = newRecipe
        
        // Add section to recipe
        newRecipe.sections.append(section)
        
        // Ensure all section ingredients have proper relationships
        for ingredient in section.ingredients {
          ingredient.recipe = newRecipe
          ingredient.section = section
        }
      }
      
      // Handle timings
      for timing in timings {
        // Ensure proper relationship
        newRecipe.timings.append(timing)
      }
      
      // Save changes to context
      try context.save()
      print("Recipe saved successfully")
      dismiss()
    } catch {
      print("Error saving recipe: \(error.localizedDescription)")
      // You could show an error alert here
    }
  }
  
}


#Preview {
  struct AddRecipePreview: View {
    @State var recognizedText: [String] = ["88", "GREEN SALAD", "with Dill & Lemon Dressing", "Serves 4 to 6", "FOR THE DRESSING:", "3 tablespoons (45 milliliters) lemon", "juice (from 1/2 large lemons)", "½ teaspoon kosher salt", "¼/ cup (60 milliliters) extra-virgin", "olive oil", "FOR THE SALAD:", "1 small head romaine lettuce", "1 small head green-leaf lettuce", "¼4 cup (15 grams) roughly chopped", "fresh dill", "2 tablespoons finely chopped", "fresh chives", "This is my version of a classic Greek dish, marouli salata, which simply", "means lettuce salad. It\'s often served with sliced raw scallions but I", "substitute chives because they have a less overpowering bite. The", "freshness of the dill with the tangy lemon makes a great palate cleanser", "atter a heavy or particularly rich meal.", "Make the dressing: In a small bowl or cup, combine the lemon juice", "and salt and mix well to dissolve. Add the oil and whisk with a fork until", "emulsified.", "Make the salad: Remove any brown or wilted outer leaves from both", "heads of lettuce. Cut the lettuce crosswise into ribbons about ½2 inch", "(12 millimeters) thick. Rinse in cold water, drain, and dry in a salad spinner.", "Place the lettuce in a large serving bowl. Add the dill and chives and", "toss to combine. Drizzle with the dressing, toss well, and serve."]
    
    @State var showAddSheet = true
    
    var body: some View {
      VStack {
        Button(action: {
          showAddSheet.toggle()
        }) {
          Text("Show Add Sheet")
        }
      }
      .sheet(isPresented: $showAddSheet) {
        AddRecipe(recognizedText: recognizedText)
      }
    }
  }
  
  return AddRecipePreview()
    .modelContainer(DataController.previewContainer)
  
}
