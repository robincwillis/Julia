//
//  AddRecipe.swift
//  Julia
//
//  Created by Robin Willis on 11/10/24.
//

import SwiftUI
import SwiftData

struct AddRecipe: View {
  @Environment(\.modelContext) var context
  @Environment(\.dismiss) var dismiss
  
  var recipe: Recipe?
  var recognizedText: [String]?
  
  @State private var title = ""
  @State private var summary = ""
  @State private var tags = []
  @State private var instructions = []
  @State private var ingredients = [Ingredient]()
  @State private var rawText: String = ""
  
  init(recognizedText: [String]? = [], recipe: Recipe? = nil) {
    self.recognizedText = recognizedText
    self._rawText = State(initialValue: recognizedText?.joined(separator: "\n") ?? "")

    //self.recipe = recipe
    
    // Set initial state based on existing recipe or empty strings
    _title = State(initialValue: recipe?.title ?? "")
    // _ingredients = State(initialValue: recipe?.ingredients ?? [])
    //_instructions = State(initialValue: recipe?.instructions ?? "")
  }
  
  var currentStrings: [String] {
    rawText
      .components(separatedBy: "\n")
      .filter { !$0.isEmpty }  // Optional: remove empty lines
  }
  
  var body: some View {
    NavigationStack {
      VStack(alignment:.leading, spacing: 24) {
        TextField("", text: $title, axis: .vertical)
          .font(.system(size: 24, weight: .medium))
          .foregroundColor(.black)
          .tint(.blue)
        // Quasi Hack, custom placeholder text
          .background(
            ZStack{
              if title.isEmpty {
                HStack {
                  Text("Add Title ...")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.gray)
                  Spacer()
                }
              }
            }
          )
          .padding()
          .background(.gray.opacity(0.1))
          .cornerRadius(12)
        
        HStack(alignment: .center) {
          Text("Recognized Text")
          .font(.headline)
          
          Spacer()
          
          Button("Copy to Clipboard") {
            UIPasteboard.general.string = rawText
          }
          .buttonStyle(.bordered)
        }
        
        TextEditor(text: $rawText)
          .font(.system(.body, design: .monospaced))
          .padding(8)
          .frame(minHeight: 200)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.gray.opacity(0.2), lineWidth: 1)
          )
      }
      .padding(.horizontal)
      .navigationTitle(recipe == nil ? "Add Recipe" : "Edit Recipe")
      .toolbar {
        Button(recipe == nil ? "Save Recipe" : "Update Recipe") {
          saveRecipe()
        }
        .buttonStyle(.borderedProminent)
        .disabled(title.isEmpty)
        
        Button("Cancel") {
          dismiss()
        }
      }
      
    }.onAppear {
      if recipe != nil {
        print("editing existing recipe")
      }
    }
  }
  
  private func saveRecipe() {
    print("save recipe")
    var newRecipe: Recipe
    do {
      if recipe != nil {
        print("update existing recipe")
        // update existing recipe
         newRecipe = recipe ?? Recipe(title: title)
         newRecipe.title = title
        
      } else {
        if !currentStrings.isEmpty {
          print("save new recipe with title & rawText")
          print(currentStrings)
          newRecipe = Recipe(title: title, rawText: currentStrings)
        } else {
          print("save new recipe with title")
          newRecipe = Recipe(title: title)
        }
        // create new recipe
        print("insert the new recipe")
        context.insert(newRecipe)
      }
      print("context save")
      try context.save()
      dismiss()
    } catch {
      print(error)
    }
  }
  
}


#Preview {
  let rawText = ["88", "GREEN SALAD", "with Dill & Lemon Dressing", "Serves 4 to 6", "FOR THE DRESSING:", "3 tablespoons (45 milliliters) lemon", "juice (from 1/2 large lemons)", "½ teaspoon kosher salt", "¼/ cup (60 milliliters) extra-virgin", "olive oil", "FOR THE SALAD:", "1 small head romaine lettuce", "1 small head green-leaf lettuce", "¼4 cup (15 grams) roughly chopped", "fresh dill", "2 tablespoons finely chopped", "fresh chives", "This is my version of a classic Greek dish, marouli salata, which simply", "means lettuce salad. It\'s often served with sliced raw scallions but I", "substitute chives because they have a less overpowering bite. The", "freshness of the dill with the tangy lemon makes a great palate cleanser", "atter a heavy or particularly rich meal.", "Make the dressing: In a small bowl or cup, combine the lemon juice", "and salt and mix well to dissolve. Add the oil and whisk with a fork until", "emulsified.", "Make the salad: Remove any brown or wilted outer leaves from both", "heads of lettuce. Cut the lettuce crosswise into ribbons about ½2 inch", "(12 millimeters) thick. Rinse in cold water, drain, and dry in a salad spinner.", "Place the lettuce in a large serving bowl. Add the dill and chives and", "toss to combine. Drizzle with the dressing, toss well, and serve."]
  @State var recognizedText: [String] = rawText
  return AddRecipe(recognizedText: recognizedText)
    .modelContainer(DataController.previewContainer)
}
