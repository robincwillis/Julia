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

  @State private var isSearchPresented = false

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
    Group {
      if recipes.isEmpty {
        recipesNavigationStack
      } else {
        recipesNavigationStack
          .searchable(
            text: $searchText,
            isPresented: $isSearchPresented,
            prompt: Text("Search recipes").foregroundStyle(Color.app.textPlaceholder)
          )
      }
    }
    .tint(Color.app.primary)
  }

  private var recipesNavigationStack: some View {
    NavigationStack {
      recipesContent
        .safeAreaInset(edge: .top, spacing: 0) {
          if !recipes.isEmpty {
            if isSearchPresented {
              Color.clear.frame(height: 12)
            } else if !allTags.isEmpty {
              tagFilterBar
                .transition(.move(edge: .top).combined(with: .opacity))
            }
          }
        }
        .animation(.easeInOut(duration: 0.25), value: isSearchPresented)
        .navigationDestination(for: Recipe.self) { recipe in
          RecipeDetails(recipe: recipe)
        }
        .background(Color.app.backgroundPrimary)
        .navigationTitle("Recipes")
        .navigationBarTitleDisplayMode(recipes.isEmpty ? .large : .inline)
        .toolbar { recipesToolbar }
        .sheet(isPresented: $showSuggestions) {
          RecipeSuggestionsView()
        }
        .sheet(isPresented: $showAddSheet) {
          AddRecipe()
            .interactiveDismissDisabled()
            .presentationDetents([.height(240), .large])
            .presentationBackground(Color.app.backgroundSecondary)
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
        .onAppear {
          let color = UIColor(Color.app.textPlaceholder)

          // Search icon
          let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
          let icon = UIImage(systemName: "magnifyingglass", withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
          UISearchBar.appearance().setImage(icon, for: .search, state: .normal)

          // Explicit fill so the field doesn't fall back to the system's glass
          // material — visible enough in light mode to pass, but reads as no
          // background at all in dark mode. White/black to match the
          // toolbar buttons' circleToolbarButtonStyle default.
          UISearchTextField.appearance().backgroundColor = UIColor(Color.app.white)

          // Placeholder text color (SwiftUI prompt foregroundStyle doesn't reach UIKit)
          UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
            .attributedPlaceholder = NSAttributedString(
              string: "Search recipes",
              attributes: [.foregroundColor: color]
            )

          // Hide inner clear button — replace its image with empty (clearButtonMode
          // via appearance proxy doesn't reach UISearchTextField's private subclass)
          UISearchBar.appearance().setImage(UIImage(), for: .clear, state: .normal)
          UISearchBar.appearance().setImage(UIImage(), for: .clear, state: .highlighted)
        }
    }
  }

  @ViewBuilder
  private var recipesContent: some View {
    if recipes.isEmpty {
      EmptyRecipesView(loadSampleData: loadSampleData)
    } else if filteredRecipes.isEmpty {
      noResultsView
    } else {
      RecipeList(recipes: filteredRecipes)
    }
  }

  @ToolbarContentBuilder
  private var recipesToolbar: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      if !recipes.isEmpty {
        Button {
          showSuggestions = true
        } label: {
          Image(systemName: "fork.knife")
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Color.app.primary)
            .opacity(isSearchPresented ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: isSearchPresented)
        }
        .circleToolbarButtonStyle()
        .buttonStyle(.plain)
      }
    }
    .hidesSharedGlassBackground()
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        showAddSheet.toggle()
      } label: {
        Image(systemName: "plus")
          .font(.system(size: 17, weight: .regular))
          .foregroundStyle(Color.app.primary)
          .opacity(isSearchPresented ? 0 : 1)
          .animation(.easeInOut(duration: 0.2), value: isSearchPresented)
      }
      .circleToolbarButtonStyle()
      .buttonStyle(.plain)
    }
    .hidesSharedGlassBackground()
  }

  private var noResultsView: some View {
    VStack(spacing: 24) {
      GlowingIcon(
        systemName: "magnifyingglass",
        size: 18,
        primaryColor: Color.app.primary,
        glowColor: .orange
      )
      Text("No recipes found")
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(Color.app.labelPrimary)
      if selectedTag != nil || !searchText.isEmpty {
        Button {
          searchText = ""
          selectedTag = nil
        } label: {
          Text("Clear filters")
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.app.white)
            .foregroundColor(Color.app.primary)
            .cornerRadius(12)
        }
      }
    }
    .padding(.bottom, 100)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
              .padding(.vertical, 8)
              .padding(.horizontal, 12)
              .background(selectedTag == tag ? Color.app.primary : Color.app.primary.opacity(0.1))
              .clipShape(Capsule())
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 16)
      //.padding(.top, 4)
      .padding(.bottom, 12)
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
