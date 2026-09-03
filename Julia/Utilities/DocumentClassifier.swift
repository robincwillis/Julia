//
//  DocumentClassifier.swift
//  Julia
//

import Foundation
import FoundationModels

enum DocumentType {
    case recipe, receipt
}

@Generable
private struct DocumentTypeResult {
    @Guide(
        description: "The document type: 'recipe' for cooking recipes with ingredients and cooking steps, 'receipt' for store receipts with purchased items and prices",
        .anyOf(["recipe", "receipt"])
    )
    var type: String
}

struct DocumentClassifier {

    /// Classifies OCR text lines as a recipe or receipt.
    /// Tries Foundation Models first; falls back to heuristics.
    static func classify(lines: [String]) async -> DocumentType {
        guard !lines.isEmpty else { return .recipe }

        let service = FoundationModelsService.shared
        if await service.isAvailable {
            let sample = lines.prefix(40).joined(separator: "\n")
            let prompt = """
                Classify the following scanned document as either a recipe or a receipt.

                Document text:
                \(sample)
                """
            if let result = try? await service.generate(prompt, type: DocumentTypeResult.self) {
                return result.type == "receipt" ? .receipt : .recipe
            }
        }
        return heuristic(lines: lines)
    }

    private static func heuristic(lines: [String]) -> DocumentType {
        let text = lines.joined(separator: " ").lowercased()
        var receiptScore = 0
        var recipeScore = 0

        let receiptWords = ["total", "subtotal", "tax", "receipt", "cashier", "change", "payment", "qty", "price"]
        for word in receiptWords where text.contains(word) { receiptScore += 1 }
        if text.contains("$") { receiptScore += 2 }

        let recipeWords = ["cup", "tbsp", "tsp", "tablespoon", "teaspoon", "ingredient",
                           "preheat", "bake", "serves", "servings", "minutes", "oven", "stir", "mix"]
        for word in recipeWords where text.contains(word) { recipeScore += 1 }

        return receiptScore > recipeScore ? .receipt : .recipe
    }
}
