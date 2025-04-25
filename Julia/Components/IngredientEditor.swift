//
//  IngredientEditorView.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftUI
import SwiftData

struct IngredientEditor: View {
  var ingredientLocation: IngredientLocation
  @Binding var ingredient: Ingredient?
  var recipe: Recipe? = nil
  var section: IngredientSection? = nil
  @Binding var showBottomSheet: Bool
  
  @State private var showControls = false
  @State private var showNotes = false
  @State private var hasSaved = false
  
  @FocusState private var isNameFieldFocused: Bool
  @FocusState private var isCommentFieldFocused: Bool
  
  // Helper computed property to determine if any field is focused
  private var isAnyFieldFocused: Bool {
    // return withAnimation {
      isNameFieldFocused || isCommentFieldFocused
    // }
  }
  
  private var canSave: Bool {
    return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasSaved
  }
  
  
  @Environment(\.modelContext) private var context
  
  // Basic ingredient properties
  @State private var name: String = ""
  @State private var quantity: Double?
  @State private var unit: MeasurementUnit?
  @State private var comment: String = ""
  
  // For parsing from text input
  @State private var ingredientInput: String = ""
  
  let units = MeasurementUnit.allCases
  let numbers = MeasurementValue.numbers
  let fractions = MeasurementValue.fractions
  
