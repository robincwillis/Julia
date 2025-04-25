//
//  GlowingIcon.swift
//  Julia
//
//  Created by Robin Willis on 4/20/25.
//

import SwiftUI

struct GlowingIcon: View {
    let systemName: String
    let size: CGFloat
    let primaryColor: Color
    let glowColor: Color
    
    // Animation state variables
    @State private var glowAmount: CGFloat = 0.5
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var radiusVariation: CGFloat = 1.0
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // Initialize with defaults or custom values
    init(
      systemName: String,
      size: CGFloat = 50,
      primaryColor: Color = .orange,
      glowColor: Color = .red
    ) {
      self.systemName = systemName
      self.size = size
      self.primaryColor = primaryColor
      self.glowColor = glowColor
    }
    
    var body: some View {
      Image(systemName: systemName)
        .font(.system(size: size))
        .foregroundColor(primaryColor)
        .shadow(
          color: glowColor.opacity(glowAmount),
          radius: 10 * radiusVariation,
          x: offsetX,
          y: offsetY
        )
        .shadow(
          color: primaryColor.opacity(glowAmount * 0.7),
          radius: 15 * radiusVariation,
          x: offsetX * 0.7,
          y: offsetY * 0.7
        )
        .onReceive(timer) { _ in
          // Create subtle random variations
          withAnimation(.easeInOut(duration: 0.8)) {
            glowAmount = CGFloat.random(in: 0.4...0.8)
            offsetX = CGFloat.random(in: -2...2)
            offsetY = CGFloat.random(in: -2...2)
            radiusVariation = CGFloat.random(in: 0.85...1.15)
          }
        }
    }
  }
