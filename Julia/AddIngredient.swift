//
//  AddIngredient.swift
//  Julia
//
//  Created by Robin Willis on 11/6/24.
//

import SwiftUI
import SwiftData

struct AddIngredient: View {
    
    @State private var name = ""
    @State private var measurement = ""
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    private var isFormValid: Bool {
        return true
        // !$name.isEmptyOrWithWhiteSpace
    }
    
    var body: some View {
        Form {
            TextField("Enter Name", text: $name)
            TextField("Enter Measurement", text: $measurement)
            Button("Save") {
                let ingredient = Ingredient(name: name, measurement: measurement)
                context.insert(ingredient)
                do {
                    try context.save()
                } catch {
                    print(error.localizedDescription)
                }
                dismiss()
            }.disabled(!isFormValid)
        }
    }
}

#Preview {
    AddIngredient()
}
