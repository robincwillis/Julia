//
//  RecipeTitleSection.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI


struct ServingsCard: View {
  let servings: Int
  
  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "person.2.fill")
        .font(.title2)
        .foregroundColor(.blue)
      
      VStack(alignment: .leading, spacing: 4) {
        Text("Servings")
          .font(.caption)
          .foregroundColor(.secondary)
        
        Text("\(servings)")
          .font(.headline)
          .foregroundColor(.primary)
      }
    }
    .frame(minWidth: 100)
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }
}

struct TimingsCard: View {
  let timings: [Timing]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "timer")
          .font(.title2)
          .foregroundColor(.blue)
        
        Text("Time")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(timings) { timing in
            HStack(spacing: 4) {
              Text(timing.type)
                .font(.caption)
                .foregroundColor(.primary)
                .fontWeight(.bold)
              
              Text(timing.display)
                .font(.caption)
                .foregroundColor(.primary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.white.opacity(0.5))
            .cornerRadius(6)
          }
        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }
}

struct RecipeSummarySection: View {
    let recipe: Recipe
    var body: some View {
      if let summary = recipe.summary {
        Text("Summary")
          .font(.headline)
          .foregroundColor(.gray)
        Text(summary)
          .font(.body)
      }
      
      HStack(spacing: 12) {
        // Servings card
        if let servings = recipe.servings {
          ServingsCard(servings: servings)
        }
        
        // Timings card
        if let timings = recipe.timings, !timings.isEmpty {
          TimingsCard(timings: timings)
        }
      }
    }
}


#Preview {
    struct PreviewWrapper: View {
        @State private var title = "Sample Recipe"
        @State private var summary: String? = "A delicious sample recipe"
        @FocusState private var focused: Bool
        
        var body: some View {
            RecipeSummarySection(
                recipe: Recipe(
                    title: "Sample Recipe",
                    summary: "A delicious sample recipe",
                    ingredients: [],
                    instructions: [],
                    rawText: ["Sample Recipe", "A delicious sample recipe"]
                )
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}