  // Formatted measurement for display
  var displayMeasurement: String? {
    // If no quantity, no measurement to display
    if quantity == nil {
      return nil
    }
    
    var display = ""
    
    // Format quantity with fractions instead of decimals
    if let qty = quantity {
      // Get the integer and fractional parts
      let intPart = Int(floor(qty))
      let fracPart = qty - floor(qty)
      
      // Format the integer part if it's not zero
      if intPart > 0 {
        display += "\(intPart)"
      }
      
      // Format the fractional part using MeasurementValue fractions
      if fracPart > 0 {
        // Find the closest fraction from our enum
        let closestFraction = MeasurementValue.fractions
          .min(by: { abs($0.rawValue - fracPart) < abs($1.rawValue - fracPart) })
        
        // Only use the fraction if it's reasonably close to the actual value
        if let fraction = closestFraction, abs(fraction.rawValue - fracPart) < 0.1 {
          // Add space between whole number and fraction if needed
          if intPart > 0 {
            display += " "
          }
          display += fraction.displaySymbol
        }
      }
    }
    
    // Add unit if it exists and isn't "item"
    if let unitValue = unit, unitValue.rawValue != "item" {
      if !display.isEmpty {
        display += " "
      }
      
      // Pluralize unit if quantity > 1
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
  
  // Define rows for horizontal scrolling grid
  let rows = [
    GridItem(.fixed(36)),
    GridItem(.fixed(36)),
    GridItem(.fixed(36)),
    GridItem(.fixed(36))
  ]
  
  var body: some View {
    VStack(spacing: 0) {
      // Header with close/save buttons
      HStack {
        Button(action: {
          withAnimation {
            isNameFieldFocused.toggle()
          }
        }) {
          Image(systemName:  isNameFieldFocused ? "arrow.down"  :"arrow.up")
            .font(.title2)
        }
        .disabled(!canSave)
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
            .foregroundColor(canSave ? Color.app.primary : Color(red: 0.976, green: 0.667, blue: 0.576))
        }
      }
      //.transition(.opacity)
      
      VStack(alignment: .center, spacing: 12) {
        
        // Display Ingredient Measurement and Unit
        if let measurementLabel = displayMeasurement {
          Button(action: {
            withAnimation {
              isNameFieldFocused.toggle()
            }
          }) {
            Text(measurementLabel)
              .font(.system(size: 18, weight: .medium))
              .foregroundColor(.blue)
              .padding(.horizontal, 8)
              .frame(maxWidth: .infinity, alignment: .center)
          }
          .disabled(!canSave)
        }
        
        // Ingredient name field - either enter name or full ingredient text
        TextField("Ingredient", text: $name)
          .font(.system(
            //size: max(16, min(32, 700 / max(1, CGFloat(name.count)))),
            //size: calculateTitleFontSize(for: name),
            size: 32,
            weight: .medium
          ))
          .foregroundColor(Color.app.textPrimary)
          .tint(.blue)
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
          .background(.white)
        
        
        
        // Control panel that shows/hides based on focus state
        if showControls {
          VStack {
            // Units grid with horizontal scrolling
            ScrollView(.horizontal, showsIndicators: false) {
              LazyHGrid(rows: rows, spacing: 8) {
                ForEach(units, id: \.self) { unitOption in
                  Button(action: {
                    self.unit = unitOption
                  }) {
                    Text(unitOption.displayName)
                      .padding(6)
                      .font(.system(size: 12))
                      .frame(height: 36)
                      .frame(minWidth: 80)
                      .background(self.unit == unitOption ? Color.blue : Color.app.offWhite200)
                      .foregroundColor(self.unit == unitOption ? .white : Color.app.textPrimary)
                      .cornerRadius(12)
                      .fontWeight(self.unit == unitOption ? .bold : .regular)
                  }
                }
              }
            }
            
            // Fractions row
            HStack(spacing: 8) {
              ForEach(fractions, id: \.self) { fraction in
                Button(action: {
                  // Add fraction to quantity
                  if quantity == nil {
                    quantity = fraction.rawValue
                  } else {
                    // Get the integer part
                    let intPart = floor(quantity!)
                    // Replace the fractional part
                    quantity = intPart + fraction.rawValue
                  }
                }) {
                  Text(fraction.displaySymbol)
                    .padding(6)
                    .frame(minHeight: 40)
                    .frame(maxWidth: .infinity)
                    .background(Color.app.secondary)
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
              }
            }
            
            // Numbers grid
            VStack(spacing: 8) {
              
              // 3x3 grid for numbers 1-9
              ForEach(0..<3) { row in
                HStack(spacing: 8) {
                  ForEach(0..<3) { column in
                    let index = row * 3 + column
                    let number = numbers[index]
                    Button(action: {
                      // Add whole number to quantity
                      let numValue = Double(number.rawValue)
                      if quantity == nil {
                        quantity = numValue
                      } else {
                        // Multiply by 10 and add (e.g., 2 becomes 20 + new digit)
                        let intPart = floor(quantity!)
                        let fracPart = quantity! - intPart
                        quantity = (intPart * 10 + numValue) + fracPart
                      }
                    }) {
                      Text(number.displaySymbol)
                        .padding(6)
                        .frame(minHeight: 40)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBlue))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.medium)
                    }
                  }
                }
              }
              
              // Bottom row with 0 and Delete buttons
              HStack(spacing: 8) {
                // Zero button
                Button(action: {
                  if quantity == nil {
                    quantity = 0
                  } else {
                    // Multiply by 10 (append zero)
                    let intPart = floor(quantity!)
                    let fracPart = quantity! - intPart
                    quantity = (intPart * 10) + fracPart
                  }
                }) {
                  Text("0")
                    .padding(6)
                    .frame(minHeight: 40)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBlue))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Delete button - removes last digit or fraction
                Button(action: {
                  if quantity != nil {
                    if quantity! < 1 {
                      // If less than 1, just clear it
                      quantity = nil
                    } else {
                      // Get integer and fractional parts
                      let intPart = floor(quantity!)
                      let fracPart = quantity! - intPart
                      
                      if fracPart > 0 {
                        // Remove fraction part first
                        quantity = intPart
                      } else {
                        // Remove last digit
                        quantity = floor(intPart / 10)
                        if quantity == 0 {
                          quantity = nil
                        }
                      }
                    }
                  }
                  
                  // If quantity is nil/deleted and unit is set, also clear unit
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
            // Comment field that collapses when name is focused
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
        showControls = !isAnyFieldFocused && showBottomSheet;
      }
    }
    // Add this at the root view level
    .onChange(of: isNameFieldFocused) { oldValue, newValue in
      withAnimation {
        showNotes = !isNameFieldFocused && showBottomSheet;
      }
      // If losing focus and input looks like an ingredient with quantity
      if oldValue && !newValue && name.contains(" ") {
        // Parse the input
        if let parsedIngredient = IngredientParser.fromString(input: name, location: ingredientLocation) {
          name = parsedIngredient.name
          
          // Only update quantity and unit if they weren't already set
          if quantity == nil {
            quantity = parsedIngredient.quantity
          }
          
          if unit == nil {
            unit = parsedIngredient.unit
          } else {
            // Keep existing unit
          }
          
          // Always update comment if provided in parsing
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
      // No existing ingredient, set default values
      unit = MeasurementUnit(from: "item") // Default to "item" unit
      
      // Focus on name field for new ingredient
      //DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(5000))
        isNameFieldFocused = true
      }
      //}
      return
    }
    
    // Populate fields with existing ingredient data
    name = existingIngredient.name
    quantity = existingIngredient.quantity
    unit = existingIngredient.unit ?? MeasurementUnit(from: "item") // Default to item if nil
    comment = existingIngredient.comment ?? ""
    
  }
  
  private func saveIngredient() {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return }
    
    // If there's input text and no ingredient details, try to parse it
    if ingredientInput.isEmpty == false && quantity == nil && unit == nil {
      if let parsedIngredient = IngredientParser.fromString(input: ingredientInput, location: ingredientLocation) {
        // Use the parsed values if available
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
      // Update existing ingredient
      existingIngredient.name = trimmedName
      existingIngredient.quantity = quantity
      existingIngredient.unit = unit
      existingIngredient.comment = comment.isEmpty ? nil : comment
    } else {
      // Create new ingredient
      let newIngredient = Ingredient(
        name: trimmedName,
        location: ingredientLocation,
        quantity: quantity,
        unit: unit?.rawValue,
        comment: comment.isEmpty ? nil : comment
      )
      
      // Insert into context
      context.insert(newIngredient)
      ingredient = newIngredient
    }
    
    // Connect to section or recipe if needed
    if let currentIngredient = ingredient {
      if let currentSection = section {
        // Connect to section if provided
        if currentIngredient.section == nil {
          withAnimation {
            // Set position to end of the list for proper ordering
            currentIngredient.position = currentSection.ingredients.count
            currentSection.ingredients.append(currentIngredient)
          }
        }
      } else if let currentRecipe = recipe {
        // Connect to recipe if no section and not already connected
        if currentIngredient.recipe == nil && currentIngredient.section == nil {
          withAnimation {
            // Set position to end of the list for proper ordering
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
      // Reset hasSaved in case of error to allow retry
    }
  }
}

#Preview {
  // Preview container setup
  let container = DataController.previewContainer
  
  // Create preview data
  let previewIngredients = [
    Ingredient(
      name: "Flour",
      location: .recipe,
      quantity: 2,
      unit: "cup",
      comment: "all-purpose"
    ),
    Ingredient(
      name: "Garlic",
      location: .recipe,
      quantity: 3,
      unit: "clove",
      comment: "minced"
    ),
    Ingredient(
      name: "Sauce",
      location: .recipe,
      quantity: 1,
      unit: "jar",
      comment: "marinara"
    )
  ]
  
  // Insert ingredients
  for ingredient in previewIngredients {
    container.mainContext.insert(ingredient)
  }
  
  struct PreviewWrapper: View {
    // Use the ingredient we created in the container
    @State private var ingredient: Ingredient?
    @State private var showSheet = true
    private var location: IngredientLocation = .recipe
    
    init(ingredient: Ingredient) {
      self._ingredient = State(initialValue: ingredient)
    }
    
    var body: some View {
      ZStack {
        Spacer()
        // Main content
        VStack {
          Spacer()
          Text("Main View")
          Button("Show Sheet") {
            showSheet = true
          }
        }
        
        Spacer()
        
        FloatingBottomSheet(
          isPresented: $showSheet
        ) {
          IngredientEditor(
            ingredientLocation: location,
            ingredient: $ingredient,
            showBottomSheet: $showSheet
          )
        }
      }
    }
  }
  
  // Use the first preview ingredient
  return PreviewWrapper(ingredient: previewIngredients[0])
    .modelContainer(container)
}
