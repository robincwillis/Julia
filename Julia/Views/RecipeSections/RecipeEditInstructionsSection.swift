//
//  RecipeEditInstructionsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftUI

struct RecipeEditInstructionsSection: View {
  @Binding var instructions: [String]
  @FocusState var isTextFieldFocused: Bool
  
  var body: some View {
    Section(header: Text("Instructions")) {
      if instructions.isEmpty {
        Text("No instructions added")
          .foregroundColor(.gray)
      } else {
        ForEach(Array(instructions.enumerated()), id: \.element) { index, _ in
          TextField("Step \(index + 1)", text: $instructions[index], axis: .vertical)
            .focused($isTextFieldFocused)
            .submitLabel(.done)
        }
        .onDelete { indices in
          deleteInstruction(at: indices)
        }
        .onMove { from, to in
          moveInstruction(from: from, to: to)
        }
       }
       Button(action: {
          addNewInstruction()
        }) {
          Label("Add Step", systemImage: "plus")
            .foregroundColor(.blue)
        }
     }
  }
  
  private func addNewInstruction() {
    withAnimation {
      instructions.append("New step")
    }
  }
  
  private func deleteInstruction(at offsets: IndexSet) {
    withAnimation {
      instructions.remove(atOffsets: offsets)
    }
  }
  
  private func moveInstruction(from source: IndexSet, to destination: Int) {
    withAnimation {
      instructions.move(fromOffsets: source, toOffset: destination)
    }
  }
}

//#Preview {
//    RecipeEditInstructionsSection()
//}
