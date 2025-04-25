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
  @Binding var focusedField: RecipeFocusedField

  
  @FocusState private var isTitleFieldFocused: Bool
  @FocusState private var isSummaryFieldFocused: Bool
  @FocusState private var isServingsFieldFocused: Bool
  
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
      //TODO Wrap if long
      TextField("Recipe Title", text: $title)
        .font(.system(
          //size: calculateTitleFontSize(for: title),
          size: 32,
          weight: .semibold
        ))
        .lineLimit(2)  // Allow text to wrap to two lines
        .multilineTextAlignment(.leading)
        .padding(.vertical, 2)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .focused($isTitleFieldFocused)
        .submitLabel(.done)
        .padding(.vertical, 2)
        .background(.white)
      
      TextField("Recipe summary", text: summaryTextBinding, axis: .vertical)
        .lineLimit(3...6)
        .focused($isSummaryFieldFocused)
        .onSubmit {
          isSummaryFieldFocused = false
        }
        .onChange(of: isSummaryFieldFocused) { _, newValue in
          if newValue {
            focusedField = .summary
          } else {
            focusedField = .none
          }
        }
      
    }
    Section {
      HStack {
        Text("Servings")
          .font(.body)
          .foregroundColor(Color.app.textLabel)
        
        Spacer()
        TextField("Optional", text: servingsTextBinding)
          .focused($isServingsFieldFocused)
          .keyboardType(.numberPad)
          .onSubmit {
            isServingsFieldFocused = false
          }
          .multilineTextAlignment(.trailing)
          .padding(.vertical, 8)
          .padding(.horizontal, 4)
        
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
          .onChange(of: isServingsFieldFocused) { _, newValue in
            if newValue {
              focusedField = .servings
            } else {
              focusedField = .none
            }
          }
      }
      // TODO  Combine with Timings
    }
  }
  
  private func calculateTitleFontSize(for text: String) -> CGFloat {
    // Start with large font for short titles
    let maxSize: CGFloat = 28
    let minSize: CGFloat = 18
    let threshold = 24  // Character count where scaling begins
    
    if text.count <= threshold {
      return maxSize
    } else {
      // Scale down linearly, with a minimum size
      let scaleFactor = 1.0 - min(1.0, CGFloat(text.count - threshold) / 30)
      print(max(minSize, maxSize * scaleFactor))
      return max(minSize, maxSize * scaleFactor)
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var servings: Int? = 4
    @State private var title = "Classic Chocolate Cake"
    @State private var summary: String? = "A rich, moist chocolate cake perfect for any occasion. This recipe has been in my family for generations."
    
    @State private var focusedField: RecipeFocusedField = .none
    
    var body: some View {
      NavigationStack {
        Form {
          RecipeEditSummarySection(
            title: $title,
            summary: $summary,
            servings: $servings,
            focusedField: $focusedField
          )
        }
      }
    }
  }
  
  return PreviewWrapper()
}
