//
//  ProcessingResultsReceipt.swift
//  Julia
//

import SwiftUI

/// Review sheet shown after receipt scanning.
/// Users can toggle items on/off, edit names, and choose Grocery or Pantry per item.
struct ProcessingResultsReceipt: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var receiptData: ReceiptData
    var saveItems: () -> Int

    @State private var showDismissAlert = false

    var selectedCount: Int {
        receiptData.items.filter { $0.isSelected }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if receiptData.items.isEmpty {
                    ContentUnavailableView(
                        "No Items Found",
                        systemImage: "receipt",
                        description: Text("No grocery items could be parsed from the scanned receipt.")
                    )
                } else {
                    itemList
                }
            }
            .navigationTitle("Receipt Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if !receiptData.items.isEmpty {
                            showDismissAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    if selectedCount > 0 {
                        Button("Save \(selectedCount)") {
                            _ = saveItems()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.app.primary)
                    }
                }
            }
            .alert("Discard Receipt?", isPresented: $showDismissAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The scanned items will not be saved.")
            }
        }
    }

    private var itemList: some View {
        List {
            Section {
                ForEach($receiptData.items) { $item in
                    ReceiptItemRow(item: $item)
                }
            } header: {
                HStack {
                    Text("\(receiptData.items.count) items found")
                    Spacer()
                    Button(selectedCount == receiptData.items.count ? "Deselect All" : "Select All") {
                        let allSelected = selectedCount == receiptData.items.count
                        for i in receiptData.items.indices {
                            receiptData.items[i].isSelected = !allSelected
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Row View

private struct ReceiptItemRow: View {
    @Binding var item: ReceiptItem

    var body: some View {
        HStack(spacing: 12) {
            // Selection toggle
            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isSelected ? Color.app.primary : .secondary)
                .font(.title3)
                .onTapGesture { item.isSelected.toggle() }

            // Editable name
            TextField("Item name", text: $item.name)
                .foregroundStyle(item.isSelected ? .primary : .secondary)

            // Grocery / Pantry picker
            if item.isSelected {
                Picker("", selection: $item.targetLocation) {
                    Text("Grocery").tag(IngredientLocation.grocery)
                    Text("Pantry").tag(IngredientLocation.pantry)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
        }
        .contentShape(Rectangle())
        .opacity(item.isSelected ? 1 : 0.5)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var data = ReceiptData(
            rawText: [],
            items: [
                ReceiptItem(name: "Whole Milk", quantity: 1, unit: "gal", price: "4.99"),
                ReceiptItem(name: "Organic Eggs", quantity: 1, unit: "dozen", price: "6.49"),
                ReceiptItem(name: "Chicken Breast", quantity: 2, unit: "lb", price: "9.98"),
                ReceiptItem(name: "Greek Yogurt", price: "3.49")
            ]
        )
        var body: some View {
            ProcessingResultsReceipt(receiptData: $data, saveItems: { 0 })
        }
    }
    return PreviewWrapper()
}
