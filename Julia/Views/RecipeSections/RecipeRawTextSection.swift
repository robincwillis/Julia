//
//  RecipeRawTextSection.swift
//  Julia
//
//  Created by Claude on 3/2/25.
//

import SwiftUI

struct RecipeRawTextSection: View {
  let recipe: Recipe
  
  var rawTextString: String {
    recipe.rawText?.joined(separator: "\n") ?? ""
  }
  
  var body: some View {
    GeometryReader { geometry in
      ZStack (alignment: .bottom) {
        ScrollView {
          Text(rawTextString)
            .font(.system(size: 12, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 16)
          
            .foregroundColor(.secondary)
        }
        //.frame(maxWidth: .infinity)
        
        VStack {
          Spacer()
          Button("Copy") {
            UIPasteboard.general.string = rawTextString
          }
          .foregroundColor(.blue)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color(red: 0.85, green: 0.92, blue: 1.0))
          .cornerRadius(12)
        }
        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 16)

      }
    }
  }
}

#Preview("Recipe Raw Text Section") {
  PreviewContainer {
    RecipeRawTextPreview()
  }
}

struct RecipeRawTextPreview: View {
  @State private var showRawTextSheet = true
  @State private var recipe: Recipe?
  

  var body: some View {
    ZStack {
      Button("Show Sheet") {
        showRawTextSheet = true
      }
      .buttonStyle(.borderedProminent)
    }
    .task {
      // Safely call the MainActor-isolated method
      if recipe == nil {
        self.recipe = await MainActor.run {
          MockData.createSampleRecipe()
        }
      }
    }
    .sheet(isPresented: $showRawTextSheet) {
      if let recipe = recipe {
        ScrollView {
          RecipeRawTextSection(recipe: recipe)
        }
        .presentationDetents([.medium, .large])
        .background(.background.secondary)
        .presentationDragIndicator(.hidden)
      } else {
        ProgressView("Loading recipe...")
      }
    }
  }
}

