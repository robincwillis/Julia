//
//  ScanInstructionView.swift
//  Julia
//

import SwiftUI

struct ScanInstructionView: View {
    var onOpenCamera: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            // Header
            VStack(spacing: 12) {
                Text("Scan a Recipe or Receipt")
                    .font(.title2.bold())

                Text("Point your camera at a recipe card or shopping receipt. Julia will automatically detect which it is and add it to the right place.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.top, 48)

            // What gets scanned
            HStack(spacing: 16) {
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
                    color: .blue
                )
            }
            .padding(.horizontal)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button(action: onOpenCamera) {
                    Label("Open Camera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.app.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .font(.body.bold())
                }
                .buttonStyle(.plain)

                Button("Cancel", action: onDismiss)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func scanTypeCard(icon: String, title: String, detail: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(color)
                .frame(width: 54, height: 54)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
}

#Preview {
    ScanInstructionView(onOpenCamera: {}, onDismiss: {})
}
