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
  
  @State private var showSuccessAlert = false
  @State private var showErrorAlert = false
  @State private var errorMessage = ""
  @State private var loadedCount = 0
  
  var body: some View {
    NavigationStack {
      VStack {
        if recipes.isEmpty {
          EmptyRecipesView {
            loadSampleData()
          }
        } else {
          RecipeList(recipes: recipes)
        }
      }
      .background(Color.app.backgroundPrimary)
      .navigationTitle("Recipes")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        Button(action: {
          showAddSheet.toggle()
        }) {
          Image(systemName: "plus")
            .foregroundColor(Color.app.primary)
            .frame(width: 40, height: 40)
            .background(Color.white)
            .clipShape(Circle())
        }
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



