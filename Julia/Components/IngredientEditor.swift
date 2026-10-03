//
//  IngredientEditorView.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftData
import SwiftUI

struct IngredientEditor: View {
  var ingredientLocation: IngredientLocation
  @Binding var ingredient: Ingredient?
  var recipe: Recipe? = nil
  var section: IngredientSection? = nil
  @Binding var showBottomSheet: Bool

  @State private var showControls = false
  @State private var showNotes = false
  @State private var hasSaved = false
  @State private var isFixingWithAI = false

  @FocusState private var isNameFieldFocused: Bool
  @FocusState private var isCommentFieldFocused: Bool

  private var isAnyFieldFocused: Bool {
    isNameFieldFocused || isCommentFieldFocused
  }

  private var canSave: Bool {
    return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasSaved
  }

  @Environment(\.modelContext) private var context

  @State private var name: String = ""
  @State private var quantity: Double?
  @State private var unit: MeasurementUnit?
  @State private var comment: String = ""

  @State private var ingredientInput: String = ""

  let units = MeasurementUnit.allCases
  let numbers = MeasurementValue.numbers
  let fractions = MeasurementValue.fractions

  var displayMeasurement: String? {
    if quantity == nil {
      return nil
    }

    var display = ""

    if let qty = quantity {
      let intPart = Int(floor(qty))
      let fracPart = qty - floor(qty)

      if intPart > 0 {
        display += "\(intPart)"
      }

      if fracPart > 0 {
        let closestFraction = MeasurementValue.fractions
          .min(by: { abs($0.rawValue - fracPart) < abs($1.rawValue - fracPart) })

        if let fraction = closestFraction, abs(fraction.rawValue - fracPart) < 0.1 {
          if intPart > 0 {
            display += " "
          }
          display += fraction.displaySymbol
        }
      }
    }

    if let unitValue = unit, unitValue.rawValue != "item" {
      if !display.isEmpty {
        display += " "
      }

      if let qty = quantity, qty > 1 {
        display += unitValue.pluralName
      } else {
        display += unitValue.displayName
      }
    }

    return display.isEmpty ? nil : display
  }

  enum Field: Hashable {
    case name, quantity, unit, comment
  }

