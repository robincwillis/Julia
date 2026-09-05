//
//  View+Extensions.swift
//  Julia
//
//  Created by Robin Willis on 3/18/25.
//

import SwiftUI

extension View {
  func hideKeyboard() {
    print("Hiding keyboard called")
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

extension View {
  /// Styles a primary keyboard accessory action as a solid prominent capsule.
  /// Styled manually rather than via buttonStyle: built-in button styles
  /// (borderedProminent, glassProminent) don't render their fills reliably
  /// inside keyboard toolbars.
  func prominentKeyboardAccessoryStyle(fill: Color = .blue) -> some View {
    self
      .foregroundStyle(Color.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(fill, in: Capsule())
  }

  /// Presents keyboard accessory content as a rounded toolbar strip with a
  /// gap only at the bottom separating it from the keyboard. Pair with
  /// `hidesSharedGlassBackground()` on the toolbar item so the system doesn't
  /// draw its own container behind (or merge glass into) this bar.
  @ViewBuilder
  func keyboardAccessoryBarStyle() -> some View {
    let base = self
      // Content inset inside the floating bar
      .padding(.horizontal, 3)
      .padding(.vertical, 3)
      .frame(maxWidth: .infinity)
    if #available(iOS 26.0, *) {
      // glassEffect already renders a capsule + material — matches nav button style
      base
        .glassEffect()
        .shadow(color: .black.opacity(0.05), radius: 24, y: 8)
    } else {
      base
        .background(.regularMaterial, in: .capsule)
        .shadow(color: .black.opacity(0.05), radius: 24, y: 8)
    }
  }
}

extension ToolbarContent {
  /// Hides the system Liquid Glass capsule (border + padding) that iOS 26 wraps
  /// around toolbar items, so custom circular buttons render as flat circles.
  /// No-op on earlier iOS versions, which don't apply the glass effect.
  @ToolbarContentBuilder
  func hidesSharedGlassBackground() -> some ToolbarContent {
    if #available(iOS 26.0, *) {
      self.sharedBackgroundVisibility(.hidden)
    } else {
      self
    }
  }
}

// Canvas stand-in for the keyboard accessory bar. The canvas can't show a
// real keyboard toolbar, so this renders the same content + styling directly
// for quick iteration. The system's toolbar hosting (hidden via
// hidesSharedGlassBackground) is not reproduced here — verify final results
// in the simulator.
#Preview("Keyboard Accessory Bar") {
  ZStack {
    Color.app.backgroundSecondary.ignoresSafeArea()
    VStack {
      Spacer()
      HStack(spacing: 12) {
          
        Button("Clear") {}
          .foregroundColor(Color.app.danger)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          

        Spacer()
          
        Button("Done") {}

        Button("Paste") {}
          

        
      }
      .keyboardAccessoryBarStyle()
      //.prominentKeyboardAccessoryStyle()

      // Keyboard stand-in so the bottom gap reads correctly
      Rectangle()
        .fill(Color(.systemGray4))
        .frame(height: 120)
        .ignoresSafeArea()
    }
  }
}
