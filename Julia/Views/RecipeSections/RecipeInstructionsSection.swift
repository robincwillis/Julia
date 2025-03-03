//
//  RecipeInstructionsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI
struct RecipeInstructionsSection: View {
  let recipe: Recipe
  @Binding var editedInstructions: [String]
  @FocusState var isTextFieldFocused: Bool
  
  // Explicitly use the editMode environment
  @Environment(\.editMode) private var editMode
  private var isEditing: Bool {
    return editMode?.wrappedValue.isEditing ?? false
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      // Header
      HStack {
        Text("Instructions")
          .font(.headline)
        Spacer()
      }
      .padding(.bottom, 4)
      
      if !editedInstructions.isEmpty {
        if isEditing {
          // Edit mode - grey background with white fields
          VStack(spacing: 12) {
            ForEach(Array(editedInstructions.enumerated()), id: \.element) { index, _ in
              HStack(alignment: .top, spacing: 10) {
                // Step number - Primary button style
                Text("\(index + 1)")
                  .font(.subheadline)
                  .foregroundColor(.white)
                  .padding(6)
                  .background(Circle().fill(Color.blue))
                  .frame(minWidth: 30)
                
                // Text field with white background
                TextField("Instruction step", text: $editedInstructions[index], axis: .vertical)
                  .padding(8)
                  .background(Color.white)
                  .cornerRadius(8)
                  .focused($isTextFieldFocused)
                  .submitLabel(.done)
                  .shadow(color: .gray.opacity(0.2), radius: 1)
              }
              .padding(.vertical, 4)
            }
            .onDelete(perform: deleteInstruction)
            .onMove(perform: moveInstruction)
          }
          .padding(12)
          .background(Color(.systemGray6))
          .cornerRadius(12)
          
          // Add button - Secondary button style
          Button(action: addNewInstruction) {
            Label("Add Step", systemImage: "plus")
              .foregroundColor(.blue)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color(red: 0.85, green: 0.92, blue: 1.0))
              .cornerRadius(8)
          }
          .padding(.top, 8)
        } else {
          // Display mode - clean white background with black text
          VStack(spacing: 10) {
            ForEach(Array(recipe.instructions.enumerated()), id: \.element) { index, step in
              HStack(alignment: .top, spacing: 12) {
                // Step number - Primary button style
                Text("\(index + 1)")
                  .font(.subheadline)
                  .foregroundColor(.white)
                  .padding(6)
                  .background(Circle().fill(Color.blue))
                  .frame(minWidth: 30)
                
                // Plain text display
                Text(step)
                  .foregroundColor(.black)
                  .padding(.vertical, 4)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
          .background(Color.white)
        }
      } else {
        Text("No instructions available")
          .foregroundColor(.gray)
          .padding(.vertical, 8)
      }
    }
    .padding(.vertical, 8)
  }
  
  private func addNewInstruction() {
    withAnimation {
      editedInstructions.append("New step")
    }
  }
  
  private func deleteInstruction(at offsets: IndexSet) {
    withAnimation {
      editedInstructions.remove(atOffsets: offsets)
    }
  }
  
  private func moveInstruction(from source: IndexSet, to destination: Int) {
    withAnimation {
      editedInstructions.move(fromOffsets: source, toOffset: destination)
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var instructions = [
      "Mix flour and sugar",
      "Add butter and eggs",
      "Bake at 350°F for 30 minutes"
    ]
    @State private var editMode: EditMode = .inactive
    @FocusState private var focused: Bool
    
    var body: some View {
      NavigationStack {
        VStack {
          RecipeInstructionsSection(
            recipe: Recipe(
              title: "Sample Recipe",
              summary: "A delicious sample recipe",
              ingredients: [],
              instructions: instructions
            ),
            editedInstructions: $instructions,
            isTextFieldFocused: _focused
          )
          .padding()
          .environment(\.editMode, $editMode)
        }
        .toolbar {
          Button(editMode.isEditing ? "Done" : "Edit") {
            withAnimation {
              editMode = editMode.isEditing ? .inactive : .active
            }
          }
          .foregroundColor(editMode.isEditing ? .black : .blue)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(editMode.isEditing ? Color.clear : Color(red: 0.85, green: 0.92, blue: 1.0))
          .cornerRadius(6)
        }
        .navigationTitle("Recipe Instructions")
      }
    }
  }
  
  return PreviewWrapper()
}
