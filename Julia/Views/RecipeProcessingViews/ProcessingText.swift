//
//  ProcessingText.swift
//  Julia
//
//  Created by Robin Willis on 3/15/25.
//

import SwiftUI

struct ProcessingText: View {
  @Binding var isClassifying: Bool
  
  var body: some View {
    VStack(spacing: 20) {
      if isClassifying {
        ProgressView("Classifying recipe text...")
          .padding()
      } else {
        ProgressView("Processing recipe text...")
          .padding()
      }
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var isClassifying = false
    var body: some View {
      ProcessingText(isClassifying:$isClassifying)
    }
  }
  return PreviewWrapper()
}
