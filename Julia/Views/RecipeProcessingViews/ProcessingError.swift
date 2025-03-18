//
//  ProcessingError.swift
//  Julia
//
//  Created by Robin Willis on 3/15/25.
//

import SwiftUI

struct ProcessingError: View {
  @Environment(\.dismiss) private var dismiss

  @ObservedObject var processingState: RecipeProcessingState

  var body: some View {
    VStack(spacing: 24) {
      if let image = processingState.image {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(height: 200)
          .cornerRadius(12)
      }
      
      VStack(spacing: 16) {
        Image(systemName: "text.magnifyingglass")
          .font(.system(size: 70))
          .foregroundColor(.secondary)
        
        Text("No Text Detected")
          .font(.headline)
        
        Text("We couldn't find any text in this image. Try another image with clear, visible text.")
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal)
      }
      
      Button("Try Again") {
        dismiss()
      }
      .buttonStyle(.borderedProminent)
      .padding(.top)
    }
    .padding()
  }
}

#Preview {
  struct PreviewWrapper: View {
    @StateObject private var processingState = RecipeProcessingState()
    
    var body: some View {
      ProcessingError(processingState: processingState)
    }
  }
  return PreviewWrapper()
}
