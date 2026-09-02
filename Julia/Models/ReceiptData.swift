//
//  ReceiptData.swift
//  Julia
//

import Foundation

/// Intermediate container holding parsed receipt data before the user
/// confirms and items are saved as `Ingredient` objects.
struct ReceiptData {
    var id: String = UUID().uuidString
    var rawText: [String] = []
    var items: [ReceiptItem] = []

    mutating func reset() {
        rawText = []
        items = []
    }
}

/// A single item parsed from a grocery receipt.
struct ReceiptItem: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var quantity: Double?
    var unit: String?
    var price: String?
    /// Destination list; user can toggle per item in the review sheet.
    var targetLocation: IngredientLocation = .grocery
    /// Whether the item is selected for saving.
    var isSelected: Bool = true
}
