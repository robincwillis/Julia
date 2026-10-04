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

  @State private var showCompleteRecipeConfirmation = false
  @State private var showAddedToGroceryAlert = false
  @State private var showCompleteRecipeResult = false
  @State private var addedToGroceryCount = 0
  @State private var usedFromPantryCount = 0
  @State private var skippedFromPantryCount = 0

  @State private var titleIsVisible: Bool = true
  @State private var focusedField: RecipeFocusedField = .none

  @State private var isRunningAIEdit = false
  @State private var aiEditError: String?
  @State private var showAIEditError = false
  @State private var showAIEditNothingToFix = false
  @State private var showAIEditPrompt = false
  @State private var aiEditCustomInstruction = ""

  private var servingMultiplier: Double {
    guard let adjusted = adjustedServings, let original = recipe.servings, original > 0 else {
      return 1.0
    }
    return Double(adjusted) / Double(original)
  }
  
  @ViewBuilder
  private var editModeContent: some View {
    Form {
      RecipeEditSummarySection(
        title: $recipe.title,
        summary: $recipe.summary,
        servings: $recipe.servings,
        focusedField: $focusedField
      )

      RecipeEditTimingsSection(
        timings: $recipe.timings
      )

      RecipeEditIngredientsSection(
        ingredients: $recipe.ingredients,
        sections: $recipe.sections,
        selectedIngredient: $selectedIngredient,
        selectedSection: $selectedSection,
        showIngredientEditor: $showIngredientEditor
      )

      RecipeEditInstructionsSection(
        instructions: $recipe.instructions,
        instructionSections: $recipe.instructionSections,
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
          
          RecipeSummarySection(
            recipe: recipe,
            adjustedServings: adjustedServings,
            onTapServings: recipe.servings != nil ? { showServingAdjuster = true } : nil
          )

          RecipeIngredientsSection(
            recipe: recipe,
            multiplier: servingMultiplier,
            adjustedServings: $adjustedServings,
            unitSystem: $unitSystem,
            selectableBinding: selectableBinding(for:),
            toggleSelection: toggleSelection(for:)
          )

          if !recipe.sections.isEmpty {
            IngredientSectionList(
              sections: recipe.sections,
              multiplier: servingMultiplier,
              unitSystem: unitSystem,
              selectableBinding: selectableBinding(for:),
              toggleSelection: toggleSelection(for:)
            )
          }

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
        aiEditCustomInstruction = ""
        showAIEditPrompt = true
      }
      .tint(Color.app.primary)
      .disabled(isRunningAIEdit)

      Button("Undo Last Edit", systemImage: "arrow.uturn.backward") {
        context.undoManager?.undo()
        try? context.save()
      }
      .tint(Color.app.primary)
      .disabled(!(context.undoManager?.canUndo ?? false))

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

  private var aiEditPromptSheet: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        Text("Restructures ingredients that didn't import cleanly, and fills in missing servings, timing, or summary. Add specific instructions below if you want — e.g. \"make this vegetarian\" or \"double the recipe.\"")
          .font(.subheadline)
          .foregroundStyle(Color.app.textSecondary)

        ZStack(alignment: .topLeading) {
          if aiEditCustomInstruction.isEmpty {
            Text("Custom instructions (optional)")
              .foregroundStyle(Color.app.textPlaceholder)
              .padding(.horizontal, 5)
              .padding(.vertical, 9)
              .allowsHitTesting(false)
          }
          TextEditor(text: $aiEditCustomInstruction)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 1)
        }
        .frame(minHeight: 100)
        .padding(8)
        .background(Color.app.backgroundInput, in: RoundedRectangle(cornerRadius: 12))

        Spacer()
      }
      .padding()
      .background(Color.app.backgroundSheet)
      .navigationTitle("Edit with AI")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            showAIEditPrompt = false
          }
          .foregroundStyle(Color.app.primary)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Edit Recipe") {
            showAIEditPrompt = false
            Task { await runAIEdit() }
          }
          .foregroundStyle(Color.app.primary)
          .fontWeight(.medium)
        }
      }
    }
  }

  var body: some View {
    ZStack {
      if isEditing {
        editModeContent
      } else {
        viewModeContent
      }

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
      if oldValue == true && newValue == false {
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
    .sheet(isPresented: $showAIEditPrompt) {
      aiEditPromptSheet
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showChefChat) {
      ChefChatView(recipe: recipe)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
  }
  
  private func deleteIngredient(_ ingredient: Ingredient) {
    if let recipe = ingredient.recipe {
      recipe.ingredients.removeAll(where: { $0.id == ingredient.id })
    }

    if let section = ingredient.section {
      section.ingredients.removeAll(where: { $0.id == ingredient.id })
    }

    context.delete(ingredient)

    do {
      try context.save()
    } catch {
      print("Error deleting empty ingredient: \(error)")
    }
  }

  private func deleteRecipe() {
    let ingredientsCopy = recipe.ingredients
    let sectionsCopy = recipe.sections

    recipe.ingredients = []
    recipe.sections = []

    for ingredient in ingredientsCopy {
      context.delete(ingredient)
    }

    for section in sectionsCopy {
      let sectionIngredients = section.ingredients
      section.ingredients = []

      for ingredient in sectionIngredients {
        context.delete(ingredient)
      }

      context.delete(section)
    }

    context.delete(recipe)

    do {
      try context.save()
    } catch {
      print("Error deleting recipe: \(error)")
    }
    showDeleteConfirmation = false
    dismiss()
  }

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

  private func toggleSelection(for ingredient: Ingredient) {
    if selectedIngredients.contains(ingredient) {
      selectedIngredients.remove(ingredient)
    } else {
      selectedIngredients.insert(ingredient)
    }
  }

  private func addSelectedToLocation(location: IngredientLocation) {
    for ingredient in selectedIngredients {
      let newIngredient = Ingredient(
        name: ingredient.name,
        location: location,
        quantity: ingredient.quantity,
        unit: ingredient.unit?.rawValue,
        comment: ingredient.comment
      )

      context.insert(newIngredient)
    }

    do {
      try context.save()
      clearSelection()
    } catch {
      print("Error saving items: \(error)")
    }
  }

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

  private func allRecipeIngredients() -> [Ingredient] {
    var all = recipe.ingredients.filter { $0.section == nil }
    for section in recipe.sections {
      all += section.ingredients
    }
    return all
  }

  /// Cheap pre-check for "this line is probably actually a section
  /// heading" (e.g. "For the dressing", "Dressing:") — short, and either
  /// starts with "for " or ends with a colon. Applies equally to an
  /// instruction step's text or an ingredient's name. Only decides whether
  /// it's worth asking the model to look; the model makes the real call.
  private func looksLikeSectionHeading(_ text: String) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed.split(separator: " ").count <= 6 else { return false }
    return trimmed.lowercased().hasPrefix("for ") || trimmed.hasSuffix(":")
  }

  private func runAIEdit() async {
    let customInstruction = aiEditCustomInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
    let hasCustomInstruction = !customInstruction.isEmpty
    let unstructured = allRecipeIngredients().filter { $0.quantity == nil && $0.unit == nil }
    let unsectionedIngredients = recipe.ingredients.filter { $0.section == nil }
    let needsServings = recipe.servings == nil
    let needsSummary = (recipe.summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let needsTimings = recipe.timings.isEmpty
    let hasPossibleInstructionHeading = recipe.instructions.contains { looksLikeSectionHeading($0.value) }
    let hasPossibleIngredientHeading = unsectionedIngredients.contains { looksLikeSectionHeading($0.name) }

    // A custom instruction like "make this vegetarian" or "double the
    // recipe" needs to see and possibly revise every ingredient, not just
    // the unstructured ones — and is reason enough to run even when nothing
    // looks structurally broken.
    let ingredientsToSend = hasCustomInstruction ? allRecipeIngredients() : unstructured

    guard !unstructured.isEmpty || needsServings || needsSummary || needsTimings
      || hasCustomInstruction || hasPossibleInstructionHeading || hasPossibleIngredientHeading else {
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
    let sortedUnsectionedIngredients = unsectionedIngredients
      .sorted { $0.position < $1.position }

    let input = FoundationModelsRecipeEditor.Input(
      title: recipe.title,
      instructions: sortedInstructions,
      ingredientLines: ingredientsToSend.map { IngredientParser.toString(for: $0) },
      unsectionedIngredientLines: sortedUnsectionedIngredients.map { IngredientParser.toString(for: $0) },
      needsServings: needsServings,
      needsSummary: needsSummary,
      needsTimings: needsTimings,
      customInstruction: hasCustomInstruction ? customInstruction : nil
    )

    do {
      let result = try await FoundationModelsRecipeEditor().edit(input)
      applyAIEdit(
        result,
        to: ingredientsToSend,
        unsectionedIngredients: sortedUnsectionedIngredients,
        needsServings: needsServings,
        needsSummary: needsSummary,
        needsTimings: needsTimings,
        hasCustomInstruction: hasCustomInstruction
      )
      try context.save()
    } catch {
      aiEditError = "Could not edit recipe: \(error.localizedDescription)"
      showAIEditError = true
    }
  }

  /// Applies the model's response back onto the recipe. Ingredients are
  /// matched to the request by index/count — mismatched counts are skipped
  /// entirely for that ingredient rather than guessed at. Servings/summary
  /// are only written when the caller said they were missing, unless a
  /// custom instruction was given — that's the one case where an explicit
  /// user ask (e.g. "double the recipe") is allowed to overwrite an
  /// existing value. Timings are always fill-only regardless, since
  /// reconciling an edit against existing Timing entries from free text
  /// isn't handled here.
  private func applyAIEdit(
    _ result: RecipeAIEdit,
    to sentIngredients: [Ingredient],
    unsectionedIngredients: [Ingredient],
    needsServings: Bool,
    needsSummary: Bool,
    needsTimings: Bool,
    hasCustomInstruction: Bool
  ) {
    context.undoManager?.beginUndoGrouping()
    context.undoManager?.setActionName("Edit with AI")
    defer { context.undoManager?.endUndoGrouping() }

    if result.ingredients.count == sentIngredients.count {
      for (ingredient, parsed) in zip(sentIngredients, result.ingredients) {
        guard !parsed.name.isEmpty else { continue }
        ingredient.name = parsed.name
        ingredient.quantity = Double(parsed.quantity)
        ingredient.unit = MeasurementUnit(from: parsed.unit)
        ingredient.comment = parsed.comment.isEmpty ? nil : parsed.comment
      }
    }

    if (needsServings || hasCustomInstruction), let servings = Int(result.servings) {
      recipe.servings = servings
    }

    if (needsSummary || hasCustomInstruction), !result.summary.isEmpty {
      recipe.summary = result.summary
    }

    if needsTimings, !result.timings.isEmpty {
      for (index, timing) in result.timings.enumerated() {
        let newTiming = Timing(type: timing.type, hours: timing.hours, minutes: timing.minutes, position: index)
        context.insert(newTiming)
        recipe.timings.append(newTiming)
      }
    }

    if !result.instructionGroups.isEmpty {
      applyInstructionGroups(result.instructionGroups)
    }

    if !result.ingredientGroups.isEmpty {
      applyIngredientGroups(result.ingredientGroups, replacing: unsectionedIngredients)
    }
  }

  /// Replaces the unsectioned ingredients with the model's regrouped ones:
  /// the first empty-named group becomes the new unsectioned list, and
  /// every named group becomes a new IngredientSection appended after any
  /// that already exist. Old Ingredient objects are deleted rather than
  /// reused, matching how UpdateRecipeTool replaces ingredients.
  ///
  /// `recipe.ingredients` invariantly holds only unsectioned ingredients
  /// (sectioned ones live in `section.ingredients` — see `moveIngredient`),
  /// so it's safe to clear wholesale here, same as `applyInstructionGroups`
  /// does for `recipe.instructions`.
  private func applyIngredientGroups(_ groups: [ClassifiedIngredientGroup], replacing oldIngredients: [Ingredient]) {
    for old in oldIngredients { context.delete(old) }
    recipe.ingredients.removeAll()

    var sectionPosition = recipe.sections.count

    for group in groups {
      guard !group.ingredients.isEmpty else { continue }

      if group.name.isEmpty {
        for (index, parsed) in group.ingredients.enumerated() {
          guard !parsed.name.isEmpty else { continue }
          let ingredient = Ingredient(
            name: parsed.name,
            location: .recipe,
            quantity: Double(parsed.quantity),
            unit: parsed.unit.isEmpty ? nil : parsed.unit,
            comment: parsed.comment.isEmpty ? nil : parsed.comment,
            position: index,
            recipe: recipe
          )
          recipe.ingredients.append(ingredient)
          context.insert(ingredient)
        }
      } else {
        let section = IngredientSection(name: group.name, position: sectionPosition, recipe: recipe)
        context.insert(section)
        for (index, parsed) in group.ingredients.enumerated() {
          guard !parsed.name.isEmpty else { continue }
          let ingredient = Ingredient(
            name: parsed.name,
            location: .recipe,
            quantity: Double(parsed.quantity),
            unit: parsed.unit.isEmpty ? nil : parsed.unit,
            comment: parsed.comment.isEmpty ? nil : parsed.comment,
            position: index,
            section: section
          )
          section.ingredients.append(ingredient)
          context.insert(ingredient)
        }
        recipe.sections.append(section)
        sectionPosition += 1
      }
    }
  }

  /// Replaces the unsectioned instructions with the model's regrouped
  /// steps: the first empty-named group becomes the new unsectioned list,
  /// and every named group becomes a new InstructionSection appended after
  /// any that already exist. Old Step objects are deleted rather than
  /// reused, matching how UpdateRecipeTool replaces instructions.
  private func applyInstructionGroups(_ groups: [ClassifiedInstructionGroup]) {
    for old in recipe.instructions { context.delete(old) }
    recipe.instructions.removeAll()

    var sectionPosition = recipe.instructionSections.count

    for group in groups {
      guard !group.steps.isEmpty else { continue }

      if group.name.isEmpty {
        for (index, value) in group.steps.enumerated() {
          let step = Step(value: value, position: index, recipe: recipe)
          recipe.instructions.append(step)
          context.insert(step)
        }
      } else {
        let section = InstructionSection(name: group.name, position: sectionPosition, recipe: recipe)
        context.insert(section)
        for (index, value) in group.steps.enumerated() {
          let step = Step(value: value, position: index, section: section)
          section.steps.append(step)
          context.insert(step)
        }
        recipe.instructionSections.append(section)
        sectionPosition += 1
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
