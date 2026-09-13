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
    static let offWhite200 = Color("offwhite.200")
    static let offWhite400 = Color("offwhite.400")
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

    // Text Colors
    static let textPrimary = Color("text.primary")
    static let textSecondary = Color("grey.400")
    // Same asset as textSecondary for now — Figma's brand/text-tertiary and
    // brand/text-disabled are still identical to brand/text-secondary as of
    // the 2026-09-12 token table (docs/design-tokens.md flag #4). Kept as
    // distinct names so call sites read semantically and can diverge later
    // without another rename.
    static let textTertiary = Color("grey.400")
    static let textDisabled = Color("grey.400")
    static let textPlaceholder = Color("text.placeholder")
    static let labelPrimary = Color("grey.300")
    // ios/secondaryLabel is translucent (#3C3C43 @ 60% / #EBEBF5 @ 60%) and
    // composites over its surface — that's exactly UIKit's dynamic
    // .secondaryLabel, so use it directly rather than freezing a flat hex.
    static let labelSecondary = Color(uiColor: .secondaryLabel)

    // Misc Colors
    static let textOnPrimary = Color.white
    static let danger = Color("danger")
    static let white = Color("white")

  }
}

extension Color {
  static let app = AppTheme.Colors.self
}

