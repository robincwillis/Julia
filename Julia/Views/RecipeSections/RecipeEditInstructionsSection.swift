//
//  RecipeEditInstructionsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftUI

struct RecipeEditInstructionsSection: View {
  @Binding var instructions: [String]
  @Binding var focusedField: RecipeFocusedField
  
  @FocusState private var focusedInstructionField: Int?
  

  private let toolbarID = "instructionsToolbar"
  var body: some View {
    Section(header: Text("Instructions")) {
      if instructions.isEmpty {
        Text("No instructions added")
          .foregroundColor(.gray)
      } else {
        ForEach(0..<instructions.count, id: \.self) { index in
          TextField("Step \(index + 1)", text: $instructions[index], axis: .vertical)
            .focused($focusedInstructionField, equals: index)
            .onSubmit {
              focusedInstructionField = nil
            }
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
    .onChange(of: focusedInstructionField) { _, newValue in
      if let index = newValue {
        focusedField = .instruction(index)
      } else {
        focusedField = .none
      }
    }
  }
  
  private func addNewInstruction() {
    withAnimation {
      instructions.append("New step")
      // Focus on the newly added instruction
      //DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      focusedInstructionField = instructions.count - 1
      //}
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

#Preview {
  struct PreviewWrapper: View {
    @State private var instructions = [
      "Preheat oven to 350°F (175°C)",
      "Mix flour, sugar, and salt in a large bowl",
      "Add butter and mix until crumbly",
      "Press mixture into the bottom of a 9x13 inch baking pan",
      "Bake for 15-18 minutes until lightly golden"
    ]
    
    @State private var focusedField: RecipeFocusedField = .none

    var body: some View {
      NavigationStack {
        Form {
          RecipeEditInstructionsSection(
            instructions: $instructions,
            focusedField: $focusedField
          )
        }
      }
    }
  }
  
  return PreviewWrapper()
}
