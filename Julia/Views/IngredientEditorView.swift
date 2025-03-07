//
//  IngredientEditorView.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftUI
import SwiftData

struct IngredientEditorView: View {
    @Binding var ingredient: Ingredient?
    @Binding var showBottomSheet: Bool
    
    @Environment(\.modelContext) private var context
    @FocusState private var focusedField: Field?
    
    @State private var name: String = ""
    @State private var quantity: Double?
    @State private var quantityString: String = ""
    @State private var unit: String = ""
    @State private var comment: String = ""
    
    enum Field: Hashable {
        case name, quantity, unit, comment
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with close/save buttons
            HStack {
                Button(action: {
                    withAnimation(.spring()) {
                        showBottomSheet = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(ingredient?.id == nil ? "Add Ingredient" : "Edit Ingredient")
                    .font(.headline)
                
                Spacer()
                
                Button(action: saveIngredient) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.bottom, 8)
            
            // Ingredient name
            VStack(alignment: .leading, spacing: 4) {
                Text("Ingredient Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter ingredient name", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .quantity
                    }
            }
            
            // Quantity and unit
            HStack(spacing: 12) {
                // Quantity
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quantity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Amount", text: $quantityString)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .frame(width: 100)
                        .focused($focusedField, equals: .quantity)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .unit
                        }
                        .onChange(of: quantityString) {
                            quantity = Double(quantityString)
                        }
                }
                
                // Unit
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("cups, tbsp, etc", text: $unit)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .focused($focusedField, equals: .unit)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .comment
                        }
                }
            }
            
            // Comment
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("diced, chopped, etc", text: $comment)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .focused($focusedField, equals: .comment)
                    .submitLabel(.done)
                    .onSubmit {
                        saveIngredient()
                    }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadIngredientData()
            focusedField = .name
        }
    }
    
    private func loadIngredientData() {
        guard let ingredient = ingredient else {
            // Create new ingredient if none exists
            return
        }
        
        // Populate fields with existing ingredient data
        name = ingredient.name
        quantity = ingredient.quantity
        quantityString = ingredient.quantity != nil ? String(format: "%.2f", ingredient.quantity!).replacingOccurrences(of: ".00", with: "") : ""
        unit = ingredient.unit?.rawValue ?? ""
        comment = ingredient.comment ?? ""
    }
    
    private func saveIngredient() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let existingIngredient = ingredient {
            // Update existing ingredient
            existingIngredient.name = trimmedName
            existingIngredient.quantity = quantity
            existingIngredient.unit = MeasurementUnit(from: unit.isEmpty ? nil : unit)
            existingIngredient.comment = comment.isEmpty ? nil : comment
        } else {
            // Create new ingredient
            let newIngredient = Ingredient(
                name: trimmedName,
                location: .recipe,
                quantity: quantity,
                unit: unit.isEmpty ? nil : unit,
                comment: comment.isEmpty ? nil : comment
            )
            ingredient = newIngredient
        }
        
        // Close the sheet
        withAnimation(.spring()) {
            showBottomSheet = false
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var ingredient: Ingredient? = Ingredient(
            name: "Flour",
            location: .recipe,
            quantity: 2,
            unit: "cup",
            comment: "all-purpose"
        )
        @State private var showSheet = true
        
        var body: some View {
            IngredientEditorView(
                ingredient: $ingredient,
                showBottomSheet: $showSheet
            )
        }
    }
    
    return PreviewWrapper()
}