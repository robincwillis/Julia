//
//  RecipeTitleSection.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI
import SwiftData

struct ServingsCard: View {
  let servings: Int
  
  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: "person.2.fill")
        .font(.title2)
        .foregroundColor(.blue)
      Text("\(servings)")
        .font(.headline)
        .foregroundColor(.primary)
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }
}

struct TimingsCard: View {
  let timings: [Timing]
  
  var body: some View {
    VStack(alignment: .leading) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(timings) { timing in
            VStack {
              Image(systemName: "stopwatch")
                .font(.title2)
                .foregroundColor(.blue)
              
              HStack(spacing: 4) {
                Text(timing.type)
                  .font(.title2)
                  .foregroundColor(.primary)
                  .fontWeight(.bold)
                
                Text(timing.displayShort)
                  .font(.title2)
                  .foregroundColor(.primary)
              }
              .padding(.horizontal, 8)
            }
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
      if !recipe.timings.isEmpty {
        TimingsCard(timings: recipe.timings)
      }
    }
  }
}

#Preview("RecipeSummarySection") {
  Previews.customRecipe(
    hasTimings: true
  ) { recipe in
        RecipeSummarySection(recipe: recipe)
          .padding()
  }
}
