//
//  RecipeSuggestionsView.swift
//  Julia
//

import SwiftUI
import SwiftData

/// "What can I cook?" — shows saved recipes ranked by pantry coverage.
struct RecipeSuggestionsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var recipes: [Recipe]
    @Query private var ingredients: [Ingredient]

    @State private var viewModel = RecipeSuggestionsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Checking pantry...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "book",
                        description: Text("Add some recipes first to see what you can cook.")
                    )
                } else if viewModel.matches.isEmpty {
                    ContentUnavailableView(
                        "No Matches",
                        systemImage: "wand.and.stars",
                        description: Text("Add pantry ingredients to see recipe matches.")
                    )
                } else {
                    matchList
                }
            }
            .navigationTitle("What can I cook?")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                filterBar
            }
        }
        .onAppear {
            viewModel.computeMatches(recipes: recipes, ingredients: ingredients)
        }
        .onChange(of: viewModel.includePantry) { _, _ in
            viewModel.computeMatches(recipes: recipes, ingredients: ingredients)
        }
        .onChange(of: viewModel.includeGrocery) { _, _ in
            viewModel.computeMatches(recipes: recipes, ingredients: ingredients)
        }
    }

    // MARK: - Subviews

    private var matchList: some View {
        List(viewModel.matches) { match in
            NavigationLink {
                RecipeSuggestionDetailView(match: match, viewModel: viewModel)
            } label: {
                RecipeMatchRow(match: match)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var filterBar: some View {
        HStack(spacing: 16) {
            Toggle("Pantry", isOn: $viewModel.includePantry)
                .toggleStyle(.button)
                .tint(Color.app.primary)
            Toggle("Grocery list", isOn: $viewModel.includeGrocery)
                .toggleStyle(.button)
                .tint(Color.app.primary)
            Spacer()
            Text("\(viewModel.matches.count) recipe\(viewModel.matches.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

// MARK: - Row

private struct RecipeMatchRow: View {
    let match: RecipeMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(match.recipe.title)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 8) {
                // Coverage progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.2))
                            .frame(height: 6)
                        Capsule().fill(coverageColor)
                            .frame(width: geo.size.width * match.coveragePercent, height: 6)
                    }
                }
                .frame(height: 6)

                Text(match.coverageLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
        .padding(.vertical, 4)
    }

    private var coverageColor: Color {
        switch match.coveragePercent {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

#Preview {
    RecipeSuggestionsView()
        .modelContainer(DataController.previewContainer)
}
