//
//  RecipeDetails.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData

// Import notification names from NavigationView
// extension is declared there

struct RecipeDetails: View {
  let recipe: Recipe
  
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) var context
  
  @State private var isEditing = false
  @State private var showingDeleteConfirmation = false
  
  // Edited recipe properties
  @State private var editedTitle = ""
  @State private var editedSummary = ""
  @State private var editedInstructions: [String] = []
  @State private var editedIngredients: [Ingredient] = []
  @State private var editedSections: [IngredientSection] = []
  @FocusState private var isTextFieldFocused: Bool
  
  var rawTextString: String {
    recipe.rawText?.joined(separator: "\n") ?? ""
  }
  
  var body: some View {
    ScrollView {
      VStack (alignment: .leading, spacing: 24) {
        if isEditing {
          TextField("Recipe Title", text: $editedTitle)
            .font(.title)
            .fontWeight(.bold)
            .padding(.vertical, 8)
            .textFieldStyle(.roundedBorder)
            .focused($isTextFieldFocused)
            .submitLabel(.done)
        }
        
        if let summary = recipe.summary, !isEditing {
          VStack (alignment: .leading) {
            Text("Summary")
              .font(.headline)
              .padding(.bottom, 6)
            Text(summary)
              .font(.caption)
          }
          Divider()
        } else if isEditing {
          VStack(alignment: .leading) {
            Text("Summary")
              .font(.headline)
              .padding(.bottom, 6)
            TextField("Recipe summary", text: $editedSummary, axis: .vertical)
              .padding(8)
              .background(Color(.systemGray6))
              .cornerRadius(8)
              .lineLimit(4...8)
              .focused($isTextFieldFocused)
              .submitLabel(.done)
              .onSubmit {
                isTextFieldFocused = false
              }
          }
          Divider()
        }
        
        // Ingredients section
        VStack (alignment: .leading) {
          HStack {
            Text("Ingredients")
              .font(.headline)
              .padding(.bottom, 6)
            
            if isEditing {
              Spacer()
              Button(action: {
                addNewSection()
              }) {
                Label("Add Section", systemImage: "plus.circle")
              }
              .buttonStyle(.bordered)
            }
          }
          
          if !isEditing {
            // Ingredients display mode
            if recipe.sections.isEmpty {
              ForEach(recipe.ingredients, id: \.self) { ingredient in
                IngredientRow(ingredient: ingredient, padding: 3)
              }
            } else {
              ForEach(recipe.sections.sorted(by: { $0.position < $1.position }), id: \.self) { section in
                VStack(alignment: .leading) {
                  Text(section.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                  
                  ForEach(section.ingredients, id: \.self) { ingredient in
                    IngredientRow(ingredient: ingredient, padding: 3)
                  }
                }
                .padding(.vertical, 4)
              }
            }
          } else {
            // Ingredients edit mode
            if editedSections.isEmpty {
              // Simple ingredient list (no sections)
              List {
                ForEach(editedIngredients.indices, id: \.self) { index in
                  HStack {
                    IngredientRow(ingredient: editedIngredients[index], padding: 3)
                    
                    Spacer()
                    
                    Button(action: {
                      editIngredient(editedIngredients[index])
                    }) {
                      Image(systemName: "pencil")
                        .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                      deleteIngredient(at: index)
                    }) {
                      Image(systemName: "trash")
                        .foregroundColor(.red)
                    }
                  }
                }
                .onMove { from, to in
                  editedIngredients.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { indexSet in
                  for index in indexSet.sorted(by: >) {
                    deleteIngredient(at: index)
                  }
                }
              }
              .listStyle(.plain)
              .environment(\.editMode, .constant(.active))
              
              Button(action: {
                addNewIngredient()
              }) {
                Label("Add Ingredient", systemImage: "plus")
                  .foregroundColor(.blue)
              }
              .padding(.vertical, 6)
            } else {
              // Sections with ingredients
              List {
                ForEach(editedSections.indices, id: \.self) { sectionIndex in
                  Section {
                    // Section header with name and controls
                    HStack {
                      TextField("Section name", text: $editedSections[sectionIndex].name)
                        .font(.headline)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                      
                      Spacer()
                      
                      Button(action: {
                        deleteSection(at: sectionIndex)
                      }) {
                        Image(systemName: "trash")
                          .foregroundColor(.red)
                      }
                    }
                    .listRowBackground(Color(.systemGray6))
                    
                    // Ingredients in this section
                    ForEach(editedSections[sectionIndex].ingredients.indices, id: \.self) { ingredientIndex in
                      HStack {
                        IngredientRow(ingredient: editedSections[sectionIndex].ingredients[ingredientIndex], padding: 3)
                        
                        Spacer()
                        
                        Button(action: {
                          editIngredient(editedSections[sectionIndex].ingredients[ingredientIndex])
                        }) {
                          Image(systemName: "pencil")
                            .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                          deleteIngredientFromSection(at: ingredientIndex, in: sectionIndex)
                        }) {
                          Image(systemName: "trash")
                            .foregroundColor(.red)
                        }
                      }
                    }
                    .onMove { from, to in
                      editedSections[sectionIndex].ingredients.move(fromOffsets: from, toOffset: to)
                    }
                    .onDelete { indexSet in
                      for index in indexSet.sorted(by: >) {
                        deleteIngredientFromSection(at: index, in: sectionIndex)
                      }
                    }
                    
                    Button(action: {
                      addNewIngredientToSection(sectionIndex)
                    }) {
                      Label("Add Ingredient", systemImage: "plus")
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                  }
                }
                .onMove { from, to in
                  editedSections.move(fromOffsets: from, toOffset: to)
                  // Update positions after moving
                  for (index, section) in editedSections.enumerated() {
                    section.position = index
                  }
                }
              }
              .listStyle(.insetGrouped)
              .environment(\.editMode, .constant(.active))
              
              Button(action: {
                addNewSection()
              }) {
                Label("Add Section", systemImage: "plus")
                  .foregroundColor(.blue)
              }
              .padding(.vertical, 6)
            }
          }
        }
        
        Divider()
        
        // Instructions section
        VStack (alignment: .leading) {
          Text("Instructions")
            .font(.headline)
            .padding(.bottom, 6)
          
          if !isEditing {
            // Instructions display mode
            ForEach(recipe.instructions.indices, id: \.self) { index in
              let step = recipe.instructions[index]
              HStack (alignment: .top, spacing: 6) {
                Text("Step \(index + 1)")
                  .foregroundColor(.blue)
                  .fontWeight(.medium)
                Text(step)
              }.padding(.vertical, 6)
            }
          } else {
            // Instructions edit mode - using List for reordering
            List {
              ForEach(editedInstructions.indices, id: \.self) { index in
                HStack(alignment: .top) {
                  Text("Step \(index + 1)")
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                    .padding(.top, 8)
                    .frame(width: 60, alignment: .leading)
                  
                  TextField("Instruction step", text: $editedInstructions[index], axis: .vertical)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                  
                  Button(action: {
                    deleteInstruction(at: index)
                  }) {
                    Image(systemName: "trash")
                      .foregroundColor(.red)
                  }
                  .padding(.leading, 8)
                }
                .padding(.vertical, 4)
              }
              .onMove { from, to in
                editedInstructions.move(fromOffsets: from, toOffset: to)
              }
              .onDelete { indexSet in
                editedInstructions.remove(atOffsets: indexSet)
              }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))
            .toolbar {
              ToolbarItem(placement: .topBarTrailing) {
                EditButton()
              }
            }
            
            Button(action: {
              addNewInstruction()
            }) {
              Label("Add Step", systemImage: "plus")
                .foregroundColor(.blue)
            }
            .padding(.vertical, 6)
          }
        }
        
        if !isEditing {
          Divider()
          
          // Raw text section
          VStack (alignment: .leading) {
            HStack (alignment: .center) {
              Text("Recognized Text")
                .font(.headline)
              Spacer()
              Button("Copy") {
                UIPasteboard.general.string = rawTextString
              }
              .buttonStyle(.bordered)
            }.padding(.bottom, 6)
            
            VStack {
              VStack(alignment: .leading, spacing: 8) {
                ForEach(recipe.rawText ?? [], id: \.self) { item in
                  Text(item)
                }
                .font(.system(.body, design: .monospaced))
              }
              .frame(width: .infinity)
              .padding()
              .foregroundColor(.secondary)
              .background(.background.secondary)
              .cornerRadius(8)
            }
          }
        }
        Spacer()
      }
      .padding()
    }
    .navigationTitle(isEditing ? "Edit Recipe" : recipe.title)
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      if isEditing {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            saveChanges()
            isEditing = false
          }
        }
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            cancelEditing()
          }
        }
      } else {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: {
            prepareForEditing()
            isEditing = true
          }) {
            Text("Edit")
          }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            Button("Delete Recipe", systemImage: "trash", role: .destructive) {
              showingDeleteConfirmation = true
            }
            
            Button("Clear All Recipes", systemImage: "clear", role: .destructive) {
              do {
                try context.delete(model: Recipe.self)
              } catch {
                print(error.localizedDescription)
              }
            }
          } label: {
            Image(systemName: "ellipsis")
              .rotationEffect(.degrees(90))
              .foregroundColor(.blue)
              .frame(width: 40, height: 40)
              .background(.tertiary)
              .clipShape(Circle())
          }
        }
      }
    }
    .confirmationDialog("Are you sure?",
                      isPresented: $showingDeleteConfirmation,
                      titleVisibility: .visible
    ) {
      Button("Delete Recipe", role: .destructive) {
        deleteRecipe()
      }
    }
    .sheet(isPresented: $showingIngredientEditor) {
      if let selectedIngredient = selectedIngredient {
        EditIngredient(ingredient: .constant(selectedIngredient))
      }
    }
    // Add toolbar with dismiss keyboard button when keyboard is visible
    .toolbar {
      ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") {
          isTextFieldFocused = false
        }
      }
    }
    .onAppear {
      NotificationCenter.default.post(name: .hideTabBar, object: nil)
    }
    .onDisappear {
      NotificationCenter.default.post(name: .showTabBar, object: nil)
    }
  }
  
  // MARK: - Edit Mode Functions
  
  private func prepareForEditing() {
    editedTitle = recipe.title
    editedSummary = recipe.summary ?? ""
    editedInstructions = recipe.instructions
    
    // Deep copy ingredients and sections for editing
    editedIngredients = recipe.ingredients
    
    // Deep copy sections
    editedSections = recipe.sections.map { section in
      let newSection = IngredientSection(id: section.id, name: section.name, position: section.position)
      newSection.ingredients = section.ingredients
      return newSection
    }
    
    // Sort sections by position
    editedSections.sort { $0.position < $1.position }
  }
  
  private func saveChanges() {
    // Update the recipe with edited values
    recipe.title = editedTitle
    recipe.summary = editedSummary.isEmpty ? nil : editedSummary
    recipe.instructions = editedInstructions
    
    if editedSections.isEmpty {
      recipe.ingredients = editedIngredients
      recipe.sections = []
    } else {
      // Ensure positions are sequential
      for (index, section) in editedSections.enumerated() {
        section.position = index
      }
      
      recipe.sections = editedSections
      recipe.ingredients = editedSections.flatMap { $0.ingredients }
    }
    
    // Save changes to context
    do {
      try context.save()
    } catch {
      print("Error saving recipe changes: \(error)")
    }
  }
  
  private func cancelEditing() {
    isEditing = false
    // No need to reset the edited values as they'll be recreated next time edit mode is entered
  }
  
  private func deleteRecipe() {
    context.delete(recipe)
    
    // We need to handle potential errors when changes are saved
    do {
      try context.save()
    } catch {
      print("Error deleting recipe: \(error)")
    }

    showingDeleteConfirmation = false
    dismiss()
  }
  
  // MARK: - Ingredient Functions
  
  private func addNewIngredient() {
    let newIngredient = Ingredient(name: "New Ingredient", location: .recipe)
    editedIngredients.append(newIngredient)
    // Open edit screen for the new ingredient
    editIngredient(newIngredient)
  }
  
  private func addNewIngredientToSection(_ sectionIndex: Int) {
    let newIngredient = Ingredient(name: "New Ingredient", location: .recipe)
    editedSections[sectionIndex].ingredients.append(newIngredient)
    // Open edit screen for the new ingredient
    editIngredient(newIngredient)
  }
  
  private func deleteIngredient(at index: Int) {
    editedIngredients.remove(at: index)
  }
  
  private func deleteIngredientFromSection(at ingredientIndex: Int, in sectionIndex: Int) {
    editedSections[sectionIndex].ingredients.remove(at: ingredientIndex)
  }
  
  @State private var selectedIngredient: Ingredient?
  @State private var showingIngredientEditor = false
  
  private func editIngredient(_ ingredient: Ingredient) {
    selectedIngredient = ingredient
    showingIngredientEditor = true
  }
  
  // MARK: - Section Functions
  
  private func addNewSection() {
    let newSection = IngredientSection(name: "New Section", position: editedSections.count)
    editedSections.append(newSection)
  }
  
  private func deleteSection(at index: Int) {
    // Move ingredients from this section to unsectioned if needed
    let sectionIngredients = editedSections[index].ingredients
    editedIngredients.append(contentsOf: sectionIngredients)
    
    editedSections.remove(at: index)
    
    // Update remaining section positions
    for i in index..<editedSections.count {
      editedSections[i].position = i
    }
  }
  
  private func moveSection(at index: Int, offset: Int) {
    let newIndex = index + offset
    guard newIndex >= 0 && newIndex < editedSections.count else { return }
    
    let movedSection = editedSections.remove(at: index)
    editedSections.insert(movedSection, at: newIndex)
    
    // Update positions
    for (i, section) in editedSections.enumerated() {
      section.position = i
    }
  }
  
  // MARK: - Instruction Functions
  
  private func addNewInstruction() {
    editedInstructions.append("New step")
  }
  
  private func deleteInstruction(at index: Int) {
    editedInstructions.remove(at: index)
  }
  
  private func moveInstruction(at index: Int, offset: Int) {
    let newIndex = index + offset
    guard newIndex >= 0 && newIndex < editedInstructions.count else { return }
    
    let movedInstruction = editedInstructions.remove(at: index)
    editedInstructions.insert(movedInstruction, at: newIndex)
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
        title: "Sample Recipe",
        summary: "A delicious sample recipe",
        ingredients: [],
        instructions: ["Step 1: Mix ingredients", "Step 2: Cook thoroughly"],
        sections: [],
        rawText: []
      )
    }
  } catch {
    print("Error fetching recipes: \(error)")
    // Error fallback
    previewRecipe = Recipe(
      title: "Sample Recipe",
      summary: "A delicious sample recipe",
      ingredients: [],
      instructions: ["Step 1: Mix ingredients", "Step 2: Cook thoroughly"],
      sections: [],
      rawText: []
    )
  }
  
  return RecipeDetails(recipe: previewRecipe)
    .modelContainer(container)
}
