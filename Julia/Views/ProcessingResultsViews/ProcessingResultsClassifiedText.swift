//
//  ProcessingResultsClassifiedText.swift
//  Julia
//
//  Created by Robin Willis on 3/16/25.
//

import SwiftUI

struct ProcessingResultsClassifiedText: View {
  @Binding var recipeData: RecipeData
  let saveProcessingResults: () -> Void

  @State private var hasUnsavedChanges = false
  @State private var filterType: RecipeLineType? = nil
  @State private var showUnclassifiedOnly: Bool = false
  @State private var unclassifiedFirst: Bool = true

  /// Whether the model actually accounted for this line.
  ///
  /// The classifier emits a binary signal, not a graded score: 1.0 for a line
  /// it categorised, and a low value for one it omitted, which `buildResult`
  /// then defaults to `.unknown`. So this reads as "was this classified",
  /// and the raw number is deliberately not shown — rendering 0.30 as a
  /// confidence implies precision that does not exist.
  private func wasClassified(_ confidence: Double) -> Bool {
    confidence >= RecipeProcessor.confidenceThreshold
  }
  
  var body: some View {
    VStack {
      HStack {
        Toggle("Unclassified Only", isOn: $showUnclassifiedOnly)
          .toggleStyle(.button)
          .background(Color.app.white)
          .cornerRadius(6)
          .font(.caption)
        
        Spacer()
        
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
        
        Button(unclassifiedFirst ? "Unclassified first" : "Document order") {
          withAnimation {
            unclassifiedFirst.toggle()
          }
        }
        .font(.caption)
      }
      .padding()
      
      Form {
        // Filter and sort the classified lines
        let filteredLines = recipeData.classifiedLines.enumerated().filter { index, item in
          let (_, type, confidence) = item
          let typeMatch = filterType == nil || type == filterType
          let classifiedMatch = !showUnclassifiedOnly || !wasClassified(confidence)
          return typeMatch && classifiedMatch
        }.sorted { a, b in
          guard unclassifiedFirst else {
            return a.offset < b.offset
          }
          // Surface the lines needing attention, keeping document order within
          // each group. Sorting by the raw value would be meaningless — there
          // are only two.
          let aNeedsAttention = !wasClassified(a.element.2)
          let bNeedsAttention = !wasClassified(b.element.2)
          if aNeedsAttention != bNeedsAttention { return aNeedsAttention }
          return a.offset < b.offset
        }
        
        if filteredLines.isEmpty {
          Text("No matching lines")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        } else {
          Section("Lines (\(filteredLines.count) of \(recipeData.classifiedLines.count))") {
            ForEach(filteredLines, id: \.offset) { index, lineData in
              let (text, type, confidence) = lineData
              VStack(alignment: .leading) {
                Text(text)
                  .font(.body)
                  .foregroundColor(wasClassified(confidence) ? Color.app.textPrimary : .secondary)
                
                HStack {
                  Label(type.rawValue.capitalized, systemImage: typeIcon(for: type))
                    .foregroundColor(typeColor(for: type))
                  
                  Spacer()
                  
                  if !wasClassified(confidence) {
                    Label("Not classified", systemImage: "exclamationmark.circle")
                      .font(.caption2)
                      .foregroundColor(.orange)
                  }
                }
                .font(.caption)
                
                if !wasClassified(confidence) {
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
      .scrollContentBackground(.hidden)
      .background(Color.app.backgroundSecondary)
    }
  }
  
  //  Helper Functions
  private func typeIcon(for type: RecipeLineType) -> String {
    switch type {
    case .title: return "textformat.characters"
    case .section_title: return "textformat.headings"
    case .ingredient: return "carrot"
    case .instruction: return "frying.pan"
    case .summary: return "text.quote"
    case .serving: return "fork.knife"
    case .time: return "stopwatch"
    case .source: return "link"
    case .note: return "exclamationmark.triangle"
    case .unknown: return "questionmark.circle"
    }
  }
  
  private func typeColor(for type: RecipeLineType) -> Color {
    switch type {
    case .title: return .blue
    case .section_title: return .cyan
    case .ingredient: return .green
    case .instruction: return .indigo
    case .summary: return .red
    case .serving: return .pink
    case .time: return .purple
    case .note: return .orange
    case .source: return .yellow
    case .unknown: return .gray
    }
  }
  
}

#Preview {
  struct PreviewWrapper: View {
    @State var mockRecipeData = RecipeData()
    let saveProcessingResults: () -> Void

    init() {
      self.saveProcessingResults = {
        // Empty implementation for preview
        print("Mock save processing results called")
      }
      // Set up mock recipe data
      var data = RecipeData()
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

