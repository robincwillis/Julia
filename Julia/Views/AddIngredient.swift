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
  @Binding var showBottomSheet: Bool
  
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  
  @FocusState private var isFocused: Bool
  
  @State private var ingredientInput = ""
  
  
  private var isInputValid: Bool {
    !ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  var body: some View {
    VStack (spacing: 12) {
      HStack {
        
        Spacer()
        
        if isInputValid {
          Button(action: {
            saveIngredient()
          }) {
            Label("Save", systemImage: "checkmark")
              .padding(.vertical, 6)
              .padding(.horizontal, 12)
              .background(Color.app.primary)
              .foregroundColor(.white)
              .clipShape(Capsule())
          }
          .disabled(!isInputValid)
        } else {
          Button(action: {
            dismiss()
            withAnimation(.spring()) {
              showBottomSheet = false
            }
          }) {
            Label("Close", systemImage: "xmark")
              .padding(.vertical, 6)
              .padding(.horizontal, 12)
              .background(.tertiary)
              .foregroundColor(Color.app.primary)
              .clipShape(Capsule())
            
          }
          
        }
        
      }
      
      // Main Input
      TextField("Ingredient", text: $ingredientInput)
        .font(.system(size: 32, weight: .medium))
        .foregroundColor(.black)
        .tint(.blue)
        .multilineTextAlignment(.center)
        .disableAutocorrection(true)
        .textInputAutocapitalization(.sentences)

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
        // Empty view when not focused
      }
      
      
    }.onAppear {
      if let ingredient = ingredient {
        ingredientInput = IngredientParser.toString(for: ingredient)
      }
    }
    
    
  }
  
  private func saveIngredient() {
    // Handle Current Ingredient
    
    
    
    guard let newIngredient = IngredientParser.fromString(input: ingredientInput, location: ingredientLocation) else { return }
   
    // Edit existing ingredient
    if let ingredient = ingredient {
      ingredient.name = newIngredient.name
      ingredient.unit = newIngredient.unit
      ingredient.quantity = newIngredient.quantity
    } else {
      // Creatae New Ingredeint
      context.insert(newIngredient)
      ingredient = newIngredient
    }
    do {
      try context.save()
      isFocused = false;
      
    } catch {
      print(error.localizedDescription)
    }
    
  }
}

#Preview {
  @State var location = IngredientLocation.pantry
  @State var showBottomSheet = true
  return FloatingBottomSheet(isPresented: $showBottomSheet) {
    AddIngredient(
      ingredientLocation: $location,
      ingredient: .constant(nil),
      showBottomSheet: $showBottomSheet
    )
  }
}


