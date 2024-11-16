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
  
  
  var rawTextString: String {
    recipe.rawText!.joined(separator: "\n")
  }
  
  var body: some View {
    ScrollView {
      VStack (alignment: .leading, spacing: 24) {
        
        if let description = recipe.content {
          VStack (alignment: .leading){
            Text("Description")
              .font(.headline)
              .padding(.bottom, 6)
            Text(description)
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
          Text("Steps")
            .font(.headline)
            .padding(.bottom, 6)
          
          ForEach(recipe.steps.indices, id: \.self) {index in
            let step = recipe.steps[index]
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
  }
}



#Preview {
  let recipe = {}
  let container = DataController.previewContainer
  let fetchDescriptor = FetchDescriptor<Recipe>()
  let recipes = try! container.mainContext.fetch(fetchDescriptor)
  return RecipeDetails(recipe: recipes[0])
}
