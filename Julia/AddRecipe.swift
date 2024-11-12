//
//  AddRecipe.swift
//  Julia
//
//  Created by Robin Willis on 11/10/24.
//

import SwiftUI

struct AddRecipe: View {
  @AppStorage("notes") private var notes = ""
  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss

  
  @State private var editor = false;
  
  @State private var title = ""
  @State private var content = ""
  @State private var category = ""
  @State private var steps = [""]
  @State private var ingredients = [""]

  private var fakeRecipe = {}
  

  
  
  var body: some View {
    NavigationStack {
      VStack(alignment:.leading) {
        if editor {
          TextEditor(text: $notes)
            .padding()
        } else {
          TextField("", text: $notes, axis: .vertical)
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(.black)
            .tint(.blue)
            // Quasi Hack, custom placeholder text
            .background(
              ZStack{
                if notes.isEmpty {
                  HStack {
                    Text("Your notes here ...")
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
            //.textFieldStyle(.roundedBorder)

        }
        Spacer()
      }
      .padding()
      .navigationTitle("Recipe Text")
      .toolbar {
        Button("Save Recipe") {
          let newRecipe = Recipe(title: title, content: content, steps: steps)
          
          // TODO
          modelContext.insert(newRecipe)
          
          // for ingredients { ingredient in
            
          // }

        }
        .buttonStyle(.borderedProminent)
      }

    }
  }
}


#Preview {
  AddRecipe()
}
