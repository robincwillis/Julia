//
//  Loader.swift
//  Julia
//
//  Created by Robin Willis on 4/12/25.
//

import SwiftUI

struct Loader: View {
  @Binding var isLoading: Bool
  @State private var rotation: Double = 0
  
  
  let numberOfCircles = 9
  let mainCircleSize: CGFloat = 18
  let smallCircleSize: CGFloat = 3
  let largeCircleSize: CGFloat = 6
  let expandedRadius: CGFloat = 9
  let animationDuration: Double = 0.2
  
  private var frameSize: CGFloat {
    return max(mainCircleSize, (expandedRadius + smallCircleSize/2) * 2)
  }
  
  private func angle(for index: Int) -> Double {
    return (2 * .pi / Double(numberOfCircles)) * Double(index)
  }
  
  var body: some View {
    ZStack {
      ForEach(0..<numberOfCircles, id: \.self) { index in
        Circle()
          .fill(Color.red)
          .frame(width: isLoading ? smallCircleSize: largeCircleSize
                 , height: isLoading ? smallCircleSize: largeCircleSize)
          .position(
            x: frameSize/2 + (isLoading ? expandedRadius * cos(angle(for: index)) : 0),
            y: frameSize/2 + (isLoading ? expandedRadius * sin(angle(for: index)) : 0)
          )
        //.opacity(animationState == .loading ? 1 : 0)
          .animation(.easeInOut(duration: animationDuration), value: isLoading)
      }
    }
    .rotationEffect(Angle(degrees: rotation))
    .frame(width: frameSize, height: frameSize)
    .onAppear() {
      //.onChange(of: isLoading) { _, newValue in
      //handleLoadingChange(isNowLoading: newValue)
      withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
        rotation = 360
      }
    }
  }
}


private struct PreviewWrapper: View {
  @State private var isLoading: Bool = true
  
  var body: some View {
    Loader(isLoading: $isLoading)
  }
}

#Preview {
  PreviewWrapper()
}
