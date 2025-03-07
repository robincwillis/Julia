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
  // @Environment(\.editMode) private var editMode
  
  var body: some View {
    Section {
      if $instructions.isEmpty {
        Text("No instructions added")
          .foregroundColor(.gray)
      } else {
        ForEach(0..<instructions.count, id: \.self) { index in
          HStack {
            Text("\(index + 1).")
              .font(.headline)
            TextField("Instruction step", text: $instructions[index], axis: .vertical)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .focused($isTextFieldFocused)
              .padding(.vertical, 4)
            
            Button(action: {
              if instructions.count > index {
                instructions.remove(at: index)
              }
            }) {
              Image(systemName: "trash")
                .foregroundColor(.red)
            }
          }
          .padding(8)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(8)
        }
        .onDelete(perform: deleteInstruction)
        .onMove(perform: moveInstruction)
        
        Button(action: addNewInstruction) {
          HStack {
            Image(systemName: "plus.circle.fill")
            Text("Add Step")
          }
          .foregroundColor(.white)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(Color.blue)
          .cornerRadius(8)
        }
        .padding(.top, 12)
        
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
