//
//  ReceiptScannerView.swift
//  Julia
//

import SwiftUI
import VisionKit

/// Full-screen live text scanner for capturing grocery receipts.
/// Uses `DataScannerViewController` for real-time text recognition.
/// When the user taps "Done", all recognized text lines are passed to `onScan`.
struct ReceiptScannerView: UIViewControllerRepresentable {
    var onScan: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
            // If scanner isn't available, return an empty controller
            // (caller should check availability before presenting)
            return UINavigationController()
        }

        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner

        let nav = UINavigationController(rootViewController: scanner)
        nav.navigationBar.tintColor = UIColor.systemBlue

        // Add Done button
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .prominent,
            target: context.coordinator,
            action: #selector(Coordinator.doneTapped)
        )
        // Add Cancel button
        let cancelButton = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.cancelTapped)
        )
        scanner.navigationItem.rightBarButtonItem = doneButton
        scanner.navigationItem.leftBarButtonItem = cancelButton
        scanner.navigationItem.title = "Scan Receipt"

        try? scanner.startScanning()
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: ([String]) -> Void
        weak var scanner: DataScannerViewController?
        private var recognizedTexts: [String] = []

        init(onScan: @escaping ([String]) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            recognizedTexts = allItems.compactMap { item in
                if case .text(let text) = item {
                    return text.transcript
                }
                return nil
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didUpdate updatedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            recognizedTexts = allItems.compactMap { item in
                if case .text(let text) = item {
                    return text.transcript
                }
                return nil
            }
        }

        @objc func doneTapped() {
            scanner?.stopScanning()
            let lines = recognizedTexts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            onScan(lines)
        }

        @objc func cancelTapped() {
            scanner?.stopScanning()
            onScan([])
        }
    }
}

/// Availability check view — shown in place of the scanner on unsupported devices.
struct ReceiptScannerUnavailableView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Receipt Scanner Unavailable")
                .font(.headline)
            Text("Live text scanning requires iOS 16 or later on a supported device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Dismiss") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ReceiptScannerUnavailableView()
}
