//
//  IngredientRow.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI

struct iOSCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                configuration.label
            }
        })
    }
}

struct IngredientRow: View {
    @State private var selected = false
    var ingredient: Ingredient
    var body: some View {
        HStack {
            Toggle(isOn: $selected) {
                if let quantity = ingredient.quantity {
                    if let measurement = ingredient.measurement {
                        Text("\(quantity.toFractionString()) \(measurement.pluralized(for: quantity))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(ingredient.name)
                    } else {
                        Text("\(quantity.toFractionString())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(ingredient.name.pluralized(for: quantity))
                    }
                } else {
                    Text(ingredient.name)
                }
                if let comment = ingredient.comment {
                    Text("\(comment)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .toggleStyle(iOSCheckboxToggleStyle())
        }
        
    }
}

//struct IngredientRow_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            IngredientRow(ingredient: mockIngredients[0])
//            IngredientRow(ingredient: mockIngredients[1])
//            IngredientRow(ingredient: mockIngredients[2])
//            IngredientRow(ingredient: mockIngredients[3])
//        }
//        
//    }
//}
