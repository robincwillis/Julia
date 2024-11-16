//
//  AddRecipe.swift
//  Julia
//
//  Created by Robin Willis on 11/10/24.
//

import SwiftUI

struct AddRecipe: View {
  @Environment(\.modelContext) var context
  @Environment(\.dismiss) var dismiss
  
  var recognizedText: [String]
  
  @State private var rawText: String
  init(recognizedText: [String]) {
    self.recognizedText = recognizedText
    self._rawText = State(initialValue: recognizedText.joined(separator: "\n"))
  }
  //@AppStorage("notes") private var notes = ""
  
  @State private var title = ""
  @State private var content = ""
  @State private var category = ""
  @State private var steps = [""]
  @State private var ingredients = [""]
  
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
          .cornerRadius(24)
        
        TextEditor(text: $rawText)
          .font(.system(.body, design: .monospaced))
          .frame(height: 200)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.gray.opacity(0.2), lineWidth: 1)
          )
        
        Spacer()
      }
      .padding()
      .navigationTitle("Add Recipe")
      .toolbar {
        Button("Copy to Clipboard") {
          UIPasteboard.general.string = rawText
        }
        .buttonStyle(.bordered)
        Button("Save Recipe") {
          saveRecipe()
        }
        .buttonStyle(.borderedProminent)
      }
      
    }
  }
  
  private func saveRecipe() {
    do {
      
      
      var newRecipe: Recipe
      if !currentStrings.isEmpty {
        print("save recipe with rawtext")
        print(rawText)
        print(currentStrings)
        newRecipe = Recipe(title: title, rawText: currentStrings)
      } else {
        print("do something else")
        newRecipe = Recipe(title: title, content: content, steps: steps)
      }
      
      // TODO
      context.insert(newRecipe)
      
      try context.save()
    } catch {
      print(error)
    }
  }
  
}


#Preview {
  @State var recognizedText: [String] = []
  return AddRecipe(recognizedText: recognizedText)
    .modelContainer(DataController.previewContainer)
}
