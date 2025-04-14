//
//  ProcessingResultsReconstructedText.swift
//  Julia
//
//  Created by Robin Willis on 3/16/25.
//

import SwiftUI

// Create a typealias for the result structure to avoid ambiguity
typealias ProcessingTextResult = TextReconstructorResult

struct ProcessingResultsReconstructedText: View {
  let reconstructedText: ProcessingTextResult
  
  var body: some View {
    Form {
      // Title Section
      if !reconstructedText.title.isEmpty {
        Section("Title") {
          Text(reconstructedText.title)
        }
      }
      
      // Reconstructed Lines Section
      Section("Reconstructed Text (\(reconstructedText.reconstructedLines.count) lines)") {
        ForEach(Array(reconstructedText.reconstructedLines.enumerated()), id: \.offset) { index, line in
          VStack(alignment: .leading) {
            HStack(alignment: .top) {
              Text("\(index + 1).")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
                .padding(.top, 2)
              Text(line)
                .font(.system(size: 14, design: .monospaced))
                .textSelection(.enabled)
            }
          }
          
        }
        
      }
      
      // Artifacts Section
      if !reconstructedText.artifacts.isEmpty {
        Section("Artifacts (\(reconstructedText.artifacts.count) lines)") {
          ForEach(Array(reconstructedText.artifacts.enumerated()), id: \.offset) { index, line in
            VStack(alignment: .leading) {
              HStack(alignment: .top) {
                Text("\(index + 1).")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .frame(width: 30, alignment: .trailing)
                  .padding(.top, 2)
                
                Text(line)
                  .font(.system(size: 14, design: .monospaced))
                  .textSelection(.enabled)
              }
            }
          }
        }
      }
    }
  }
}

#Preview {
  let reconstructedText: ProcessingTextResult = {
    let title = "Classic Chocolate Chip Cookies"
    let reconstructedLines = [
      "2 1/4 cups all-purpose flour",
      "1 teaspoon baking soda",
      "1 teaspoon salt",
      "1 cup (2 sticks) butter, softened",
      "3/4 cup granulated sugar",
      "3/4 cup packed brown sugar",
      "1 teaspoon vanilla extract",
      "2 large eggs",
      "2 cups semi-sweet chocolate chips",
      "Preheat oven to 375°F.",
      "Combine flour, baking soda and salt in small bowl.",
      "Beat butter, granulated sugar, brown sugar and vanilla extract in large mixer bowl until creamy.",
      "Add eggs, one at a time, beating well after each addition.",
      "Gradually beat in flour mixture.",
      "Stir in chocolate chips.",
      "Drop by rounded tablespoon onto ungreased baking sheets.",
      "Bake for 9 to 11 minutes or until golden brown.",
      "Cool on baking sheets for 2 minutes; remove to wire racks to cool completely."
    ]
    let artifacts = [
      "375°F",
      "9-11",
      "2 min"
    ]
    
    return TextReconstructorResult(
      title: title,
      reconstructedLines: reconstructedLines,
      artifacts: artifacts
    )
  }()
  
  return ProcessingResultsReconstructedText(reconstructedText: reconstructedText)
}
