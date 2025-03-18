//
//  ProcessingImage.swift
//  Julia
//
//  Created by Robin Willis on 3/15/25.
//

import SwiftUI

struct ProcessingImage: View {
  var image: UIImage
  @Binding var isClassifying: Bool
  
  var body: some View {
    VStack(spacing: 20) {
      Image(uiImage: image)
        .resizable()
        .scaledToFit()
        .frame(height: 200)
        .cornerRadius(12)
      if isClassifying {
        ProgressView("Classifying recipe text...")
          .padding()
      } else {
        ProgressView("Processing recipe image...")
          .padding()
      }
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    private var image: UIImage = UIImage()
    @State private var isClassifying = false
    
    var body: some View {
      
      ProcessingImage(
        image: image,
        isClassifying: $isClassifying
      )
    }
  }
  return PreviewWrapper()
}
