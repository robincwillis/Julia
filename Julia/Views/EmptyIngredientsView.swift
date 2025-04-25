//
//  EmptyIngredientsView.swift
//  Julia
//
//  Created by Robin Willis on 4/20/25.
//

import SwiftUI
import SwiftData

struct EmptyIngredientsView: View {
  let location: IngredientLocation
  let loadSampleData: () -> Void
  @State private var isLoading = false
  
  var body: some View {
    VStack(spacing: 24) {

      GlowingIcon(
        systemName: locationIcon,
        size: 18,
        primaryColor: Color.app.primary,
        glowColor: .orange
      )
      
      Text(locationLabel)
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(Color.app.textLabel)
      
      Button(action: {
        isLoading = true
        loadSampleData()
        // We don't set isLoading back to false because the view will be replaced by actual content
      }) {
        HStack {
          Text(locationCTA)
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
  
  private var locationIcon: String {
    switch location {
    case .pantry: return "cabinet.fill"
    case .grocery: return "basket.fill"
    case .recipe: return "book.fill"
    case .unknown: return "questionmark.circle.fill"
    }
  }
  
  private var locationLabel: String {
    switch location {
    case .pantry: return "Nothing in the pantry"
    case .grocery: return "Grocery basket empty"
    case .recipe: return "..."
    case .unknown: return "..."
    }
  }
  
  private var locationCTA: String {
    switch location {
    case .pantry: return "Add the basics"
    case .grocery: return "Start a shopping list"
    case .recipe: return "..."
    case .unknown: return "..."
    }
  }
  
  
}
