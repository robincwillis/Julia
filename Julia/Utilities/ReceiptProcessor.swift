//
//  ReceiptProcessor.swift
//  Julia
//

import SwiftUI
import SwiftData

/// Manages the receipt scanning and parsing workflow.
/// Mirrors `RecipeProcessor` — reuses `RecipeProcessingState` for stage/sheet state.
@Observable
@MainActor
class ReceiptProcessor {
    var processingState = RecipeProcessingState()
    var receiptData = ReceiptData()

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - State Management

    func start() {
        processingState.reset()
        receiptData.reset()
        processingState.processingStage = .notStarted
        processingState.showProcessingSheet = true
        processingState.showResultsSheet = false
    }

    func complete() {
        processingState.processingStage = .completed
        processingState.showProcessingSheet = false
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            processingState.showResultsSheet = true
        }
    }

    func fail(error: String) {
        processingState.processingStage = .error
        processingState.errorMessage = error
        processingState.statusMessage = ""
    }

    // MARK: - Processing

    /// Entry point from `ReceiptScannerView` with recognized text lines.
    func processLines(_ lines: [String]) {
        start()
        processingState.processingStage = .processing
        processingState.statusMessage = "Parsing receipt items..."
        receiptData.rawText = lines

        Task {
            do {
                let parsed = try await parseReceiptLines(lines)
                receiptData.items = parsed
                complete()
            } catch {
                fail(error: error.localizedDescription)
            }
        }
    }

    // MARK: - Saving

    /// Inserts all selected items as `Ingredient` objects into SwiftData.
    /// Returns the number of items saved.
    @discardableResult
    func saveSelectedItems() -> Int {
        guard let context = modelContext else { return 0 }
        let selectedItems = receiptData.items.filter { $0.isSelected }
        for item in selectedItems {
            let ingredient = Ingredient(
                name: item.name,
                location: item.targetLocation,
                quantity: item.quantity,
                unit: item.unit
            )
            context.insert(ingredient)
        }
        processingState.reset()
        receiptData.reset()
        return selectedItems.count
    }

    // MARK: - Private

    private func parseReceiptLines(_ lines: [String]) async throws -> [ReceiptItem] {
        let text = lines.joined(separator: "\n")

        guard await FoundationModelsService.shared.isAvailable else {
            return heuristicParse(lines)
        }

        let prompt = """
        Parse this grocery receipt. Extract each grocery or food product as an item.
        Skip store name, date/time, cashier info, subtotals, tax lines, totals, and payment method lines.

        Receipt:
        \(text)
        """

        let result = try await FoundationModelsService.shared.generate(
            prompt,
            type: ParsedReceipt.self,
            instructions: "You are a grocery receipt parser. Extract only food and grocery product items."
        )

        return result.items.map { item in
            ReceiptItem(
                name: item.name,
                quantity: Double(item.quantity),
                unit: item.unit.isEmpty ? nil : item.unit,
                price: item.price.isEmpty ? nil : item.price
            )
        }
    }

    /// Heuristic fallback: strip price patterns and treat remaining text as item names.
    private func heuristicParse(_ lines: [String]) -> [ReceiptItem] {
        // Price pattern: digits, decimal, 2-digit cents (e.g. "3.99", "$12.50")
        let pricePattern = try? NSRegularExpression(pattern: #"\$?\d+\.\d{2}"#)
        let skipPattern = try? NSRegularExpression(
            pattern: #"(?i)(total|subtotal|tax|change|cash|credit|debit|visa|mastercard|thank you|receipt)"#
        )

        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count > 2 else { return nil }
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            if skipPattern?.firstMatch(in: trimmed, range: range) != nil { return nil }

            // Remove price from line
            var cleaned = trimmed
            if let match = pricePattern?.firstMatch(in: trimmed, range: range),
               let matchRange = Range(match.range, in: trimmed) {
                cleaned = trimmed.replacingCharacters(in: matchRange, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard !cleaned.isEmpty else { return nil }
            return ReceiptItem(name: cleaned)
        }
    }
}
