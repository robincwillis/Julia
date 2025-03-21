//
//  AddRecipe.swift
//  Julia
//
//  Created by Robin Willis on 11/10/24.
//

import SwiftUI
import SwiftData
import UIKit // For UIPasteboard

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
  
  @FocusState var isRawTextFieldFocused: Bool

  
  init(recognizedText: [String]? = [], recipe: Recipe? = nil) {
    self.recognizedText = recognizedText
    self._rawText = State(initialValue: recognizedText?.joined(separator: "\n") ?? "")

    self.recipe = recipe
    
    // Set initial state based on existing recipe or empty strings
    _title = State(initialValue: recipe?.title ?? "")
    _ingredients = State(initialValue: recipe?.ingredients ?? [])
  }
  
  var currentStrings: [String] {
    rawText
      .components(separatedBy: "\n")
      .filter { !$0.isEmpty }  // Optional: remove empty lines
  }
  
  var body: some View {
    NavigationStack {
      Form {
        TextField("Recipe Title", text: $title, axis: .vertical)
          //.font(.system(size: 24, weight: .medium))
          .font(.title)
          //.padding(.horizontal, 12)
          .padding(.vertical, 2)
          .shadow(color: Color.gray.opacity(0.1), radius: 2)
          .cornerRadius(12)
          .submitLabel(.done)
        Section {
          TextEditor(text: $rawText)
            .font(.system(size: 12, design: .monospaced))
            //.padding(0)
            .frame(minHeight: 200)
            .frame(maxWidth: .infinity)
            .foregroundColor(.secondary)
            .background(.white)
            .cornerRadius(12)
            .focused($isRawTextFieldFocused)
            .onSubmit {
              isRawTextFieldFocused = false
            }
            .toolbar {
              ToolbarItemGroup(placement: .keyboard) {
                if isRawTextFieldFocused {
                  Spacer()
                  Button("Done") {
                    isRawTextFieldFocused = false
                  }
                }
              }
            }
        } header: {
          HStack(alignment: .center) {
            Text("Recipe Text")
            Spacer()
            Button("Paste from Clipboard") {
              if let clipboardString = UIPasteboard.general.string {
                rawText += clipboardString
              }
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.85, green: 0.92, blue: 1.0))
            .cornerRadius(8)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          
        }
      }
      .background(Color(.secondarySystemBackground))
      .navigationTitle(recipe == nil ? "Add Recipe" : "Edit Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.blue)
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
    .onAppear {
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
          // Create recipe with the updated model structure
          newRecipe = Recipe(
            title: title, 
            rawText: currentStrings
            // time is optional, so we don't need to provide it
          )
        } else {
          print("save new recipe with title")
          // Create recipe with the updated model structure
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
