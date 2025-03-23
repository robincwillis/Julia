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
  @Binding var servings: Int?
  @FocusState var isTextFieldFocused: Bool
  @FocusState var isSummaryFieldFocused: Bool
    
  @State private var servingsText: String = ""
  
  private var summaryTextBinding: Binding<String> {
    Binding<String>(
      get: { self.summary ?? "" },
      set: { summary = $0.isEmpty ? nil : $0  }
    )
  }
  
  private var servingsTextBinding: Binding<String> {
    Binding<String>(
      get: { self.servingsText },
      set: { newValue in
        if newValue.isEmpty {
          self.servings = nil
        } else {
          self.servings = Int(newValue)
        }
        if newValue == "0" {
          self.servingsText = ""
        } else {
          self.servingsText = newValue
        }
      }
    )
  }
  
  
  var body: some View {
    // Title and Summary
    Section {
      // Wrap if long
      TextField("Recipe Title", text: $title)
        .font(.title)
        .focused($isTextFieldFocused)
        .submitLabel(.done)
        .padding(.vertical, 2)
      
      TextField("Recipe summary", text: summaryTextBinding, axis: .vertical)
        .lineLimit(3...6)
        .focused($isSummaryFieldFocused)
        .onSubmit {
          isSummaryFieldFocused = false
        }
        .toolbar {
          ToolbarItemGroup(placement: .keyboard) {
            if isSummaryFieldFocused {
              Spacer()
              Button("Done") {
                isSummaryFieldFocused = false
              }
            }
          }
        }
    }
    Section {
      HStack {
        Text("Servings")
          .font(.body)
          .foregroundColor(.primary)
        
        Spacer()
        TextField("Optional", text: servingsTextBinding)
          .keyboardType(.numberPad)
          .multilineTextAlignment(.trailing)
          .padding(.vertical, 8)
          .padding(.horizontal, 4)
          //.background(Color(.systemGray6))
          .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
              Button("Clear") {
                servings = nil
              }
              Spacer()
              Button("Done") {
                hideKeyboard()
              }
            }
          }
          .onAppear {
            if let servings = servings, servings > 0 {
              servingsText = String(servings)
            }
          }
          .onChange(of: servings) {
            if let servings = servings, servings > 0 {
              servingsText = String(servings)
            } else {
              servingsText = ""
            }
          }
        
        
      }
      //.padding(.vertical, 8)
      // TODO  Combine with Timings
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var servings: Int? = 4
    @State private var title = "Classic Chocolate Cake"
    @State private var summary: String? = "A rich, moist chocolate cake perfect for any occasion. This recipe has been in my family for generations."
    @FocusState private var focused: Bool
    
    var body: some View {
      NavigationStack {
        Form {
          RecipeEditSummarySection(
            title: $title,
            summary: $summary,
            servings: $servings,
            isTextFieldFocused: _focused
          )
        }
      }
    }
  }
  
  return PreviewWrapper()
}
