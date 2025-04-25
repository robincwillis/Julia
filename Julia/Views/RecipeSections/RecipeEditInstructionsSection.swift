//
//  RecipeEditInstructionsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftUI

struct RecipeEditInstructionsSection: View {
  @Binding var instructions: [Step]
  @State private var newStepText: String = ""

  @Binding var focusedField: RecipeFocusedField
  
  @FocusState private var focusedInstructionField: String?
  
  private let toolbarID = "instructionsToolbar"
  var body: some View {
    Section(header: Text("Instructions")) {
      if instructions.isEmpty {
        Text("No instructions added")
          .foregroundColor(Color.app.textLabel)
      } else {
        let sortedInstructions: [Step] = instructions.sorted { $0.position < $1.position }

        ForEach(sortedInstructions, id: \.id) { step in
          if let stepIndex = instructions.firstIndex(where: { $0.id == step.id }) {
            TextField("Step \(step.id)", text: $instructions[stepIndex].value, axis: .vertical)
              .focused($focusedInstructionField, equals: step.id)
              .onSubmit {
                focusedInstructionField = nil
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
      HStack {
        TextField("Add a step", text: $newStepText)
          .submitLabel(.done)
          .focused($focusedInstructionField, equals: "new")
          .onSubmit {
            focusedInstructionField = nil
          }
        
        Button(action: addNewInstruction) {
          Image(systemName: "plus.circle.fill")
        }
        .disabled(newStepText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding(.top, 4)
      
    }
    .onChange(of: focusedInstructionField) { _, newValue in
      if let stepId =  newValue {
        focusedField = .instruction(stepId)
      } else {
        focusedField = .none
      }
    }
  }
  
  
  private func addNewInstruction() {
    let stepText = newStepText.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if !stepText.isEmpty {
      withAnimation {
        instructions.append(Step(value:stepText))
        newStepText = ""
      }
    }
  }
  
  private func deleteInstruction(at offsets: IndexSet) {
    withAnimation {
      instructions.remove(atOffsets: offsets)
    }
  }
  
  private func moveInstruction(from source: IndexSet, to destination: Int) {
    var sortedInstructions = instructions.sorted { $0.position < $1.position }
    sortedInstructions.move(fromOffsets: source, toOffset: destination)
    for (index, step) in sortedInstructions.enumerated() {
      step.position = index
    }
    instructions.move(fromOffsets: source, toOffset: destination)
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var instructions = [
      Step(value:"Preheat oven to 350°F (175°C)", position: 0),
      Step(value:"Mix flour, sugar, and salt in a large bowl", position: 1),
      Step(value:"Add butter and mix until crumbly", position: 2),
      Step(value:"Press mixture into the bottom of a 9x13 inch baking pan", position: 3),
      Step(value:"Bake for 15-18 minutes until lightly golden", position: 4)
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
