//
//  RecipeSuggestionDetailView.swift
//  Julia
//

import SwiftUI
import SwiftData

/// Detailed view for a single `RecipeMatch` — shows missing ingredients,
/// lets the user add them to grocery, and fetches FM substitution suggestions.
struct RecipeSuggestionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let match: RecipeMatch
    var viewModel: RecipeSuggestionsViewModel

    @State private var selectedMissing: Set<String> = []
    @State private var navigateToRecipe = false

    var substitutions: SubstitutionSuggestions? {
        viewModel.substitutionsByRecipeId[match.recipe.id]
    }

    var body: some View {
        List {
            // Coverage summary
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(match.coverageLabel)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "%.0f%%", match.coveragePercent * 100))
                            .font(.title2)
                            .foregroundStyle(Color.app.primary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(UIColor.tertiarySystemFill))
                                .frame(height: 8)
                            Capsule()
                                .fill(Color.app.primary)
                                .frame(width: geo.size.width * match.coveragePercent, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.vertical, 4)
            }

            // Missing ingredients
            if !match.missingIngredients.isEmpty {
                Section {
                    ForEach(match.missingIngredients, id: \.self) { ingredient in
                        Toggle(isOn: Binding(
                            get: { selectedMissing.contains(ingredient) },
                            set: { isOn in
                                if isOn { selectedMissing.insert(ingredient) }
                                else { selectedMissing.remove(ingredient) }
                            }
                        )) {
                            Text(ingredient)
                                .foregroundStyle(Color.app.textPrimary)
                        }
                        .toggleStyle(iOSCheckboxToggleStyle())
                    }
                    if !selectedMissing.isEmpty {
                        Button {
                            addSelectedToGrocery()
                        } label: {
                            Text("Add to Grocery List")
                                .foregroundStyle(Color.app.primary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Missing")
                }
            }

            // Substitutions — only shown when ingredients are missing
            if !match.missingIngredients.isEmpty {
                Section("Substitutions") {
                    if viewModel.isFetchingSubstitutions {
                        HStack(spacing: 12) {
                            Loader(isLoading: .constant(true))
                            Text("Generating suggestions...")
                                .foregroundStyle(Color.app.primary)
                        }
                        .listRowBackground(Color.app.white)
                    } else if let subs = substitutions {
                        ForEach(subs.suggestions, id: \.missingIngredient) { sub in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sub.missingIngredient.capitalized)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.app.textPrimary)
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(Color.app.primary)
                                        .font(.caption)
                                    Text(sub.substitutes.joined(separator: " or "))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.app.primary)
                                }
                                if !sub.note.isEmpty {
                                    Text(sub.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } else if let error = viewModel.substitutionError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        actionButton(
                            title: "Get Suggestions",
                            icon: "wand.and.stars",
                            color: Color.app.primary
                        ) {
                            Task { await viewModel.fetchSubstitutions(for: match) }
                        }
                        .listRowBackground(Color.app.white)
                    }
                }
            }

            // Ready to Cook — shown when all ingredients are available
            if match.missingIngredients.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        GlowingIcon(systemName: "checkmark.circle.fill", size: 36)
                        Text("Ready to Cook")
                            .font(.headline)
                            .foregroundStyle(Color.app.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }

            // View full recipe
            Section {
                actionButton(
                    title: "View Full Recipe",
                    icon: "arrow.right",
                    color: Color.app.secondary
                ) {
                    navigateToRecipe = true
                }
                .listRowBackground(Color.app.white)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.app.backgroundSheet)
        .navigationTitle(match.recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToRecipe) {
            RecipeDetails(recipe: match.recipe)
                .background(Color.app.backgroundPrimary)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.app.primary)
                }
                .circleToolbarButtonStyle()
                .buttonStyle(.plain)
            }
            .hidesSharedGlassBackground()
        }
    }

    // MARK: - Subviews

    private func actionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: icon)
            }
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private

    private func addSelectedToGrocery() {
        for name in selectedMissing {
            let ingredient = Ingredient(name: name, location: .grocery)
            context.insert(ingredient)
        }
        selectedMissing.removeAll()
    }
}

#Preview {
    let recipe = Recipe(title: "Pasta Carbonara")
    let match = RecipeMatch(
        recipe: recipe,
        coveredCount: 3,
        totalCount: 6,
        missingIngredients: ["pancetta", "pecorino romano", "black pepper"]
    )
    let vm = RecipeSuggestionsViewModel()
    NavigationStack {
        RecipeSuggestionDetailView(match: match, viewModel: vm)
    }
    .modelContainer(DataController.previewContainer)
}
