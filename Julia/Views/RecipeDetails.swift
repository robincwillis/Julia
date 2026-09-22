//
//  RecipeDetails.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import SwiftUI
import SwiftData
import UIKit

struct RecipeDetails: View {
  @Bindable var recipe: Recipe
  
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) var context
  @Environment(\.editMode) private var editMode
  
  private var isEditing: Bool {
    return editMode?.wrappedValue.isEditing ?? false
  }
  
  var ingredientLocation: IngredientLocation = .recipe
  
  @State private var showDeleteConfirmation = false
  @State private var selectedIngredient: Ingredient?
  @State private var selectedSection: IngredientSection?
  @State private var showIngredientEditor = false
  @State private var selectedIngredients: Set<Ingredient> = []
  @State private var showRawTextSheet = false
  @State private var showSourceSheet = false
  @State private var showChefChat = false

  @State private var adjustedServings: Int? = nil
  @State private var showServingAdjuster = false
  @State private var showCookMode = false
  @State private var unitSystem: UnitSystem? = nil

  // Recipe actions
  @State private var showCompleteRecipeConfirmation = false
  @State private var showAddedToGroceryAlert = false
  @State private var showCompleteRecipeResult = false
  @State private var addedToGroceryCount = 0
  @State private var usedFromPantryCount = 0
  @State private var skippedFromPantryCount = 0

  @State private var titleIsVisible: Bool = true
  @State private var focusedField: RecipeFocusedField = .none

  // Edit with AI
  @State private var isRunningAIEdit = false
  @State private var aiEditError: String?
  @State private var showAIEditError = false
  @State private var showAIEditNothingToFix = false

  private var servingMultiplier: Double {
    guard let adjusted = adjustedServings, let original = recipe.servings, original > 0 else {
      return 1.0
    }
    return Double(adjusted) / Double(original)
  }
  
  @ViewBuilder
  private var editModeContent: some View {
    Form {
      // Edit Summary Section
      RecipeEditSummarySection(
        title: $recipe.title,
        summary: $recipe.summary,
        servings: $recipe.servings,
        focusedField: $focusedField
      )
      
      RecipeEditTimingsSection(
        timings: $recipe.timings
      )
      
      // Ingredients section
      RecipeEditIngredientsSection(
        ingredients: $recipe.ingredients,
        sections: $recipe.sections,
        selectedIngredient: $selectedIngredient,
        selectedSection: $selectedSection,
        showIngredientEditor: $showIngredientEditor
      )
      
      // Instructions section
      RecipeEditInstructionsSection(
        instructions: $recipe.instructions,
        focusedField: $focusedField
      )
      
      RecipeEditNotesSection(
        notes: $recipe.notes,
        focusedField: $focusedField
      )
      
      RecipeEditTagsSection(
        tags: $recipe.tags
      )
      
    }
    .scrollContentBackground(.hidden)
    .background(Color.app.backgroundSecondary)
    .listStyle(.insetGrouped)
    .navigationTitle(recipe.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if focusedField.needsDoneButton {
        ToolbarItemGroup(placement: .keyboard) {
          HStack(spacing: 12) {
            if focusedField == .servings {
              Button("Clear") {
                recipe.servings = nil
              }
              .foregroundStyle(Color.app.secondary)
            }

            Spacer()

            Button("Done") {
              hideKeyboard()
            }
            .foregroundStyle(Color.app.primary)
            .fontWeight(.medium)
          }
          .keyboardAccessoryBarStyle()
          .padding(.bottom, 24)
        }
        .hidesSharedGlassBackground()
      }
    }
    .overlay {
      if isRunningAIEdit {
        aiEditOverlay
      }
    }
  }

  private var aiEditOverlay: some View {
    ZStack {
      Color.black.opacity(0.2)
        .ignoresSafeArea()

      VStack(spacing: 16) {
        ProgressView()
          .scaleEffect(1.2)
        Text("Fixing recipe with AI…")
          .font(.subheadline)
          .foregroundColor(Color.app.textPrimary)
      }
      .padding(16)
      .background(Color.app.white)
      .cornerRadius(12)
      .shadow(radius: 5)
    }
    .transition(.opacity)
  }


  @ViewBuilder
  private var viewModeContent: some View {
    ZStack(alignment: .top) {
      ScrollView(.vertical, showsIndicators: true) {
        VStack(alignment: .leading, spacing: 24) {
          ScrollFadeTitle(
            title: recipe.title,
            titleIsVisible: $titleIsVisible
          )
          
          // Title and Summary Section
          RecipeSummarySection(
            recipe: recipe,
            adjustedServings: adjustedServings,
            onTapServings: recipe.servings != nil ? { showServingAdjuster = true } : nil
          )

          // Ingredients Section with selectable ingredients
          RecipeIngredientsSection(
            recipe: recipe,
            multiplier: servingMultiplier,
            adjustedServings: $adjustedServings,
            unitSystem: $unitSystem,
            selectableBinding: selectableBinding(for:),
            toggleSelection: toggleSelection(for:)
          )

          // Additional Ingredient Sections
          if !recipe.sections.isEmpty {
            IngredientSectionList(
              sections: recipe.sections,
              multiplier: servingMultiplier,
              unitSystem: unitSystem,
              selectableBinding: selectableBinding(for:),
              toggleSelection: toggleSelection(for:)
            )
          }
          
          // Instructions Section
          RecipeInstructionsSection(recipe: recipe)
          
          RecipeNotesSection(
            notes: recipe.notes
          )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 48)
      }
    }
    .coordinateSpace(name: "scrollContainer")
    .navigationTitle(!titleIsVisible ? recipe.title : "")
    .navigationBarTitleDisplayMode(.inline)
    .edgesIgnoringSafeArea(.bottom)
  }

  private var ingredientEditorSheet: some View {
    FloatingBottomSheet(
      isPresented: $showIngredientEditor,
      showHideTabBar: false
    ) {
      IngredientEditor(
        ingredientLocation: ingredientLocation,
        ingredient: $selectedIngredient,
        recipe: recipe,
        section: selectedSection,
        showBottomSheet: $showIngredientEditor
      )
    }
  }
  
  @ToolbarContentBuilder
  private var mainToolbarItems: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button { dismiss() } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color.app.primary)
      }
      .circleToolbarButtonStyle(background: Color.app.backgroundSheet)
      .buttonStyle(.plain)
    }
    .hidesSharedGlassBackground()

    ToolbarItem(placement: .primaryAction) {
      if isEditing {
        Button {
          editMode?.wrappedValue = .inactive
        } label: {
          Image(systemName: "checkmark")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.app.primary)
        }
        .circleToolbarButtonStyle(background: Color.app.backgroundSheet)
        .buttonStyle(.plain)
      }
    }
    .hidesSharedGlassBackground()

    if !isEditing {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          showChefChat = true
        } label: {
          GlowingIcon(systemName: "circle.fill", size: 12)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask Julia")
      }
      .hidesSharedGlassBackground()

      if !recipe.instructions.isEmpty {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showCookMode = true
          } label: {
            Image(systemName: "play.fill")
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(Color.app.primary)
          }
          .circleToolbarButtonStyle(background: Color.app.backgroundSheet)
          .buttonStyle(.plain)
          .accessibilityLabel("Start cooking")
        }
        .hidesSharedGlassBackground()
      }
    }

    ToolbarItem(placement: .navigationBarTrailing) {
      if isEditing {
        editingMenu
      } else {
        Menu {
          if !selectedIngredients.isEmpty {
            Button(action: {
              addSelectedToLocation(location: .grocery)
            }) {
              Label("Add to Groceries", systemImage: "basket.fill")
            }
            .tint(Color.app.primary)

            Button(action: {
              addSelectedToLocation(location: .pantry)
            }) {
              Label("Add to Pantry", systemImage: "cabinet.fill")
            }
            .tint(Color.app.primary)

            Button(action: selectAll) {
              Label("Select All", systemImage: "checklist.checked")
            }
            .tint(Color.app.primary)

            Button(action: clearSelection) {
              Label("Clear Selection", systemImage: "xmark.circle")
            }
            .tint(Color.app.primary)

            Divider()
          }

          Button("Edit Recipe", systemImage: "pencil") {
            editMode?.wrappedValue = .active
          }
          if !recipe.ingredients.isEmpty || !recipe.sections.isEmpty {
            Divider()
            if selectedIngredients.isEmpty {
              Button("Add to Groceries", systemImage: "basket") {
                addAllToGroceryList()
              }
            }
            Button("Complete Recipe", systemImage: "checkmark.seal", role: .destructive) {
              showCompleteRecipeConfirmation = true
            }
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 14))
            .foregroundColor(Color.app.primary)
        }
        .circleToolbarButtonStyle(background: Color.app.backgroundSheet)
      }
    }
    .hidesSharedGlassBackground()
  }

  private var editingMenu: some View {
    Menu {
      Button("Edit with AI", systemImage: "sparkles") {
        Task { await runAIEdit() }
      }
      .tint(Color.app.primary)
      .disabled(isRunningAIEdit)

      Divider()

      Button("Show Raw Text", systemImage: "text.quote") {
        showRawTextSheet = true
      }
      .tint(Color.app.primary)
      Button("Show Source", systemImage: "text.page.badge.magnifyingglass") {
        showSourceSheet = true
      }
      .tint(Color.app.primary)
      Button("Delete Recipe", systemImage: "trash", role: .destructive) {
        showDeleteConfirmation = true
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 14))
        .foregroundColor(Color.app.primary)
        .animation(.snappy, value: isEditing)
        .transition(.opacity)
    }
    .circleToolbarButtonStyle(background: Color.app.backgroundSheet)
  }

  private var rawTextSheet: some View {
    RecipeRawTextSection(recipe: recipe)
      .presentationDetents([.medium, .large])
      .background(.background.secondary)
      .presentationDragIndicator(.hidden)
  }
  
  private var sourceSheet: some View {
    Form {
      RecipeEditSourceSection(
        source: Binding($recipe.source, default: ""),
        sourceTitle: Binding($recipe.sourceTitle, default: ""),
        author: Binding($recipe.author, default: ""),
        website: Binding($recipe.website, default: ""),
        sourceType: Binding($recipe.sourceType,  default: SourceType.unknown)
      )
    }
    .scrollContentBackground(.hidden)
    .background(Color.app.backgroundSecondary)
    .presentationDetents([.medium, .large])
    .background(.background.secondary)
    .presentationDragIndicator(.hidden)
  }
  
  // MARK: - Body
  var body: some View {
    ZStack {
      // Main content based on edit mode
      if isEditing {
        editModeContent
      } else {
        viewModeContent
      }
      
      // Floating ingredient editor
      ingredientEditorSheet
    }
    .navigationBarBackButtonHidden(true)
    .toolbar { mainToolbarItems }
    .confirmationDialog(
      "Are you sure?",
      isPresented: $showDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Delete Recipe", role: .destructive) {
        deleteRecipe()
      }
    }
    .confirmationDialog(
      "Complete Recipe",
      isPresented: $showCompleteRecipeConfirmation,
      titleVisibility: .visible
    ) {
      Button("Remove from Pantry", role: .destructive) {
        completeRecipe()
      }
    } message: {
      Text("Matching ingredients will be removed from your pantry. This cannot be undone.")
    }
    .alert("Added to Grocery List", isPresented: $showAddedToGroceryAlert) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("Added \(addedToGroceryCount) ingredient\(addedToGroceryCount == 1 ? "" : "s") to your grocery list.")
    }
    .alert("Recipe Complete", isPresented: $showCompleteRecipeResult) {
      Button("OK", role: .cancel) { }
    } message: {
      if skippedFromPantryCount > 0 {
        Text("Removed \(usedFromPantryCount) item\(usedFromPantryCount == 1 ? "" : "s") from your pantry. \(skippedFromPantryCount) ingredient\(skippedFromPantryCount == 1 ? "" : "s") weren't in your pantry.")
      } else {
        Text("Removed \(usedFromPantryCount) item\(usedFromPantryCount == 1 ? "" : "s") from your pantry.")
      }
    }
    .alert("Nothing to Fix", isPresented: $showAIEditNothingToFix) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("All ingredients look well-structured and servings, timing, and summary are already filled in.")
    }
    .alert("Edit with AI Failed", isPresented: $showAIEditError) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(aiEditError ?? "Unknown error occurred")
    }
    .onChange(of: showIngredientEditor) { oldValue, newValue in
      // Only execute when the sheet is being dismissed
      if oldValue == true && newValue == false {
        // Clear the selection after handling everything
        selectedIngredient = nil
        selectedSection = nil
      }
    }
    .onAppear {
      NotificationCenter.default.post(name: .hideTabBar, object: nil)
    }
    .onDisappear {
      NotificationCenter.default.post(name: .showTabBar, object: nil)
      if editMode?.wrappedValue.isEditing == true {
        editMode?.wrappedValue = .inactive
      }
      adjustedServings = nil
    }
    .fullScreenCover(isPresented: $showCookMode) {
      CookModeView(recipe: recipe, servingMultiplier: servingMultiplier)
    }
    .sheet(isPresented: $showServingAdjuster, onDismiss: { }) {
      ServingAdjusterSheet(
        originalServings: recipe.servings ?? 1,
        adjustedServings: $adjustedServings
      )
      .presentationDetents([.height(240)])
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showRawTextSheet) {
      rawTextSheet
    }
    .sheet(isPresented: $showSourceSheet) {
      sourceSheet
    }
    .sheet(isPresented: $showChefChat) {
      ChefChatView(recipe: recipe)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
  }
  
  private func deleteIngredient(_ ingredient: Ingredient) {
    // Remove from recipe if needed
    if let recipe = ingredient.recipe {
      recipe.ingredients.removeAll(where: { $0.id == ingredient.id })
    }
    
    // Remove from section if needed
    if let section = ingredient.section {
      section.ingredients.removeAll(where: { $0.id == ingredient.id })
    }
    
    // Delete from context
    context.delete(ingredient)
    
    do {
      try context.save()
    } catch {
      print("Error deleting empty ingredient: \(error)")
    }
  }
  
  private func deleteRecipe() {
    // First explicitly clear relationships to prevent access to deleted objects
    let ingredientsCopy = recipe.ingredients
    let sectionsCopy = recipe.sections
    
    // Clear relationship arrays first
    recipe.ingredients = []
    recipe.sections = []
    
    // Then delete all related objects explicitly
    for ingredient in ingredientsCopy {
      context.delete(ingredient)
    }
    
    for section in sectionsCopy {
      // Clear section's ingredients to avoid nested access
      let sectionIngredients = section.ingredients
      section.ingredients = []
      
      // Delete section's ingredients
      for ingredient in sectionIngredients {
        context.delete(ingredient)
      }
      
      // Delete the section
      context.delete(section)
    }
    
    // Now delete the recipe
    context.delete(recipe)
    
    // We need to handle potential errors when changes are saved
    do {
      try context.save()
    } catch {
      print("Error deleting recipe: \(error)")
    }
    showDeleteConfirmation = false
    dismiss()
  }
  
  // Ingredient Selection Methods
  
  // Create a binding for the selectable modifier
  private func selectableBinding(for ingredient: Ingredient) -> Binding<Bool> {
    Binding(
      get: { selectedIngredients.contains(ingredient) },
      set: { isSelected in
        if isSelected {
          selectedIngredients.insert(ingredient)
        } else {
          selectedIngredients.remove(ingredient)
        }
      }
    )
  }
  
  // Toggle selection for an ingredient
  private func toggleSelection(for ingredient: Ingredient) {
    if selectedIngredients.contains(ingredient) {
      selectedIngredients.remove(ingredient)
    } else {
      selectedIngredients.insert(ingredient)
    }
  }
  
  // Add selected ingredients to grocery list
  private func addSelectedToLocation(location: IngredientLocation) {
    for ingredient in selectedIngredients {
      // Create a copy of the ingredient for the list
      let newIngredient = Ingredient(
        name: ingredient.name,
        location: location,  // Change location
        quantity: ingredient.quantity,
        unit: ingredient.unit?.rawValue,
        comment: ingredient.comment
      )
      
      // Add to context
      context.insert(newIngredient)
    }
    
    // Save changes
    do {
      try context.save()
      
      // Clear selection
      clearSelection()
    } catch {
      print("Error saving items: \(error)")
    }
  }
  
  // Clear the current selection
  private func clearSelection() {
    selectedIngredients.removeAll()
  }
  
  private func selectAll() {
    let unsectionedIngredients = recipe.ingredients.filter { $0.section == nil }
    for ingredient in unsectionedIngredients {
      selectedIngredients.insert(ingredient)
    }
    for section in recipe.sections {
      for ingredient in section.ingredients {
        selectedIngredients.insert(ingredient)
      }
    }
  }

  // MARK: - Recipe Actions

  private func allRecipeIngredients() -> [Ingredient] {
    var all = recipe.ingredients.filter { $0.section == nil }
    for section in recipe.sections {
      all += section.ingredients
    }
    return all
  }

  private func runAIEdit() async {
    let unstructured = allRecipeIngredients().filter { $0.quantity == nil && $0.unit == nil }
    let needsServings = recipe.servings == nil
    let needsSummary = (recipe.summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let needsTimings = recipe.timings.isEmpty

    guard !unstructured.isEmpty || needsServings || needsSummary || needsTimings else {
      showAIEditNothingToFix = true
      return
    }

    guard await FoundationModelsService.shared.isAvailable else {
      aiEditError = "Apple Intelligence is not available on this device."
      showAIEditError = true
      return
    }

    isRunningAIEdit = true
    defer { isRunningAIEdit = false }

    let sortedInstructions = recipe.instructions
      .sorted { $0.position < $1.position }
      .map { $0.value }

    let input = FoundationModelsRecipeEditor.Input(
      title: recipe.title,
      instructions: sortedInstructions,
      unstructuredIngredients: unstructured.map { $0.name },
      needsServings: needsServings,
      needsSummary: needsSummary,
      needsTimings: needsTimings
    )

    do {
      let result = try await FoundationModelsRecipeEditor().edit(input)
      applyAIEdit(result, to: unstructured, needsServings: needsServings, needsSummary: needsSummary, needsTimings: needsTimings)
      try context.save()
    } catch {
      aiEditError = "Could not edit recipe: \(error.localizedDescription)"
      showAIEditError = true
    }
  }

  /// Applies the model's response back onto the recipe. Ingredients are
  /// matched to the request by index/count — mismatched counts are skipped
  /// entirely for that ingredient rather than guessed at. Recipe-level
  /// fields are only written when the caller said they were missing, so a
  /// field the model filled in despite not being asked is simply ignored.
  private func applyAIEdit(
    _ result: RecipeAIEdit,
    to unstructuredIngredients: [Ingredient],
    needsServings: Bool,
    needsSummary: Bool,
    needsTimings: Bool
  ) {
    if result.ingredients.count == unstructuredIngredients.count {
      for (ingredient, parsed) in zip(unstructuredIngredients, result.ingredients) {
        guard !parsed.name.isEmpty else { continue }
        ingredient.name = parsed.name
        ingredient.quantity = Double(parsed.quantity)
        ingredient.unit = MeasurementUnit(from: parsed.unit)
        ingredient.comment = parsed.comment.isEmpty ? nil : parsed.comment
      }
    }

    if needsServings, let servings = Int(result.servings) {
      recipe.servings = servings
    }

    if needsSummary, !result.summary.isEmpty {
      recipe.summary = result.summary
    }

    if needsTimings, !result.timings.isEmpty {
      for (index, timing) in result.timings.enumerated() {
        let newTiming = Timing(type: timing.type, hours: timing.hours, minutes: timing.minutes, position: index)
        context.insert(newTiming)
        recipe.timings.append(newTiming)
      }
    }
  }

  private func addAllToGroceryList() {
    let ingredients = allRecipeIngredients()
    for ingredient in ingredients {
      let scaledQty: Double? = ingredient.quantity.map { $0 * servingMultiplier }
      let copy = Ingredient(
        name: ingredient.name,
        location: .grocery,
        quantity: scaledQty,
        unit: ingredient.unit?.rawValue,
        comment: ingredient.comment
      )
      context.insert(copy)
    }
    do {
      try context.save()
      addedToGroceryCount = ingredients.count
      showAddedToGroceryAlert = true
    } catch {
      print("Error adding ingredients to grocery list: \(error)")
    }
  }

  private func completeRecipe() {
    let ingredients = allRecipeIngredients()

    // Fetch all pantry items — filter in Swift to avoid enum predicate complexity
    let descriptor = FetchDescriptor<Ingredient>()
    guard let allStored = try? context.fetch(descriptor) else { return }
    let pantryItems = allStored.filter { $0.location == .pantry }

    var used = 0
    var skipped = 0

    for recipeIngredient in ingredients {
      let scaledQty: Double? = recipeIngredient.quantity.map { $0 * servingMultiplier }
      let matches = pantryItems.filter {
        $0.name.lowercased() == recipeIngredient.name.lowercased()
      }

      if matches.isEmpty {
        skipped += 1
        continue
      }

      for pantryItem in matches {
        if let pantryQty = pantryItem.quantity, let needed = scaledQty,
           pantryItem.unit == recipeIngredient.unit {
          // Same unit — subtract quantity
          let remaining = pantryQty - needed
          if remaining <= 0 {
            context.delete(pantryItem)
          } else {
            pantryItem.quantity = remaining
          }
        } else if pantryItem.quantity == nil {
          // No quantity tracking — remove entirely
          context.delete(pantryItem)
        }
        // Units differ — leave the pantry item untouched (can't convert)
      }
      used += 1
    }

    do {
      try context.save()
      usedFromPantryCount = used
      skippedFromPantryCount = skipped
      showCompleteRecipeResult = true
    } catch {
      print("Error completing recipe: \(error)")
    }
  }
}

#Preview("Recipe Details") {
  Previews.customRecipe(
    hasSections:true,
    hasTimings: true
  ) { recipe in
    RecipeDetails(recipe: recipe)
      .padding()
  }
}
