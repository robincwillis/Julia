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
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
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
    // TODO: Delete
    do {
      context.delete(recipe)
    } catch {
      print(error)
    }

    showingDeleteConfirmation = false
    dismiss()
  }
}



#Preview {
  let recipe = {}
  let container = DataController.previewContainer
  let fetchDescriptor = FetchDescriptor<Recipe>()
  let recipes = try! container.mainContext.fetch(fetchDescriptor)
  return RecipeDetails(recipe: recipes[0])
}
