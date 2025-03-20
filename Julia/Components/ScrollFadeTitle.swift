//
//  ScrollFadeTitle.swift
//  Julia
//
//  Created by Robin Willis on 3/18/25.
//

import SwiftUI

struct ScrollFadeTitle: View {
  // Properties needed from parent
  let title: String
  @Binding var titleIsVisible: Bool
  @State var titleHeight: CGFloat = 80
  @State var titleOpacity: Double = 1
  
  var body: some View {
    GeometryReader { geometry in
      Text(title)
        .font(.largeTitle)
        .fontWeight(.bold)
        .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
        .background(
          // Background for height measurement
          GeometryReader { geo -> Color in
            DispatchQueue.main.async {
              self.titleHeight = geo.size.height
            }
            return Color.clear
          }
        )
        .onChange(of: geometry.frame(in: .named("scrollContainer")).minY) { oldValue, newValue in
          // Update visibility based on scroll position
          titleIsVisible = newValue > -titleHeight
          // Calculate opacity based on scroll position
          if newValue >= 0 {
            // Fully visible
            titleOpacity = 1.0
          } else if newValue <= -titleHeight {
            // Fully scrolled out
            titleOpacity = 0.0
          } else {
            titleOpacity = 1.0 - (-newValue / (titleHeight - 20))
          }
        }
    }
    .frame(height: titleHeight)
    .frame(maxWidth: .infinity)
    .opacity(titleOpacity)
  }
}
