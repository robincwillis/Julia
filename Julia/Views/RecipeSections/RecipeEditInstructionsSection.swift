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
  
  // Use a dedicated FocusState for the instruction fields
  @FocusState private var focusedInstructionField: Int?

  var body: some View {
    Section(header: Text("Instructions")) {
      if instructions.isEmpty {
        Text("No instructions added")
          .foregroundColor(.gray)
      } else {
        ForEach(Array(instructions.enumerated()), id: \.element) { index, _ in
          TextField("Step \(index + 1)", text: $instructions[index], axis: .vertical)
            .focused($focusedInstructionField, equals: index)
            .submitLabel(.next)
            .toolbar {
              ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button("Previous") {
                  if let focused = focusedInstructionField, focused > 0 {
                    focusedInstructionField = focused - 1
                  }
                }
                .disabled(focusedInstructionField == nil || focusedInstructionField == 0)
                
                Button("Next") {
                  if let focused = focusedInstructionField, focused < instructions.count - 1 {
                    focusedInstructionField = focused + 1
                  }
                }
                .disabled(focusedInstructionField == nil || focusedInstructionField == instructions.count - 1)
                
                Button("Done") {
                  focusedInstructionField = nil
                  isTextFieldFocused = false
                }
              }
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
  }
  
  private func addNewInstruction() {
    withAnimation {
      instructions.append("New step")
      // Focus on the newly added instruction
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        focusedInstructionField = instructions.count - 1
      }
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
    @FocusState private var focused: Bool
    
    var body: some View {
      NavigationStack {
        Form {
          RecipeEditInstructionsSection(
            instructions: $instructions,
            isTextFieldFocused: _focused
          )
        }
      }
    }
  }
  
  return PreviewWrapper()
}
