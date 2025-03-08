//
//  RecipeEditIngredientsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftUI

struct RecipeEditIngredientsSection: View {
  @Binding var ingredients: [Ingredient]
  @Binding var sections: [IngredientSection]
  @Binding var selectedIngredient: Ingredient?
  @Binding var showIngredientEditor: Bool
  @FocusState var isTextFieldFocused: Bool
  
  var body: some View {
    // Unsectioned ingredients section
    Section(header: Text("Ingredients")) {
      if ingredients.isEmpty {
        Text("No ingredients added")
          .foregroundColor(.gray)
      } else {
        ForEach(ingredients) { ingredient in
          HStack {
            Button(action: {
              editIngredient(ingredient)
            }) {
              Text(ingredient.name)
            }
          }
        }
        .onDelete { indices in
          deleteIngredient(at: indices)
        }
        .onMove { from, to in
          moveIngredient(from: from, to: to)
        }
      }
      
      Button(action: addNewIngredient) {
        Label("Add Ingredient", systemImage: "plus")
          .foregroundColor(.blue)
      }
    }
    
    // Sections
    // Ingredient Sections Section
    ForEach($sections.indices, id: \.self) { sectionIndex in
      Section {
        TextField("Section name", text: $sections[sectionIndex].name)
          .font(.headline)
          .focused($isTextFieldFocused)
        
        if sections[sectionIndex].ingredients.isEmpty {
          Text("No ingredients in this section")
            .foregroundColor(.secondary)
            .italic()
        } else {
          ForEach(sections[sectionIndex].ingredients) { ingredient in
            HStack {
              Button(action: {
                selectedIngredient = ingredient
                showIngredientEditor = true
              }) {
                Text(ingredient.name)
                  .font(.body)

              }
            }
          }
          .onDelete { indices in
            deleteIngredientFromSection(at: indices, in: sectionIndex)
          }
          .onMove { from, to in
            moveIngredientInSection(from: from, to: to, inSection: sectionIndex)
          }
        }
        
        Button {
          addNewIngredientToSection(sectionIndex)
        } label: {
          Label("Add to Section", systemImage: "plus")
            .foregroundColor(.blue)
        }
      } header: {
        HStack {
          Text(sections[sectionIndex].name.isEmpty ? "Section \(sectionIndex + 1)" : sections[sectionIndex].name)
          Spacer()
          Button(action: {
            deleteSection(at: sectionIndex)
          }) {
            Image(systemName: "trash")
              .foregroundColor(.red)
              .font(.caption)
          }
        }
      }
    }
    .onMove { from, to in
      moveSection(from: from, to: to)
    }
    // Add section button
    Section {
      Button(action: addNewSection) {
        Label("Add Section", systemImage: "plus")
          .foregroundColor(.blue)
      }
    }
  }
  
  
  private func addNewIngredient() {
    withAnimation {
      let newIngredient = Ingredient(name: "New Ingredient", location: .recipe)
      ingredients.append(newIngredient)
      // Open edit screen for the new ingredient
      editIngredient(newIngredient)
    }
  }
  
  private func addNewIngredientToSection(_ sectionIndex: Int) {
    withAnimation {
      let newIngredient = Ingredient(name: "New Ingredient", location: .recipe)
      sections[sectionIndex].ingredients.append(newIngredient)
      // Open edit screen for the new ingredient
      editIngredient(newIngredient)
    }
  }
  
  private func deleteIngredient(at indices: IndexSet) {
    withAnimation {
      ingredients.remove(atOffsets: indices)
    }
  }
  
  private func moveIngredient(from source: IndexSet, to destination: Int) {
    //withAnimation {
    ingredients.move(fromOffsets: source, toOffset: destination)
    //}
  }
  
  private func moveIngredientInSection(from source: IndexSet, to destination: Int, inSection sectionIndex: Int) {
    if sections.count > sectionIndex {
      sections[sectionIndex].ingredients.move(fromOffsets: source, toOffset: destination)
    }
  }
  
  private func moveSection(from source: IndexSet, to destination: Int) {
    //withAnimation {
    sections.move(fromOffsets: source, toOffset: destination)
    //}
  }
  
  
  // Delete ingredients from a section
  private func deleteIngredientFromSection(at indices: IndexSet, in sectionIndex: Int) {
    withAnimation {
      if sections.count > sectionIndex {
        sections[sectionIndex].ingredients.remove(atOffsets: indices)
      }
    }
  }
  
  private func editIngredient(_ ingredient: Ingredient) {
    selectedIngredient = ingredient
    showIngredientEditor = true
  }
  
  private func addNewSection() {
    withAnimation {
      let newSection = IngredientSection(name: "New Section", position: sections.count)
      sections.append(newSection)
    }
  }
  
  private func deleteSection(at index: Int) {
    withAnimation {
      // Move ingredients from this section to unsectioned if needed
      let sectionIngredients = sections[index].ingredients
      ingredients.append(contentsOf: sectionIngredients)
      
      sections.remove(at: index)
      
      // Update remaining section positions
      for i in index..<sections.count {
        sections[i].position = i
      }
    }
  }
  
}
// #Preview {
//  let container = DataController.previewContainer
//  let fetchDescriptor = FetchDescriptor<Recipe>()
//  let recipes = try container.mainContext.fetch(fetchDescriptor)
//  let previewRecipe = recipes.first
//  @Bindable var ingredients = previewRecipe.ingredients
//  @Bindable var sections: previewRecipe.ingredients
//  @State var selectedIngredient: Ingredient?
//  @State var showingIngredientEditor = false
//  
//  RecipeEditIngredientsSection(
//    ingredients: ingredients,
//    sections: sections,
//    selectedIngredient: selectedIngredient,
//    showIngredientEditor: showingIngredientEditor
//  ).modelContainer(container)
// }
