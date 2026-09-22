//
//  Theme.swift
//  Julia
//
//  Created by Claude on 3/3/25.
//

import SwiftUI

// MARK: - Environment Keys
private struct DebugModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
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
    static let offWhite200 = Color("offwhite.200")
    static let offWhite300 = Color("offwhite.300")  // L #E9E9E5 / D #4C4B47
    static let offWhite400 = Color("offwhite.400")

    // Checkbox: light and dark each needed a different step off the shared
    // offwhite ramp for good contrast (offwhite.300 was too close to
    // background.primary in light mode; offwhite.400 was too close to the
    // dark backgrounds). Own colorset carrying the best value per mode.
    static let checkboxUnselected = Color("checkbox.unselected")  // L #DDDAD1 / D #4C4B47
    // Semantic aliases for the off-white ramp (brand/background-form tokens)
    static let backgroundForm = Color("offwhite.200")
    static let backgroundFormField = Color("offwhite.400")

    // Accent Colors
    static let primary = Color("primary")
    static let primaryDisabled = Color("primary.disabled")

    static let secondary = Color("secondary")
    static let secondaryDisabled = Color("secondary.disabled")

    // Background Colors
    static let backgroundPrimary = Color("background.primary")
    static let backgroundSecondary = Color("background.secondary")
    // brand/background-keyboard-toolbar and brand/background-card — same
    // "backdrop" swatch, split from the old backgroundSecondary asset.
    // backgroundSecondary itself still needs its call sites individually
    // re-audited against the new table (docs/design-tokens.md flag #5)
    // before its own value can move to the new spec's black-in-dark value.
    static let backgroundSheet = Color("background.sheet")
    static let backgroundKeyboardToolbar = Color("background.card")
    static let backgroundCard = Color("background.card")
    static let backgroundInput = Color("background.input")  // L #F5F5F5 / D #1C1C1E — chat close btn, import btns, input field

    // Text Colors
    static let textPrimary = Color("text.primary")
    static let textSecondary = Color("text.secondary")   // L #494949 / D #BABABA
    static let textTertiary = Color("grey.400")           // L #494949 / D #C4C4C4
    static let textDisabled = Color("text.disabled")      // L #494949 / D #7A7671
    static let textPlaceholder = Color("text.placeholder") // L #C5C5C7 / D #7A7671
    static let labelPrimary = Color("grey.300")
    static let labelSecondary = Color("label.secondary")  // L #8D8C8B / D #8D8C8B

    // Misc Colors
    static let textOnPrimary = Color.white
    static let danger = Color("danger")
    static let white = Color("white")

  }
}

extension Color {
  static let app = AppTheme.Colors.self
}

