//
//  RecipeEditRawTextSection.swift
//  Julia
//
//  Created by Robin Willis on 3/30/25.
//

import SwiftUI
import UIKit

struct RecipeEditRawTextSection: View {
  @Binding var rawText: String
  @Binding var focusedField: RecipeFocusedField
  @FocusState private var isRawTextFieldFocused: Bool
  
  var body: some View {
    Section("Raw Text") {      
      TextEditor(text: $rawText)
        .font(.system(size: 14, design: .monospaced))
        .padding(.vertical, 8)
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .foregroundColor(.secondary)
        .background(.white)
        .cornerRadius(12)
        .focused($isRawTextFieldFocused)
        .onSubmit {
          isRawTextFieldFocused = false
        }
        .onChange(of: isRawTextFieldFocused) { oldValue, newValue in
          print("RawText focus changed: \(oldValue) -> \(newValue), current focusedField: \(focusedField)")
          if newValue {
            focusedField = .rawText
            print("Set focusedField to .rawText")
          } else if focusedField == .rawText {
            focusedField = .none
            print("Reset focusedField to .none")
          }
        }
    }
  }
}

#Preview {
  struct RecipeEditRawTextSectionPreview: View {
    @State var rawText = "1 cup all-purpose flour\n2 tbsp sugar\n1 tsp baking powder\n1/2 tsp salt\n1 cup milk\n1 large egg\n2 tbsp melted butter"
    @State private var focusedField: RecipeFocusedField = .none
    
    var body: some View {
      Form {
        RecipeEditRawTextSection(
          rawText: $rawText,
          focusedField: $focusedField
        )
      }
    }
  }
  
  return RecipeEditRawTextSectionPreview()
}
