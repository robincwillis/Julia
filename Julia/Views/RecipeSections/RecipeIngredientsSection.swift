//
//  RecipeIngredientsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI
import SwiftData

struct RecipeIngredientsSection: View {
  let recipe: Recipe
  var multiplier: Double = 1.0
  @Binding var adjustedServings: Int?
  @Binding var unitSystem: UnitSystem?
  let selectableBinding: (Ingredient) -> Binding<Bool>
  let toggleSelection: (Ingredient) -> Void

  @State private var isServingsExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      titleRow

      if isServingsExpanded, let originalServings = recipe.servings {
        servingsSlider(originalServings: originalServings)
          .padding(.bottom, 4)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }

      if recipe.ingredients.isEmpty && recipe.sections.isEmpty {
        Text("No ingredients available")
          .foregroundColor(Color.app.textSecondary)
          .padding(.vertical, 8)
      } else {
        // Display unsectioned ingredients first
        let unsectionedIngredients = recipe.ingredients.filter { $0.section == nil }
        if !unsectionedIngredients.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            ForEach(unsectionedIngredients) { ingredient in
              IngredientRow(ingredient: ingredient, multiplier: multiplier, unitSystem: unitSystem)
                .selectable(selected: selectableBinding(ingredient))
                .contentShape(Rectangle())
                .onTapGesture {
                  toggleSelection(ingredient)
                }
            }
          }
          .padding(.bottom, 8)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Title Row

  private var titleRow: some View {
    HStack(spacing: 8) {
      Text("Ingredients")
        .font(.headline)
        .foregroundColor(Color.app.textPrimary)

      Spacer()

      if recipe.servings != nil {
        Button {
          withAnimation(.snappy) {
            isServingsExpanded.toggle()
          }
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
            Text("\(adjustedServings ?? recipe.servings!)")
          }
          .font(.caption.weight(.medium))
          .foregroundStyle(isServingsExpanded ? Color.white : Color.app.primary)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(isServingsExpanded ? Color.app.primary : Color.app.backgroundInput, in: Capsule())
        }
        .buttonStyle(.plain)
      }

      unitSystemToggle
    }
    .padding(.bottom, 8)
  }

  private var unitSystemToggle: some View {
    HStack(spacing: 4) {
      unitSystemButton(.imperial, label: "US")
      unitSystemButton(.metric, label: "Metric")
    }
  }

  private func unitSystemButton(_ system: UnitSystem, label: String) -> some View {
    let isSelected = unitSystem == system
    return Button {
      unitSystem = isSelected ? nil : system
    } label: {
      Text(label)
        .font(.caption.weight(.medium))
        .foregroundStyle(isSelected ? Color.white : Color.app.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.app.primary : Color.app.backgroundInput, in: Capsule())
    }
    .buttonStyle(.plain)
  }

  // MARK: - Servings Slider

  private func servingsSlider(originalServings: Int) -> some View {
    let sliderMax = max(Double(originalServings) * 3, 12)
    let currentServings = adjustedServings ?? originalServings

    return VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text("\(currentServings) serving\(currentServings == 1 ? "" : "s")")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(Color.app.textPrimary)
          .contentTransition(.numericText())
          .animation(.snappy, value: currentServings)

        Spacer()

        if adjustedServings != nil && adjustedServings != originalServings {
          Button("Reset") {
            withAnimation(.snappy) {
              adjustedServings = nil
            }
          }
          .font(.caption)
          .foregroundStyle(Color.app.secondary)
        }
      }

      Slider(
        value: Binding(
          get: { Double(currentServings) },
          set: { newValue in
            let rounded = Int(newValue.rounded())
            adjustedServings = rounded == originalServings ? nil : rounded
          }
        ),
        in: 1...sliderMax,
        step: 1
      )
      .tint(Color.app.primary)
    }
  }
}

#Preview {
  Previews.recipeComponent { recipe in
    RecipeIngredientsSection(
      recipe: recipe,
      adjustedServings: .constant(nil),
      unitSystem: .constant(nil),
      selectableBinding: { _ in .constant(false) },
      toggleSelection: { _ in }
    )
    .padding()
  }
}
