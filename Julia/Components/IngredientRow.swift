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
        RoundedRectangle(cornerRadius: 6)
          .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.25))  // Blue when checked, gray otherwise
          .frame(width: 24, height: 24)
          .overlay(
            Image(systemName: "checkmark")
              .foregroundColor(.white)
              .opacity(configuration.isOn ? 1 : 0)
          )
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
    VStack(alignment: .leading, spacing: 2) {
      // Main content in HStack to flow inline
      HStack(alignment: .firstTextBaseline, spacing: 2) {
        
        if let quantity = ingredient.quantity {
          if let unit = ingredient.unit {
            Text("\(quantity.toFractionString())") // \(unit.shortHand)
              .font(.body)
              .foregroundColor(.blue)
            if unit.rawValue != "item" {
              Text(" \(unit.displayName.pluralized(for: quantity))")
                .font(.body)
                .foregroundColor(.blue)
            }
            
            Text(unit.rawValue != "item" ? ingredient.name : ingredient.name.pluralized(for: quantity))
              .font(.body)
              .foregroundColor(.black)
          } else {
            Text("\(quantity.toFractionString())")
              .font(.body)
              .foregroundColor(.blue)
            Text(ingredient.name.pluralized(for: quantity))
              .font(.body)
              .foregroundColor(.black)
            
          }
        } else {
          Text(ingredient.name)
            .font(.body)
            .foregroundColor(.black)
        }
      }
      
      if let comment = ingredient.comment {
        Text("\(comment)")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
    }
  }
}

struct IngredientRow: View {
  var ingredient: Ingredient
  var onTap: ((Ingredient?, IngredientSection?) -> Void)?
  var section: IngredientSection? = nil
  var padding: CGFloat = 6
  
  init(ingredient: Ingredient, onTap: ((Ingredient?, IngredientSection?) -> Void)? = nil, section: IngredientSection? = nil, padding: CGFloat = 6) {
    self.ingredient = ingredient
    self.onTap = onTap
    self.section = section
    self.padding = padding
  }
  
  // onTap (Ingredient?) -> Void initializer
  init(ingredient: Ingredient, onTap: ((Ingredient?) -> Void)?, padding: CGFloat = 6) {
    self.ingredient = ingredient
    self.padding = padding
    self.section = nil
    
    if let onTap = onTap {
      self.onTap = { ingredient, _ in
        onTap(ingredient)
      }
    } else {
      self.onTap = nil
    }
  }
  
  var body: some View {
    HStack {
      IngredientLabel(ingredient)
      Spacer()
    }
    .padding(.vertical, padding)
    .onTapGesture {
      onTap?(ingredient, section)  // Call the onTap closure if provided
    }
  }
}

struct SelectableModifier: ViewModifier {
  let selected: Binding<Bool>
  func body(content: Content) -> some View {
    HStack {
      Toggle(isOn: selected){}
      .toggleStyle(iOSCheckboxToggleStyle())
      content
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
    func handleTap(with ingredient: Ingredient?) {

    }
    return Group {
      ForEach(ingredients[0..<5]) { ingredient in
        IngredientRow(ingredient: ingredient, onTap: handleTap(with:))
          .selectable(selected: $selected)
      }
    }
  } catch {
    return Text("Failed to create container: \(error.localizedDescription)")
  }
  
}
