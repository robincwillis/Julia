//
//  EmptyRecipesView.swift
//  Julia
//
//  Created by Robin Willis on 4/20/25.
//

import SwiftUI
import SwiftData

struct EmptyRecipesView: View {
  let loadSampleData: () -> Void
  @State private var isLoading = false
  @State private var glowAmount: CGFloat = 0.5

  var body: some View {
    VStack(spacing: 24) {
      GlowingIcon(
        systemName: "book.fill",
        size: 18,
        primaryColor: Color.app.primary,
        glowColor: .orange
      )
      
      Text("No Recipes Added")
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(Color.app.textLabel)
      
      Button(action: {
        isLoading = true
        loadSampleData()
      }) {
        HStack {
          Text("Load a few Gems")
          if isLoading {
            Loader(isLoading: $isLoading)
              .padding(.leading, 4)
          }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.white)
        .foregroundColor(Color.app.primary)
        .cornerRadius(12)
      }
      .disabled(isLoading)
    }
    .padding(.bottom, 100) // Make room for the tab bar
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview {
  EmptyRecipesView(loadSampleData: { /* Noop */ })
    .modelContainer(DataController.previewContainer)
}

