//
//  RecipeEditSummarySection.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftUI

struct RecipeEditSummarySection: View {
    @Binding var title: String
    @Binding var summary: String?
    @FocusState var isTextFieldFocused: Bool
  
    var body: some View {
      // Title and Summary
      Section {
        TextField("Recipe Title", text: $title)
          .font(.title)
          .focused($isTextFieldFocused)
          .submitLabel(.done)
          .padding(.vertical, 4)
        
        TextField("Recipe summary", text: Binding(
          get: { summary ?? "" },
          set: { summary = $0.isEmpty ? nil : $0 }
        ), axis: .vertical)
          .lineLimit(3...6)
          .focused($isTextFieldFocused)
          .submitLabel(.done)
      }
    }
}

// #Preview {
//    TODO Setup Preview
//    let container = DataController.previewContainer
//    let fetchDescriptor = FetchDescriptor<Recipe>()
//    
//    let previewRecipe: Recipe
//    RecipeEditSummarySection()
// }
