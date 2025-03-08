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
          .padding(.vertical, 2)
        
        TextField("Recipe summary", text: Binding(
          get: { summary ?? "" },
          set: { summary = $0.isEmpty ? nil : $0 }
        ), axis: .vertical)
          .lineLimit(3...6)
          .focused($isTextFieldFocused)
          .submitLabel(.done)
          .onSubmit {
            isTextFieldFocused = false
          }
          .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
              Spacer()
              Button("Done") {
                isTextFieldFocused = false
              }
            }
          }
      }
    }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var title = "Classic Chocolate Cake"
    @State private var summary: String? = "A rich, moist chocolate cake perfect for any occasion. This recipe has been in my family for generations."
    @FocusState private var focused: Bool
    
    var body: some View {
      NavigationStack {
        Form {
          RecipeEditSummarySection(
            title: $title,
            summary: $summary,
            isTextFieldFocused: _focused
          )
        }
      }
    }
  }
  
  return PreviewWrapper()
}
