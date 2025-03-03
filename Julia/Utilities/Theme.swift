//
//  Theme.swift
//  Julia
//
//  Created by Claude on 3/3/25.
//

import SwiftUI

struct AppTheme {
    // Primary Colors
    static let primary = Color.blue
    static let secondary = Color(red: 0.85, green: 0.92, blue: 1.0)
    
    // Background Colors
    static let backgroundPrimary = Color.white
    static let backgroundSecondary = Color(.systemGray6)
    
    // Text Colors
    static let textPrimary = Color.black
    static let textSecondary = Color.gray
    static let textOnPrimary = Color.white
    
    // Button Styles
    static func primaryButtonStyle() -> some ButtonStyle {
        return PrimaryButtonStyle()
    }
    
    static func secondaryButtonStyle() -> some ButtonStyle {
        return SecondaryButtonStyle()
    }
}

// Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.primary)
            .foregroundColor(AppTheme.textOnPrimary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.secondary)
            .foregroundColor(AppTheme.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Extension for view modifiers
extension View {
    func primaryButtonStyle() -> some View {
        self.buttonStyle(AppTheme.primaryButtonStyle())
    }
    
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(AppTheme.secondaryButtonStyle())
    }
}

// Convenience extension to access theme colors directly from Color
extension Color {
    // Primary Colors
    static let appPrimary = AppTheme.primary
    static let appSecondary = AppTheme.secondary
    
    // Background Colors
    static let appBackgroundPrimary = AppTheme.backgroundPrimary
    static let appBackgroundSecondary = AppTheme.backgroundSecondary
    
    // Text Colors
    static let appTextPrimary = AppTheme.textPrimary
    static let appTextSecondary = AppTheme.textSecondary
    static let appTextOnPrimary = AppTheme.textOnPrimary
}