  let rows = [
    GridItem(.fixed(36)),
    GridItem(.fixed(36)),
    GridItem(.fixed(36)),
    GridItem(.fixed(36)),
  ]

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        HStack(spacing: 16) {
          Button(action: {
            withAnimation {
              isNameFieldFocused.toggle()
            }
          }) {
            Image(systemName: isNameFieldFocused ? "arrow.down" : "arrow.up")
              .font(.title2)
              .foregroundColor(Color.app.primary)
          }
          .disabled(!canSave)

          Button(action: {
            Task { await fixWithAI() }
          }) {
            if isFixingWithAI {
              Loader(isLoading: .constant(true))
            } else {
              Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(Color.app.primary)
            }
          }
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFixingWithAI)
        }

        Spacer()

        Button(action: {
          if canSave {
            saveIngredient()
            hasSaved = true
          }
          showBottomSheet = false
        }) {
          Image(systemName: canSave ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.title2)
            .foregroundColor(canSave ? Color.app.primary : Color.app.primaryDisabled)
        }
      }
      VStack(alignment: .center, spacing: 12) {

        if let measurementLabel = displayMeasurement {
          Button(action: {
            withAnimation {
              isNameFieldFocused.toggle()
            }
          }) {
            Text(measurementLabel)
              .font(.system(size: 18, weight: .medium))
              .foregroundStyle(Color.app.primary)
              .padding(.horizontal, 8)
              .frame(maxWidth: .infinity, alignment: .center)
          }
          .disabled(!canSave)
        }

        TextField("Ingredient", text: $name)
          .font(.system(size: 32, weight: .medium))
          .foregroundColor(Color.app.textPrimary)
          .tint(Color.app.primary)
          .multilineTextAlignment(.center)
          .lineLimit(1)
          .submitLabel(.done)
          .minimumScaleFactor(0.5)
          .disableAutocorrection(true)
          .textInputAutocapitalization(.sentences)
          .focused($isNameFieldFocused)
          .padding(.vertical, 12)
          .onChange(of: name) {
            if isNameFieldFocused {
              ingredientInput = name
            }
          }
          .onSubmit {
            isNameFieldFocused = false
          }
          .background(Color.app.white)

        if showControls {
          VStack {
            ScrollView(.horizontal, showsIndicators: false) {
              LazyHGrid(rows: rows, spacing: 8) {
                ForEach(units, id: \.self) { unitOption in
                  Button(action: {
                    self.unit = unitOption
                  }) {
                    Text(unitOption.displayName)
                      .padding(6)
                      .font(.system(size: 12))
                      .frame(maxWidth: .infinity, minHeight: 36)
                      .background(self.unit == unitOption ? Color.app.secondary : Color.app.backgroundCard)
                      .foregroundColor(self.unit == unitOption ? .white : Color.app.textPrimary)
                      .cornerRadius(12)
                      .fontWeight(self.unit == unitOption ? .bold : .regular)
                  }
                  .containerRelativeFrame(.horizontal, count: 4, spacing: 8)
                }
              }
            }

            HStack(spacing: 8) {
              ForEach(fractions, id: \.self) { fraction in
                Button(action: {
                  if quantity == nil {
                    quantity = fraction.rawValue
                  } else {
                    let intPart = floor(quantity!)
                    quantity = intPart + fraction.rawValue
                  }
                }) {
                  Text(fraction.displaySymbol)
                    .padding(6)
                    .frame(minHeight: 40)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
              }
            }

            VStack(spacing: 8) {

              ForEach(0..<3) { row in
                HStack(spacing: 8) {
                  ForEach(0..<3) { column in
                    let index = row * 3 + column
                    let number = numbers[index]
                    Button(action: {
                      let numValue = Double(number.rawValue)
                      if quantity == nil {
                        quantity = numValue
                      } else {
                        let intPart = floor(quantity!)
                        let fracPart = quantity! - intPart
                        quantity = (intPart * 10 + numValue) + fracPart
                      }
                    }) {
                      Text(number.displaySymbol)
                        .padding(6)
                        .frame(minHeight: 40)
                        .frame(maxWidth: .infinity)
                        .background(Color.app.secondary)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                        .fontWeight(.medium)
                    }
                  }
                }
              }

              HStack(spacing: 8) {
                Button(action: {
                  if quantity == nil {
                    quantity = 0
                  } else {
                    let intPart = floor(quantity!)
                    let fracPart = quantity! - intPart
                    quantity = (intPart * 10) + fracPart
                  }
                }) {
                  Text("0")
                    .padding(6)
                    .frame(minHeight: 40)
                    .frame(maxWidth: .infinity)
                    .background(Color.app.secondary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button(action: {
                  if quantity != nil {
                    if quantity! < 1 {
                      quantity = nil
                    } else {
                      let intPart = floor(quantity!)
                      let fracPart = quantity! - intPart

                      if fracPart > 0 {
                        quantity = intPart
                      } else {
                        quantity = floor(intPart / 10)
                        if quantity == 0 {
                          quantity = nil
                        }
                      }
                    }
                  }

                  if quantity == nil {
                    unit = nil
                  }
                }) {
                  Text("Delete")
                    .padding(6)
                    .frame(minHeight: 40)
                    .frame(maxWidth: .infinity)
                    .background(Color.app.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
              }
            }

          }

        }

        if showNotes {
          VStack {
            TextField("Comment (e.g., diced, chopped)", text: $comment)
              .padding()
              .background(Color.app.backgroundPrimary)
              .foregroundColor(Color.app.textPrimary)
              .cornerRadius(10)
              .focused($isCommentFieldFocused)
              .submitLabel(.done)
              .onSubmit {
                isCommentFieldFocused = false
              }
          }
        }
      }
    }
    .onAppear {
      loadIngredient()
      isNameFieldFocused = true
      hasSaved = false
    }
    .onChange(of: isAnyFieldFocused) { _, _ in
      withAnimation {
        showControls = !isAnyFieldFocused && showBottomSheet
      }
    }
    .onChange(of: isNameFieldFocused) { oldValue, newValue in
      withAnimation {
        showNotes = !isNameFieldFocused && showBottomSheet
      }
      if oldValue && !newValue && name.contains(" ") {
        if let parsedIngredient = IngredientParser.fromString(input: name, location: ingredientLocation) {
          name = parsedIngredient.name

          if quantity == nil {
            quantity = parsedIngredient.quantity
          }

          if unit == nil {
            unit = parsedIngredient.unit
          }

          if let parsedComment = parsedIngredient.comment, !parsedComment.isEmpty {
            comment = parsedComment
          }
        }
      }
    }
    .onChange(of: showBottomSheet) { oldValue, newValue in
      if oldValue == true && newValue == false && canSave && !hasSaved {
        saveIngredient()
      }
    }
  }

  private func loadIngredient() {
    guard let existingIngredient = ingredient else {
      unit = MeasurementUnit(from: "item")

      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(350))
        isNameFieldFocused = true
      }
      return
    }

    name = existingIngredient.name
    quantity = existingIngredient.quantity
    unit = existingIngredient.unit ?? MeasurementUnit(from: "item")
    comment = existingIngredient.comment ?? ""
  }

  /// Re-parses the current name field with Foundation Models and populates
  /// name/quantity/unit/comment from the result, so a raw imported line
  /// (e.g. "2 cups flour, sifted" sitting entirely in the name) gets split
  /// into its proper fields for review before saving.
  private func fixWithAI() async {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    guard await FoundationModelsService.shared.isAvailable else { return }

    isFixingWithAI = true
    defer { isFixingWithAI = false }

    do {
      if let parsed = try await FoundationModelsIngredientParser().parse(
        trimmed,
        location: ingredientLocation,
        recipeContext: recipe?.title
      ) {
        name = parsed.name
        quantity = parsed.quantity
        unit = parsed.unit
        comment = parsed.comment ?? ""
      }
    } catch {
      print("AI ingredient fix failed: \(error)")
    }
  }

  private func saveIngredient() {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return }

    // If there's input text and no ingredient details, try to parse it
    if ingredientInput.isEmpty == false && quantity == nil && unit == nil {
      if let parsedIngredient = IngredientParser.fromString(input: ingredientInput, location: ingredientLocation) {
        if parsedIngredient.quantity != nil {
          quantity = parsedIngredient.quantity
        }

        if parsedIngredient.unit != nil {
          unit = parsedIngredient.unit
        }

        if let parsedComment = parsedIngredient.comment, !parsedComment.isEmpty {
          comment = parsedComment
        }
      }
    }

    if let existingIngredient = ingredient {
      existingIngredient.name = trimmedName
      existingIngredient.quantity = quantity
      existingIngredient.unit = unit
      existingIngredient.comment = comment.isEmpty ? nil : comment
    } else {
      let newIngredient = Ingredient(
        name: trimmedName,
        location: ingredientLocation,
        quantity: quantity,
        unit: unit?.rawValue,
        comment: comment.isEmpty ? nil : comment
      )

      context.insert(newIngredient)
      ingredient = newIngredient
    }

    if let currentIngredient = ingredient {
      if let currentSection = section {
        if currentIngredient.section == nil {
          withAnimation {
            currentIngredient.position = currentSection.ingredients.count
            currentSection.ingredients.append(currentIngredient)
          }
        }
      } else if let currentRecipe = recipe {
        if currentIngredient.recipe == nil && currentIngredient.section == nil {
          withAnimation {
            currentIngredient.position = currentRecipe.ingredients.count
            currentRecipe.ingredients.append(currentIngredient)
          }
        }
      }
    }

    defer {
      hasSaved = false
    }

    do {
      try context.save()
    } catch {
      print("Error saving ingredient: \(error)")
    }
  }
}

