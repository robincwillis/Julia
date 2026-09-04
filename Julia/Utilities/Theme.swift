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
    static let primary = Color("primary")
    static let primaryDisabled = Color("primary.disabled")

    static let secondary = Color("secondary")
    static let secondaryDisabled = Color("secondary.disabled")


    // Background Colors
    static let backgroundPrimary = Color("background.primary")
    static let backgroundSecondary = Color("background.secondary")

    // Text Colors
    static let textPrimary = Color("text.primary")
    static let textSecondary = Color("grey.400")
    static let textLabel = Color("grey.300")
    static let textTitle = Color("grey.300")

    // Misc Colors
    static let textOnPrimary = Color.white
    static let danger = Color("danger")
    static let white = Color("white")

  }
}

extension Color {
  static let app = AppTheme.Colors.self
}

