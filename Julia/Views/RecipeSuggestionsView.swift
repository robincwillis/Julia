//
//  RecipeSuggestionsView.swift
//  Julia
//

import SwiftUI
import SwiftData

/// "What can I cook?" — shows saved recipes ranked by pantry/grocery coverage.
struct RecipeSuggestionsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var recipes: [Recipe]
    @Query private var ingredients: [Ingredient]

    @State private var viewModel = RecipeSuggestionsViewModel()
    @State private var selectedFilter: FilterOption = .pantry

    private enum FilterOption: String, CaseIterable {
        case pantry = "Pantry"
        case grocery = "Groceries"
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Checking pantry...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if recipes.isEmpty {
                    SuggestionsEmptyState(label: "No Recipes Yet")
                } else if viewModel.matches.isEmpty {
                    SuggestionsEmptyState(label: "No Matches")
                } else {
                    matchList
                }
            }
            .background(Color.app.backgroundSecondary.ignoresSafeArea())
            .navigationTitle("What can I cook?")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.app.primary)
                    }
                    .circleToolbarButtonStyle()
                    .buttonStyle(.plain)
                }
                .hidesSharedGlassBackground()
            }
            .safeAreaInset(edge: .bottom) {
                if !recipes.isEmpty {
                    filterBar
                }
            }
        }
        .onAppear {
            // Sync ViewModel to initial filter selection
            viewModel.includePantry = true
            viewModel.includeGrocery = false
            viewModel.computeMatches(recipes: recipes, ingredients: ingredients)
            // Chevron color
            UITableViewCell.appearance().tintColor = UIColor(
                red: 197/255, green: 197/255, blue: 199/255, alpha: 1
            )
        }
        .onChange(of: viewModel.includePantry) { _, _ in
            viewModel.computeMatches(recipes: recipes, ingredients: ingredients)
        }
        .onChange(of: viewModel.includeGrocery) { _, _ in
            viewModel.computeMatches(recipes: recipes, ingredients: ingredients)
        }
        .onChange(of: selectedFilter) { _, filter in
            viewModel.includePantry = (filter == .pantry)
            viewModel.includeGrocery = (filter == .grocery)
        }
        .presentationBackground(Color.app.backgroundSecondary)
    }

    // MARK: - Subviews

    private var matchList: some View {
        List(viewModel.matches) { match in
            NavigationLink {
                RecipeSuggestionDetailView(match: match, viewModel: viewModel)
            } label: {
                RecipeMatchRow(match: match)
            }
            .listRowBackground(Color.clear)
            .listRowSeparatorTint(Color(UIColor.separator))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var filterBar: some View {
        segmentedControl
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.app.backgroundSecondary)
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(FilterOption.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 14, weight: selectedFilter == option ? .semibold : .regular))
                        .foregroundStyle(
                            selectedFilter == option ? Color.app.primary : Color(UIColor.secondaryLabel)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            selectedFilter == option ? Color.app.white : Color.clear,
                            in: Capsule()
                        )
                        .padding(3)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: selectedFilter)
            }
        }
        .background(Color(UIColor.systemGray5), in: Capsule())
    }
}

// MARK: - Empty State

private struct SuggestionsEmptyState: View {
    let label: String

    var body: some View {
        VStack(spacing: 16) {
            GlowingIcon(
                systemName: "book.fill",
                size: 18,
                primaryColor: Color.app.primary,
                glowColor: .orange
            )
            Text(label)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(Color.app.labelPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row

private struct RecipeMatchRow: View {
    let match: RecipeMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(match.recipe.title)
                .font(.headline)
                .fontWeight(isReadyToCook ? .semibold : .regular)
                .lineLimit(1)
                .foregroundStyle(titleColor)
                .opacity(titleOpacity)

            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(UIColor.tertiarySystemFill))
                            .frame(height: 6)
                        Capsule()
                            .fill(coverageColor)
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
        Color.app.primary
    }

    private var isReadyToCook: Bool {
        match.coveragePercent >= 1.0
    }

    private var titleColor: Color {
        isReadyToCook ? Color.app.textPrimary : Color.app.textSecondary
    }

    private var titleOpacity: Double {
        match.coveragePercent >= 0.5 ? 1.0 : 0.5
    }
}

#Preview {
    RecipeSuggestionsView()
        .modelContainer(DataController.previewContainer)
}
