//
//  RecipesView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData

struct RecipesView: View {
  @Environment(\.modelContext) var context
  @Query private var recipes: [Recipe]
  @State var showAddSheet = false
  @State private var showSuggestions = false
  @State private var searchText = ""
  @State private var selectedTag: String? = nil

  @State private var showSuccessAlert = false
  @State private var showErrorAlert = false
  @State private var errorMessage = ""
  @State private var loadedCount = 0

  private var allTags: [String] {
    Array(Set(recipes.flatMap { $0.tags })).sorted()
  }

  private var filteredRecipes: [Recipe] {
    var result = recipes
    if !searchText.isEmpty {
      result = result.filter { recipe in
        recipe.title.localizedCaseInsensitiveContains(searchText) ||
        (recipe.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
        recipe.tags.contains { tag in tag.localizedCaseInsensitiveContains(searchText) }
      }
    }
    if let tag = selectedTag {
      result = result.filter { $0.tags.contains(tag) }
    }
    return result
  }

  var body: some View {
    NavigationStack {
      Group {
        if recipes.isEmpty {
          EmptyRecipesView {
            loadSampleData()
          }
        } else if filteredRecipes.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 44, weight: .ultraLight))
              .foregroundStyle(.secondary)
            Text("No recipes found")
              .font(.headline)
              .foregroundStyle(.secondary)
            if selectedTag != nil || !searchText.isEmpty {
              Button("Clear filters") {
                searchText = ""
                selectedTag = nil
              }
              .foregroundStyle(Color.app.primary)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          RecipeList(recipes: filteredRecipes)
        }
      }
      .safeAreaInset(edge: .top, spacing: 0) {
        if !recipes.isEmpty && !allTags.isEmpty {
          tagFilterBar
        }
      }
      .searchable(text: $searchText, prompt: "Search recipes")
      .navigationDestination(for: Recipe.self) { recipe in
        RecipeDetails(recipe: recipe)
      }
      .background(Color.app.backgroundPrimary)
      .navigationTitle("Recipes")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          if !recipes.isEmpty {
            Button {
              showSuggestions = true
            } label: {
              Image(systemName: "wand.and.stars")
                .foregroundStyle(Color.app.primary)
            }
            .frame(width: 30, height: 30)
            .background(.regularMaterial)
            .clipShape(Circle())
            .buttonStyle(.plain)
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showAddSheet.toggle()
          } label: {
            Image(systemName: "plus")
              .foregroundStyle(Color.app.primary)
          }
          .frame(width: 30, height: 30)
          .background(.regularMaterial)
          .clipShape(Circle())
          .buttonStyle(.plain)
        }
      }
      .sheet(isPresented: $showSuggestions) {
        RecipeSuggestionsView()
      }
      .sheet(isPresented: $showAddSheet) {
        AddRecipe()
          .interactiveDismissDisabled()
          .presentationDetents([.height(240), .large])
          .presentationDragIndicator(.hidden)
      }
      .alert("Recipes Added", isPresented: $showSuccessAlert) {
        Button("OK", role: .cancel) { }
      } message: {
        Text("Added \(loadedCount) recipes to your collection.")
      }
      .alert("Error", isPresented: $showErrorAlert) {
        Button("OK", role: .cancel) { }
      } message: {
        Text(errorMessage)
      }
    }
  }

  private var tagFilterBar: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(allTags, id: \.self) { tag in
          Button {
            selectedTag = selectedTag == tag ? nil : tag
          } label: {
            Text(tag)
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(selectedTag == tag ? .white : Color.app.primary)
              .padding(.vertical, 6)
              .padding(.horizontal, 12)
              .background(selectedTag == tag ? Color.app.primary : Color.app.primary.opacity(0.1))
              .clipShape(Capsule())
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
    }
    .background(.bar)
  }

  private func loadSampleData() {
    Task {
      do {
        let count = try await SampleDataLoader.loadSampleData(
          type: .recipes,
          context: context
        )
        await MainActor.run {
          loadedCount = count
          showSuccessAlert = true
        }
      } catch {
        errorMessage = "Error loading sample data: \(error.localizedDescription)"
        print(errorMessage)
        showErrorAlert = true
      }
    }
  }
}

#Preview {
  RecipesView()
    .modelContainer(DataController.previewContainer)
}
