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
  
  
    private var summaryTextBinding: Binding<String> {
      Binding<String>(
        get: { self.summary ?? "" },
        set: { summary = $0.isEmpty ? nil : $0  }
      )
    }
  
    private var servingsTextBinding: Binding<Int> {
      Binding<Int>(
        get: { self.servings ?? 0 },
        set: { self.servings = $0 < 1 ? nil : $0 }
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
          
          HStack(spacing: 12) {
            Button(action: {
              if (servings ?? 1) > 1 {
                servings = (servings ?? 1) - 1
              }
            }) {
              Image(systemName: "minus.circle.fill")
                .foregroundColor(servings ?? 0 > 1 ? .blue : .gray)
            }
            
            TextField("", value: servingsTextBinding, formatter: NumberFormatter())
              .keyboardType(.numberPad)
              .multilineTextAlignment(.center)
              .frame(width: 40)
              .padding(.vertical, 4)
              .padding(.horizontal, 8)
              .background(Color(.systemGray6))
              .cornerRadius(8)
            
            Button(action: {
              servings = (servings ?? 0) + 1
            }) {
              Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
            }
          }
        }
        .padding(.vertical, 8)
        // TODO Add Timings Here
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
