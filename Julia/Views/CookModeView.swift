//
//  CookModeView.swift
//  Julia
//

import SwiftUI
import SwiftData

struct CookModeView: View {
  let recipe: Recipe
  var servingMultiplier: Double = 1.0

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context

  @State private var currentStep = 0
  @State private var isDrawerExpanded = false
  @State private var showChefChat = false
  @State private var checkedIngredients: Set<Ingredient> = []
  @State private var showCompleteConfirmation = false
  @State private var showCompleteResult = false
  @State private var usedFromPantryCount = 0
  @State private var skippedFromPantryCount = 0

  private var steps: [Step] {
    recipe.instructions.sorted { $0.position < $1.position }
  }

  private var hasIngredients: Bool {
    !recipe.ingredients.isEmpty || !recipe.sections.isEmpty
  }

  private var unsectionedIngredients: [Ingredient] {
    recipe.ingredients
      .filter { $0.section == nil }
      .sorted { $0.position < $1.position }
  }

  private let collapsedDrawerHeight: CGFloat = 72

  var body: some View {
    ZStack(alignment: .bottom) {
      // Background
      Color(UIColor.systemBackground)
        .ignoresSafeArea()

      // Step carousel + top bar
      VStack(spacing: 0) {
        topBar

        if steps.isEmpty {
          emptyState
        } else {
          TabView(selection: $currentStep) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
              StepCardView(
                step: step,
                stepNumber: index + 1,
                totalSteps: steps.count
              )
              .tag(index)
            }
          }
          .tabViewStyle(.page(indexDisplayMode: .never))
          .animation(.easeInOut, value: currentStep)

          stepProgress
            .padding(.bottom, collapsedDrawerHeight + 16)
        }
      }