#Preview {
  let container = DataController.previewContainer

  let previewIngredients = [
    Ingredient(name: "Flour", location: .recipe, quantity: 2, unit: "cup", comment: "all-purpose"),
    Ingredient(name: "Garlic", location: .recipe, quantity: 3, unit: "clove", comment: "minced"),
    Ingredient(name: "Sauce", location: .recipe, quantity: 1, unit: "jar", comment: "marinara"),
  ]

  for ingredient in previewIngredients {
    container.mainContext.insert(ingredient)
  }

  struct PreviewWrapper: View {
    @State private var ingredient: Ingredient?
    @State private var showSheet = true
    private var location: IngredientLocation = .recipe

    init(ingredient: Ingredient) {
      self._ingredient = State(initialValue: ingredient)
    }

    var body: some View {
      ZStack {
        Spacer()
        VStack {
          Spacer()
          Text("Main View")
          Button("Show Sheet") { showSheet = true }
        }

        Spacer()

        FloatingBottomSheet(isPresented: $showSheet) {
          IngredientEditor(
            ingredientLocation: location,
            ingredient: $ingredient,
            showBottomSheet: $showSheet
          )
        }
      }
    }
  }

  return PreviewWrapper(ingredient: previewIngredients[0])
    .modelContainer(container)
}
