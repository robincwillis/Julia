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
    let match: RecipeMatch
    var viewModel: RecipeSuggestionsViewModel

    @State private var selectedMissing: Set<String> = []

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
                            .foregroundStyle(.secondary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.2)).frame(height: 8)
                            Capsule().fill(coverageColor).frame(width: geo.size.width * match.coveragePercent, height: 8)
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
                        Toggle(ingredient, isOn: Binding(
                            get: { selectedMissing.contains(ingredient) },
                            set: { isOn in
                                if isOn { selectedMissing.insert(ingredient) }
                                else { selectedMissing.remove(ingredient) }
                            }
                        ))
                        .toggleStyle(iOSCheckboxToggleStyle())
                    }
                } header: {
                    Text("Missing (\(match.missingIngredients.count))")
                } footer: {
                    if !selectedMissing.isEmpty {
                        Button("Add \(selectedMissing.count) to Grocery List") {
                            addSelectedToGrocery()
                        }
                        .font(.subheadline)
                        .tint(Color.app.primary)
                    }
                }
            }

            // Substitution suggestions
            Section {
                if viewModel.isFetchingSubstitutions {
                    HStack {
                        ProgressView()
                        Text("Generating suggestions...")
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                } else if let subs = substitutions {
                    ForEach(subs.suggestions, id: \.missingIngredient) { sub in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(sub.missingIngredient)
                                    .fontWeight(.medium)
                            }
                            Text("Use: " + sub.substitutes.joined(separator: " or "))
                                .font(.subheadline)
                                .foregroundStyle(Color.app.primary)
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
                } else if !match.missingIngredients.isEmpty {
                    Button {
                        Task { await viewModel.fetchSubstitutions(for: match) }
                    } label: {
                        Label("Suggest Substitutions", systemImage: "wand.and.stars")
                    }
                }
            } header: {
                Text("Substitutions")
            }

            // Link to recipe
            Section {
                NavigationLink("View Full Recipe") {
                    RecipeDetails(recipe: match.recipe)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(match.recipe.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private

    private var coverageColor: Color {
        switch match.coveragePercent {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

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
