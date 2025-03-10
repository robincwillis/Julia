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
          IngredientRow(
            ingredient: ingredient,
            onTap: editIngredient,
            padding: 3
          )
            
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
            IngredientRow(ingredient: ingredient, padding: 3)
              .onTapGesture {
                editIngredient(ingredient)
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
          Label("Add Ingredient", systemImage: "plus")
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
      let newIngredient = Ingredient(name: "", location: .recipe)
      ingredients.append(newIngredient)
      // Open edit screen for the new ingredient
      editIngredient(newIngredient)
    }
  }
  
  private func addNewIngredientToSection(_ sectionIndex: Int) {
    withAnimation {
      let newIngredient = Ingredient(name: "", location: .recipe)
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
  
  private func editIngredient(_ ingredient: Ingredient?) {
    if (ingredient != nil) {
     selectedIngredient = ingredient
    }
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
#Preview {
  struct PreviewWrapper: View {
    @State private var ingredients: [Ingredient] = [
      Ingredient(name: "Flour", location: .recipe, quantity: 2, unit: "cups"),
      Ingredient(name: "Sugar", location: .recipe, quantity: 1, unit: "cup")
    ]
    @State private var sections: [IngredientSection] = [
      IngredientSection(name: "Sauce", position: 0, ingredients: [
        Ingredient(name: "Tomato", location: .recipe, quantity: 2, unit: "cups"),
        Ingredient(name: "Garlic", location: .recipe, quantity: 2, unit: "cloves")
      ]),
      IngredientSection(name: "Garnish", position: 1, ingredients: [
        Ingredient(name: "Parsley", location: .recipe, quantity: 0.25, unit: "cup")
      ])
    ]
    @State private var selectedIngredient: Ingredient?
    @State private var showIngredientEditor = false
    @FocusState private var focused: Bool
    
    var body: some View {
      NavigationStack {
        Form {
          RecipeEditIngredientsSection(
            ingredients: $ingredients,
            sections: $sections,
            selectedIngredient: $selectedIngredient,
            showIngredientEditor: $showIngredientEditor,
            isTextFieldFocused: _focused
          )
        }
      }
    }
  }
  
  return PreviewWrapper()
}
