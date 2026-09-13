//
//  ScanInstructionView.swift
//  Julia
//

import SwiftUI

struct ScanInstructionView: View {
    var onOpenCamera: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("Scan a Recipe or Receipt")
                    .font(.title2.bold())

                Text("Point your camera at a recipe card or shopping receipt. Julia will automatically detect which it is and add it to the right place.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // What gets scanned
            HStack(spacing: 24) {
                scanTypeCard(
                    icon: "fork.knife",
                    title: "Recipe",
                    detail: "Creates a new recipe",
                    color: Color.app.primary
                )
                scanTypeCard(
                    icon: "receipt",
                    title: "Receipt",
                    detail: "Add items to your kitchen",
                    color: Color.app.secondary
                )
            }

            // Actions
            VStack(spacing: 16) {
                Button(action: onOpenCamera) {
                    Label("Open Camera", systemImage: "camera.fill")
                        .font(.body.bold())
                        .foregroundStyle(Color.app.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.app.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                Button("Cancel", action: onDismiss)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }

    private func scanTypeCard(icon: String, title: String, detail: String, color: Color) -> some View {
        VStack(spacing: 12) {
            GlowingIcon(
                systemName: icon,
                size: 32,
                primaryColor: color,
                glowColor: color
            )

            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScanInstructionView(onOpenCamera: {}, onDismiss: {})
}