      // Dim overlay when drawer is open
      if isDrawerExpanded {
        Color.black.opacity(0.2)
          .ignoresSafeArea()
          .transition(.opacity)
          .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
              isDrawerExpanded = false
            }
          }
      }

      // Bottom drawer
      if hasIngredients {
        ingredientDrawer
      }
    }
    .sheet(isPresented: $showChefChat) {
      ChefChatView(recipe: recipe)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    .confirmationDialog(
      "Complete Recipe",
      isPresented: $showCompleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Remove from Pantry", role: .destructive) {
        completeRecipe()
      }
    } message: {
      Text("Matching ingredients will be removed from your pantry. This cannot be undone.")
    }
    .alert("Recipe Complete", isPresented: $showCompleteResult) {
      Button("Done") { dismiss() }
    } message: {
      if skippedFromPantryCount > 0 {
        Text("Removed \(usedFromPantryCount) item\(usedFromPantryCount == 1 ? "" : "s") from your pantry. \(skippedFromPantryCount) ingredient\(skippedFromPantryCount == 1 ? "" : "s") weren't in your pantry.")
      } else {
        Text("Removed \(usedFromPantryCount) item\(usedFromPantryCount == 1 ? "" : "s") from your pantry.")
      }
    }
  }

  // MARK: - Top Bar

  private var topBar: some View {
    HStack {
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(Color.app.textPrimary)
          .frame(width: 32, height: 32)
          .background(Color(UIColor.secondarySystemBackground))
          .clipShape(Circle())
      }
      .buttonStyle(.plain)

      Spacer()

      if !steps.isEmpty {
        Text("Step \(currentStep + 1) of \(steps.count)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .contentTransition(.numericText())
          .animation(.snappy, value: currentStep)
      }

      Spacer()

      HStack(spacing: 8) {
        Button {
          showCompleteConfirmation = true
        } label: {
          Image(systemName: "checkmark.circle")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.app.primary)
            .frame(width: 32, height: 32)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Complete recipe")

        Button {
          showChefChat = true
        } label: {
          Image(systemName: "fork.knife.circle")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.app.primary)
            .frame(width: 32, height: 32)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask Julia about this recipe")
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 4)
  }

  // MARK: - Step Progress Dots

  private var stepProgress: some View {
    HStack(spacing: 6) {
      ForEach(0..<steps.count, id: \.self) { index in
        Capsule()
          .fill(index == currentStep ? Color.app.primary : Color.secondary.opacity(0.25))
          .frame(
            width: index == currentStep ? 20 : 6,
            height: 6
          )
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
      }
    }
    .padding(.vertical, 12)
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 16) {
      Image(systemName: "list.number")
        .font(.system(size: 48, weight: .ultraLight))
        .foregroundStyle(.secondary)
      Text("No steps added yet")
        .font(.title3)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Ingredient Drawer

  private var ingredientDrawer: some View {
    VStack(spacing: 0) {
      // Drag handle + header — always visible, tap to toggle
      VStack(spacing: 0) {
        RoundedRectangle(cornerRadius: 2.5)
          .fill(Color.secondary.opacity(0.3))
          .frame(width: 36, height: 5)
          .padding(.top, 10)
          .padding(.bottom, 12)

        HStack {
          Text("Ingredients")
            .font(.headline)
          Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
      }
      .contentShape(Rectangle())
      .onTapGesture {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
          isDrawerExpanded.toggle()
        }
      }
      .gesture(
        DragGesture(minimumDistance: 16)
          .onEnded { value in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
              isDrawerExpanded = value.translation.height < 0
            }
          }
      )

      // Expandable ingredient list
      if isDrawerExpanded {
        Divider()
          .padding(.horizontal, 20)

        ScrollView {
          VStack(alignment: .leading, spacing: 8) {
            ForEach(unsectionedIngredients) { ingredient in
              IngredientRow(ingredient: ingredient, multiplier: servingMultiplier)
                .selectable(selected: checkableBinding(for: ingredient))
                .contentShape(Rectangle())
                .onTapGesture { toggleCheck(for: ingredient) }
            }

            if !recipe.sections.isEmpty {
              IngredientSectionList(
                sections: recipe.sections,
                multiplier: servingMultiplier,
                selectableBinding: checkableBinding(for:),
                toggleSelection: toggleCheck(for:)
              )
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 48)
        }
        .frame(maxHeight: 380)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 24)
        .fill(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.07), radius: 24, x: 0, y: -6)
        .ignoresSafeArea(edges: .bottom)
    )
  }

  // MARK: - Ingredient Check Helpers

  private func checkableBinding(for ingredient: Ingredient) -> Binding<Bool> {
    Binding(
      get: { checkedIngredients.contains(ingredient) },
      set: { isChecked in
        if isChecked { checkedIngredients.insert(ingredient) }
        else { checkedIngredients.remove(ingredient) }
      }
    )
  }

  private func toggleCheck(for ingredient: Ingredient) {
    if checkedIngredients.contains(ingredient) {
      checkedIngredients.remove(ingredient)
    } else {
      checkedIngredients.insert(ingredient)
    }
  }

  // MARK: - Complete Recipe

  private func completeRecipe() {
    var allIngredients = recipe.ingredients.filter { $0.section == nil }
    for section in recipe.sections { allIngredients += section.ingredients }

    let descriptor = FetchDescriptor<Ingredient>()
    guard let allStored = try? context.fetch(descriptor) else { return }
    let pantryItems = allStored.filter { $0.location == .pantry }

    var used = 0
    var skipped = 0

    for recipeIngredient in allIngredients {
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
          let remaining = pantryQty - needed
          if remaining <= 0 { context.delete(pantryItem) }
          else { pantryItem.quantity = remaining }
        } else if pantryItem.quantity == nil {
          context.delete(pantryItem)
        }
      }
      used += 1
    }

    do {
      try context.save()
      usedFromPantryCount = used
      skippedFromPantryCount = skipped
      showCompleteResult = true
    } catch {
      print("Error completing recipe: \(error)")
    }
  }
}

// MARK: - Step Card

private struct StepCardView: View {
  let step: Step
  let stepNumber: Int
  let totalSteps: Int

  var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack(alignment: .leading, spacing: 28) {
        // Step number bubble
        ZStack {
          Circle()
            .fill(Color.app.primary)
            .frame(width: 52, height: 52)
          Text("\(stepNumber)")
            .font(.title2.bold())
            .foregroundStyle(.white)
        }

        // Step text
        Text(step.value)
          .font(.title3)
          .lineSpacing(7)
          .foregroundStyle(Color.app.textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 32)
      .padding(.top, 36)
      .padding(.bottom, 24)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

#Preview {
  Previews.customRecipe(
    hasSections: false,
    hasTimings: false
  ) { recipe in
    CookModeView(recipe: recipe)
  }
}
