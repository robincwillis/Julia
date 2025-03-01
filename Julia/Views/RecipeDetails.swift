//
//  RecipeDetails.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData

struct RecipeDetails: View {
  let recipe: Recipe
  
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) var context
  
  @State private var isEditing = false
  @State private var showingDeleteConfirmation = false

  var rawTextString: String {
    recipe.rawText!.joined(separator: "\n")
  }
  
  var body: some View {
    ScrollView {
      VStack (alignment: .leading, spacing: 24) {
        
        if let summary = recipe.summary {
          VStack (alignment: .leading){
            Text("Summary")
              .font(.headline)
              .padding(.bottom, 6)
            Text(summary)
              .font(.caption)
          }
          Divider()
        }
        
        VStack (alignment: .leading) {
          Text("Ingredients")
            .font(.headline)
            .padding(.bottom, 6)
          ForEach(recipe.ingredients, id: \.self) { ingredient in
            IngredientRow(ingredient: ingredient, padding: 3)
          }
        }
        
        
        Divider()
        
        VStack (alignment: .leading) {
          Text("Instructions")
            .font(.headline)
            .padding(.bottom, 6)
          
          ForEach(recipe.instructions.indices, id: \.self) {index in
            let step = recipe.instructions[index]
            HStack (alignment: .top, spacing: 6) {
              Text("Step \(index + 1)")
                .foregroundColor(.blue)
                .fontWeight(.medium)
              Text(step)
              
            }.padding(.vertical, 6)
          }
        }
        
        Divider()
        
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
              .font(.system(.body, design: .monospaced)) // Monospaced system font
              
            }
            .frame(width: .infinity)
            .padding()
            .foregroundColor(.secondary) // Dark grey text
            .background(.background.secondary) // Light grey background
            .cornerRadius(8)
            
          }
        }
        Spacer()
      }
      .padding()
      
    }
    .navigationTitle(recipe.title)
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      Menu {
        NavigationLink(destination: AddRecipe(recipe: recipe)) {
          Label("Edit Recipe", systemImage: "pencil")
        }
        Button("Delete Recipe", systemImage: "trash", role: .destructive) {
          showingDeleteConfirmation = true
        }
        
        Button("Clear Recipes", systemImage: "clear", role: .destructive) {
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
    .confirmationDialog("Are you sure?",
                        isPresented: $showingDeleteConfirmation,
                        titleVisibility: .visible
    ) {
      Button("Delete Recipe", role: .destructive) {
        deleteRecipe()
      }
    }
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
