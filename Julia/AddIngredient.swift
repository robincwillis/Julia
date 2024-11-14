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
  @Binding var ingredient : Ingredient?
  
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  
  @FocusState private var isFocused: Bool
  
  @State private var ingredientInput = ""
  
  
  private var isInputValid: Bool {
    !ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  var body: some View {
    print("::AddIngredient: currentIngredient")
    print(ingredient ?? "nothing")
    print("::AddIngredient: ingredientInput")
    print(ingredientInput)
    return VStack (spacing: 12) {
      HStack {
        
        Spacer()
        
        if isInputValid {
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
          .disabled(!isInputValid)
        } else {
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
          //.disabled(!isInputValid)
          
        }
        
        
        
      }
      
      // Main Input
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
        .submitLabel(.done)
      
      // Secondary Input
      
      if !isFocused {
        HStack {
          Text("Measurement Option")
          Text("Measurement Option")
          Text("Measurement Option")
          Text("Measurement Option")
          Text("Measurement Option")
        }
        HStack {
          Text("Fraction")
          Text("Fraction")
          Text("Fraction")
        }
      }
      
      
    }.onAppear {
      if let ingredient = ingredient {
        ingredientInput = IngredientParser.toString(for: ingredient)
      }
    }
    
    
  }
  
  private func saveIngredient() {
    // guard !isInputValid() else { return }
    // Handle Current Ingredient
    
    
    // TODO: Get Location from parent
    guard let newIngredient = IngredientParser.fromString(input: ingredientInput, location: ingredientLocation) else { return }
    if let ingredient = ingredient {
      ingredient.name = newIngredient.name
      ingredient.unit = newIngredient.unit
      ingredient.quantity = newIngredient.quantity
    } else {
      context.insert(newIngredient)
    }
    do {
      try context.save()
      //showSheet = false
      //ingredientInput = ""
      isFocused = false;
      // dismiss()
    } catch {
      print(error.localizedDescription)
    }
    
  }
}

#Preview {
  @State var location = IngredientLocation.pantry
  @State var showBottomSheet = true
  return FloatingBottomSheet(isPresented: $showBottomSheet) {
    AddIngredient(ingredientLocation: $location, ingredient: .constant(nil))
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
