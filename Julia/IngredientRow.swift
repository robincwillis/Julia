//
//  IngredientRow.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData

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

struct IngredientLabel: View {
  var ingredient: Ingredient
  
  init(_ ingredient: Ingredient) {
    self.ingredient = ingredient
  }
  
  var body: some View {
    if let quantity = ingredient.quantity {
      if let unit = ingredient.unit {
        Text("\(quantity.toFractionString()) \(unit.pluralized(for: quantity))")
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
  }
}

struct IngredientRow: View {
  var ingredient: Ingredient
  
  var body: some View {
    HStack {
      IngredientLabel(ingredient)
    }
  }
}

struct SelectableModifier: ViewModifier {
  let selected: Binding<Bool>
  func body(content: Content) -> some View {
    HStack {
      Toggle(isOn: selected) {
        content
        Spacer()
      }
//      .onChange(of: selected.wrappedValue) {
//        print("Toggle changed")
//        print(selected.wrappedValue)
//      }
      .toggleStyle(iOSCheckboxToggleStyle())
    }
  }
}

extension View {
  func selectable(selected: Binding<Bool>) -> some View {
    modifier(SelectableModifier(selected: selected))
  }
}

#Preview {
  do {
    @State var selected = false
    let container = DataController.previewContainer
    let fetchDescriptor = FetchDescriptor<Ingredient>()
    let ingredients = try container.mainContext.fetch(fetchDescriptor)
    return Group {
      ForEach(ingredients[0..<5]) { ingredient in
        
        IngredientRow(ingredient: ingredient)
          .selectable(selected: $selected)
      }
    }
  } catch {
    return Text("Failed to create container: \(error.localizedDescription)")
  }
  
}
