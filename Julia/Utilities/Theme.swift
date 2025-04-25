//
//  Theme.swift
//  Julia
//
//  Created by Claude on 3/3/25.
//

import SwiftUI

// MARK: - Environment Keys
private struct DebugModeKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var debugMode: Bool {
        get { self[DebugModeKey.self] }
        set { self[DebugModeKey.self] = newValue }
    }
}

struct ComponentTheme {
  // Button Styles
//    static func primaryButtonStyle() -> some ButtonStyle {
//        return PrimaryButtonStyle()
//    }
//    
//    static func secondaryButtonStyle() -> some ButtonStyle {
//        return SecondaryButtonStyle()
//    }
}

// Button Styles
//struct PrimaryButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .padding(.horizontal, 12)
//            .padding(.vertical, 8)
//            .background(AppTheme.primary)
//            .foregroundColor(AppTheme.textOnPrimary)
//            .cornerRadius(8)
//            .scaleEffect(configuration.isPressed ? 0.95 : 1)
//            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
//    }
//}
//
//struct SecondaryButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .padding(.horizontal, 12)
//            .padding(.vertical, 8)
//            .background(AppTheme.secondary)
//            .foregroundColor(AppTheme.primary)
//            .cornerRadius(8)
//            .scaleEffect(configuration.isPressed ? 0.95 : 1)
//            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
//    }
//}

// Extension for view modifiers
//extension View {
//    func primaryButtonStyle() -> some View {
//        self.buttonStyle(AppTheme.primaryButtonStyle())
//    }
//    
//    func secondaryButtonStyle() -> some View {
//        self.buttonStyle(AppTheme.secondaryButtonStyle())
//    }
//}



struct AppTheme {
  enum Colors {
    // MARK: - Off White Shades
    static let offWhite100 = Color("offwhite.100")
    static let offWhite200 = Color("offwhite.200")
    static let offWhite300 = Color("offwhite.300")
    static let offWhite400 = Color("offwhite.400")
    static let offWhite500 = Color("offwhite.500")
    
    // MARK: - Grey Shades
    static let grey100 = Color("grey.100")
    static let grey200 = Color("grey.200")
    static let grey300 = Color("grey.300")
    static let grey400 = Color("grey.400")
    static let grey500 = Color("grey.500")
    // Accent Colors
    static let primary = Color("primary") // #D72638
    static let primaryDisabled = Color("Primary.disabled")

    static let secondary = Color("secondary") // (red: 0.85, green: 0.92, blue: 1.0)
    static let secondaryDisabled = Color("Secondary.disabled")


    // Background Colors
    static let backgroundPrimary = Color("background.primary")
    static let backgroundSecondary = Color("background.secondary")
    
    // Text Colors
    static let textPrimary = Color("text.primary") // #1C1C1C
    static let textSecondary = Color("grey.400")
    static let textLabel = Color("grey.300")
    static let textTitle = Color("grey.300")
    
    // Misc Colors
    static let textOnPrimary = Color.white
    static let danger = Color("danger")
    
    // MARK: - Primary Colors
    static let primaryColor = Color("PrimaryColor") // Define in assets
    static let secondaryColor = Color("SecondaryColor")
    

  }
}

extension Color {
  static let app = AppTheme.Colors.self
}

