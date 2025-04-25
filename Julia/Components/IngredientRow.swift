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
          .fill(configuration.isOn ? Color.blue : Color.app.offWhite400)  // Blue when checked, gray otherwise
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
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      quantityView
      ingredientDetailsView
    }
  }
  
  // MARK: - Helper Views
  
  private var quantityView: some View {
    Group {
      if let quantity = ingredient.quantity {
        Text(quantity.toFractionString())
          .font(.body)
          .foregroundColor(Color.app.primary)
        
        if let unit = ingredient.unit, unit.rawValue != "item" {
          Text(unit.displayName.pluralized(for: quantity))
            .font(.body)
            .foregroundColor(Color.app.primary)
        }
      }
    }
  }
  
  private var ingredientDetailsView: some View {
    (
      Text(formattedIngredientName)
        .font(.body)
        .foregroundColor(Color.app.textSecondary)
      +
      (ingredient.comment != nil ?
       Text(" " + (ingredient.comment ?? ""))
        .font(.subheadline)
        .foregroundColor(Color.app.grey300) :
        Text(""))
    )
    .multilineTextAlignment(.leading)
    .fixedSize(horizontal: false, vertical: true)
  }
  
  // MARK: - Computed Properties
  
  private var formattedIngredientName: String {
    if let quantity = ingredient.quantity {
      if let unit = ingredient.unit, unit.rawValue == "item" {
        // Pluralize the name if it's an "item" unit type
        return ingredient.name.pluralized(for: quantity)
      }
    }
    return ingredient.name
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
    .onTapGesture {
      onTap?(ingredient, section)  // Call the onTap closure if provided
    }
    .padding(padding)
  }
}

struct SelectableModifier: ViewModifier {
  let selected: Binding<Bool>
  func body(content: Content) -> some View {
    HStack (alignment: .firstTextBaseline) {
      Toggle(isOn: selected){}
      .toggleStyle(iOSCheckboxToggleStyle())
      VStack {
        content
      }
      .offset(y: -6)
    }

  }
}

extension View {
  func selectable(selected: Binding<Bool>) -> some View {
    modifier(SelectableModifier(selected: selected))
  }
}


#Preview("Ingredient Row") {
  Previews.previewModels(with: { context in
    // Get ingredients from MockData
    let ingredients = MockData.createSampleIngredients()
    
    // Insert them into the context
    for ingredient in ingredients {
      context.insert(ingredient)
    }
    
    return ingredients
  }) { (ingredients: [Ingredient]) in
    List {
      ForEach(ingredients.prefix(5)) { ingredient in
        IngredientRow(
          ingredient: ingredient,
          onTap: { _ in /* Noop */ }
        )
        .selectable(selected: .constant(false))
      }
    }
  }
}

