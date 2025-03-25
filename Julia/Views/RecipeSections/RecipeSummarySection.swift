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
    .frame(minWidth: 80, minHeight: 80)

  }
}

struct TimingsCard: View {
  let timings: [Timing]
  let allowExpand: Bool
  
  var body: some View {
    VStack(alignment: .leading) {
      // If only one timing, use a centered HStack without ScrollView
      if timings.count == 1, let timing = timings.first {
        VStack(spacing: 6) {
          Image(systemName: "stopwatch.fill")
            .font(.title2)
            .foregroundColor(.blue)
          
          HStack(spacing: 4) {
            Text(timing.displayShort)
              .font(.headline)
              .foregroundColor(.primary)
            
            Text(timing.type)
              .font(.headline)
              .foregroundColor(.secondary)
          }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center) // Center when there's only one
      } else {
        // Multiple timings - use ScrollView with leading alignment
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 24) {
            ForEach(timings) { timing in
              HStack(alignment: .firstTextBaseline) {
                Image(systemName: "stopwatch")
                  .font(.title2)
                  .foregroundColor(.blue)
                  .alignmentGuide(.firstTextBaseline) { d in
                    d[.bottom] - 8 // Fine-tuned alignment
                  }
                
                VStack(alignment: .leading, spacing: 4) {
                  Text(timing.displayShort)
                    .font(.headline)
                    .foregroundColor(.primary)
                  
                  Text(timing.type)
                    .font(.headline)
                    .foregroundColor(.secondary)
                }
              }
            }
          }
          .padding()
        }
      }
    }
    .frame(minHeight: 80)
    .frame(maxWidth: allowExpand ? .infinity : nil, alignment: .leading)
  }
}

struct RecipeSummarySection: View {
  let recipe: Recipe
  var body: some View {
    if let summary = recipe.summary {
      Text(summary)
        .font(.body)
    }
    
    // Dynamic cards layout
    GeometryReader { geometry in
      let hasServings = recipe.servings != nil
      let hasTimings = !recipe.timings.isEmpty
      let singleTiming = recipe.timings.count == 1
      
      HStack (spacing: 12) { //
        // Servings card - grows to fill half space if we only have one timing item
        if hasServings {
          ServingsCard(servings: recipe.servings!)
            .frame(
              width: hasTimings && singleTiming ?
              geometry.size.width * 0.5 : nil
            )
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        
        // Timings card - expands to fill available width
        if hasTimings {
          TimingsCard(
            timings: recipe.timings,
            allowExpand: !hasServings || !singleTiming
          )
          .frame(
            width: hasServings && singleTiming ?
            geometry.size.width * 0.5 : nil
          )
          .background(Color(.systemGray6))
          .cornerRadius(12)
        }
      }
      .frame(maxWidth: geometry.size.width)
    }
    .frame(height: 80)
  }
}

#Preview("RecipeSummarySection") {
  Previews.customRecipe(
    hasTimings: true,
    hasServings: true,
    timingsCount: 3
  ) { recipe in
    ScrollView {
      VStack (alignment: .leading, spacing: 24) {
        RecipeSummarySection(recipe: recipe)
      }
      .padding()
    }
  }
}
