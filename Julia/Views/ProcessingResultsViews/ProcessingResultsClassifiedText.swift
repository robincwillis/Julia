//
//  ProcessingResultsClassifiedText.swift
//  Julia
//
//  Created by Robin Willis on 3/16/25.
//

import SwiftUI

struct ProcessingResultsClassifiedText: View {
  @Binding var recipeData: RecipeProcessingView.RecipeData
  let saveProcessingResults: () -> Void

  @State private var hasUnsavedChanges = false
  @State private var filterType: RecipeLineType? = nil
  @State private var showSkippedOnly: Bool = false
  @State private var sortByConfidence: Bool = true
  
  var body: some View {
    VStack {
      HStack {
        Menu {
          Button("All Types") { filterType = nil }
          Divider()
          ForEach(RecipeLineType.allCases, id: \.self) { type in
            Button(type.rawValue.capitalized) { filterType = type }
          }
        } label: {
          Label(
            filterType == nil ? "Filter: All" : "Filter: \(filterType!.rawValue.capitalized)",
            systemImage: "line.3.horizontal.decrease.circle"
          )
        }
        .font(.caption)
        
        Toggle("Skipped Only", isOn: $showSkippedOnly)
          .toggleStyle(.button)
          .font(.caption)
        
        Spacer()
        
        Button(sortByConfidence ? "Sort: Confidence" : "Sort: Order") {
          withAnimation {
            sortByConfidence.toggle()
          }
        }
        .font(.caption)
      }
      .padding(.horizontal)
      
      List {
        // Filter and sort the classified lines
        let filteredLines = recipeData.classifiedLines.enumerated().filter { index, item in
          let (_, type, confidence) = item
          let typeMatch = filterType == nil || type == filterType
          let confidenceMatch = !showSkippedOnly || confidence < RecipeProcessingView.confidenceThreshold
          return typeMatch && confidenceMatch
        }.sorted { a, b in
          if sortByConfidence {
            return a.element.2 > b.element.2 // Sort by confidence descending
          } else {
            return a.offset < b.offset // Sort by original order
          }
        }
        
        if filteredLines.isEmpty {
          Text("No matching lines")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        } else {
          Section("Classified Lines (\(filteredLines.count) of \(recipeData.classifiedLines.count))") {
            ForEach(filteredLines, id: \.offset) { index, lineData in
              let (text, type, confidence) = lineData
              VStack(alignment: .leading) {
                Text(text)
                  .font(.body)
                  .foregroundColor(confidence >= RecipeProcessingView.confidenceThreshold ? .primary : .secondary)
                
                HStack {
                  Label(type.rawValue.capitalized, systemImage: typeIcon(for: type))
                    .foregroundColor(typeColor(for: type))
                  
                  Spacer()
                  
                  Text("Confidence: \(String(format: "%.2f", confidence))")
                    .font(.caption2)
                    .foregroundColor(confidence >= RecipeProcessingView.confidenceThreshold ? .green : .red)
                }
                .font(.caption)
                
                if confidence < RecipeProcessingView.confidenceThreshold {
                  HStack {
                    Button("Add as Ingredient") {
                      recipeData.ingredients.append(text)
                      hasUnsavedChanges = true
                      saveProcessingResults()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    
                    Button("Add as Instruction") {
                      recipeData.instructions.append(text)
                      hasUnsavedChanges = true
                      saveProcessingResults()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                  }
                  .padding(.top, 2)
                }
              }
              .padding(.vertical, 4)
            }
          }
        }
      }
    }
  }
  
  //  Helper Functions
  private func typeIcon(for type: RecipeLineType) -> String {
    switch type {
    case .title: return "text.badge.star"
    case .ingredient: return "list.bullet"
    case .instruction: return "1.square"
    case .summary: return "text.quote"
    case .serving: return "fork.knife"
    case .time: return "stopwatch"
    case .unknown: return "questionmark.circle"
    }
  }
  
  private func typeColor(for type: RecipeLineType) -> Color {
    switch type {
    case .title: return .blue
    case .ingredient: return .green
    case .instruction: return .orange
    case .summary: return .red
    case .serving: return .pink
    case .time: return .purple
    case .unknown: return .gray
    }
  }
  
}

#Preview {
  struct PreviewWrapper: View {
    @State var mockRecipeData = RecipeProcessingView.RecipeData()
    let saveProcessingResults: () -> Void

    init() {
      self.saveProcessingResults = {
        // Empty implementation for preview
        print("Mock save processing results called")
      }
      // Set up mock recipe data
      var data = RecipeProcessingView.RecipeData()
      data.title = "Sample Recipe"
      data.ingredients = ["2 cups flour", "1 cup sugar", "3 eggs"]
      data.instructions = ["Mix dry ingredients", "Add eggs", "Bake at 350°F for 30 minutes"]
      // Use the typealias defined in RecipeProcessing.swift to avoid ambiguity
      data.reconstructedText = TextReconstructorResult(
        title: "Sample Recipe",
        reconstructedLines: ["2 cups flour", "1 cup sugar", "3 eggs", "Mix dry ingredients", "Add eggs"],
        artifacts: ["350°F"]
      )
      _mockRecipeData = State(initialValue: data)
    }
    
    
    var body: some View {
      ProcessingResultsClassifiedText(
        recipeData: $mockRecipeData,
        saveProcessingResults:saveProcessingResults
      )
    }
  }
  return PreviewWrapper()
}

