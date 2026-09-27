//
//  RecipeEditInstructionsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftUI

struct RecipeEditInstructionsSection: View {
  @Binding var instructions: [Step]
  @Binding var instructionSections: [InstructionSection]
  @State private var newStepText: String = ""

  @Binding var focusedField: RecipeFocusedField

  @FocusState private var focusedInstructionField: String?

  var body: some View {
    Section(header: Text("Instructions")) {
      if instructions.isEmpty {
        Text("No instructions added")
          .foregroundColor(Color.app.labelPrimary)
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
            .foregroundStyle(Color.app.primary)
        }
        .disabled(newStepText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding(.top, 4)

    }
    .listRowBackground(Color.app.backgroundSheet)
    .onChange(of: focusedInstructionField) { _, newValue in
      if let stepId =  newValue {
        focusedField = .instruction(stepId)
      } else {
        focusedField = .none
      }
    }

    // Instruction sections — e.g. "For the Dressing"
    ForEach($instructionSections.indices, id: \.self) { sectionIndex in
      InstructionSectionEditor(
        section: $instructionSections[sectionIndex],
        focusedField: $focusedField,
        onDelete: { deleteInstructionSection(at: sectionIndex) }
      )
    }
    .onMove { from, to in
      moveInstructionSection(from: from, to: to)
    }

    Section {
      Button(action: addNewInstructionSection) {
        Label("Add Section", systemImage: "plus")
          .foregroundStyle(Color.app.primary)
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

  private func addNewInstructionSection() {
    withAnimation {
      let newSection = InstructionSection(name: "New Section", position: instructionSections.count)
      instructionSections.append(newSection)
    }
  }

  private func deleteInstructionSection(at index: Int) {
    withAnimation {
      // Move steps from this section back to unsectioned rather than losing them
      let sectionSteps = instructionSections[index].steps
      instructions.append(contentsOf: sectionSteps)
      for step in sectionSteps {
        step.section = nil
      }

      instructionSections.remove(at: index)

      // Update remaining section positions
      for i in index..<instructionSections.count {
        instructionSections[i].position = i
      }
    }
  }

  private func moveInstructionSection(from source: IndexSet, to destination: Int) {
    withAnimation {
      instructionSections.move(fromOffsets: source, toOffset: destination)
      for (index, section) in instructionSections.enumerated() {
        section.position = index
      }
    }
  }
}

// MARK: - Instruction Section Editor

private struct InstructionSectionEditor: View {
  @Binding var section: InstructionSection
  @Binding var focusedField: RecipeFocusedField
  var onDelete: () -> Void

  @State private var newStepText: String = ""
  @FocusState private var focusedStepField: String?

  var body: some View {
    Section {
      TextField("Section name", text: $section.name)
        .font(.headline)
        .submitLabel(.done)

      if section.steps.isEmpty {
        Text("No steps in this section")
          .foregroundColor(.secondary)
          .italic()
      } else {
        let sortedSteps = section.steps.sorted { $0.position < $1.position }
        ForEach(sortedSteps, id: \.id) { step in
          if let stepIndex = section.steps.firstIndex(where: { $0.id == step.id }) {
            TextField("Step \(step.id)", text: $section.steps[stepIndex].value, axis: .vertical)
              .focused($focusedStepField, equals: step.id)
              .onSubmit {
                focusedStepField = nil
              }
          }
        }
        .onDelete { indices in
          section.steps.remove(atOffsets: indices)
        }
        .onMove { from, to in
          var sortedSteps = section.steps.sorted { $0.position < $1.position }
          sortedSteps.move(fromOffsets: from, toOffset: to)
          for (index, step) in sortedSteps.enumerated() {
            step.position = index
          }
          section.steps.move(fromOffsets: from, toOffset: to)
        }
      }

      HStack {
        TextField("Add a step", text: $newStepText)
          .submitLabel(.done)
          .focused($focusedStepField, equals: "new-\(section.id)")
          .onSubmit {
            focusedStepField = nil
          }

        Button(action: addStep) {
          Image(systemName: "plus.circle.fill")
            .foregroundStyle(Color.app.primary)
        }
        .disabled(newStepText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    } header: {
      HStack {
        Text(section.name.isEmpty ? "Section" : section.name)
        Spacer()
        Button(action: onDelete) {
          Image(systemName: "trash")
            .foregroundColor(Color.app.primary)
            .font(.caption)
        }
      }
    }
    .onChange(of: focusedStepField) { _, newValue in
      if let stepId = newValue {
        focusedField = .instruction(stepId)
      } else {
        focusedField = .none
      }
    }
  }

  private func addStep() {
    let stepText = newStepText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !stepText.isEmpty else { return }
    withAnimation {
      section.steps.append(Step(value: stepText, position: section.steps.count))
      newStepText = ""
    }
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
    @State private var instructionSections: [InstructionSection] = []

    @State private var focusedField: RecipeFocusedField = .none

    var body: some View {
      NavigationStack {
        Form {
          RecipeEditInstructionsSection(
            instructions: $instructions,
            instructionSections: $instructionSections,
            focusedField: $focusedField
          )
        }
      }
    }
  }

  return PreviewWrapper()
}
