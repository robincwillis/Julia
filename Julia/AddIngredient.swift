//
//  AddIngredient.swift
//  Julia
//
//  Created by Robin Willis on 11/6/24.
//

import SwiftUI
import SwiftData

struct AddIngredient: View {
  @Binding var ingredientLocation : IngredientLocation

  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss

  @FocusState private var isFocused: Bool
  @State private var ingredientInput = ""
  
  private var isInputValid: () -> Bool {
    { !ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
  }
  
  var body: some View {
    VStack (spacing: 12) {
      HStack {
        Button(action: {
          dismiss()
        }) {
          Label("Close", systemImage: "xmark")
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(.tertiary)
            .foregroundColor(.blue)
            .clipShape(Capsule())
          
        }
        .disabled(!isInputValid())
        
        Spacer()
      
        Button(action: {
          saveIngredient()
        }) {
          Label("Save", systemImage: "checkmark")
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())

        }
        .disabled(!isInputValid())
        
      }
      
      TextField("Ingredient", text: $ingredientInput)
        .font(.system(size: 32, weight: .medium))
        .foregroundColor(.black)
        .tint(.blue)
        .multilineTextAlignment(.center)
          .focused($isFocused) // Bind focus to this text field
          .onAppear {
            isFocused = true // Automatically focus when the view appears
          }
          .onSubmit {
            saveIngredient()
          }
        //.background(.red)
        

    }

    
  }
  
  private func saveIngredient() {
   // guard !isInputValid() else { return }
    
    // TODO: Get Location from parent
    guard let ingredient = IngredientParser.parse(input: ingredientInput, location: ingredientLocation) else { return }
    context.insert(ingredient)
    do {
      try context.save()
      //showSheet = false
      ingredientInput = ""
      dismiss()
    } catch {
      print(error.localizedDescription)
    }

  }
}

#Preview {
  @State var location = IngredientLocation.pantry
  @State var showBottomSheet = true
  return FloatingBottomSheet(isPresented: $showBottomSheet) {
    AddIngredient(ingredientLocation: $location)
  }
}


//VStack(spacing: 20) {
//  Text("Add Item")
//    .font(.headline)
//  
//  TextField("Type something...", text: $textInput)
//    .textFieldStyle(RoundedBorderTextFieldStyle())
//    .padding(.horizontal)

//  
//  }
