//
//  EditIngredient.swift
//  Julia
//
//  Created by Robin Willis on 11/11/24.
//

import SwiftUI
import SwiftData

struct EditIngredient: View {
  @Binding var ingredient: Ingredient
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  
  @State private var name: String
  @State private var quantity: Double = 0
  @State private var selectedUnit: MeasurementUnit
  
  init(ingredient: Binding<Ingredient>) {
    self._ingredient = ingredient
    self._name = State(initialValue: ingredient.wrappedValue.name)
    self._quantity = State(initialValue: ingredient.wrappedValue.quantity ?? 0)
    self._selectedUnit = State(initialValue: ingredient.wrappedValue.unit ?? .piece)
  }
  
  var body: some View {
    NavigationStack {
      Form {
        Section("Ingredient Details") {
          TextField("Name", text: $name)
          
          HStack {
            TextField("Quantity", value: $quantity, format: .number)
              .keyboardType(.decimalPad)
            
            Picker("Unit", selection: $selectedUnit) {
              ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                Text(unit.displayName)
              }
            }
            .pickerStyle(.menu)
          }
        }
      }
      .navigationTitle("Edit Ingredient")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveChanges()
          }
        }
      }
    }
  }
  
  private func saveChanges() {
    ingredient.name = name
    ingredient.quantity = quantity
    ingredient.unit = selectedUnit
    
    try? context.save()
    dismiss()
  }
}

#Preview {
  let ingredient = Ingredient(name: "Apple", location: .pantry, quantity: 2, unit: "piece")
  return EditIngredient(ingredient: .constant(ingredient))
    .modelContainer(DataController.previewContainer)
}
