import SwiftUI
import SwiftData

struct RecipeTextImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @Binding var showRecipeProcessing: Bool
    
    @State private var recipeText = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Processing recipe...")
                        .padding()
                } else {
                    Form {
                        Section(header: Text("Paste Recipe Text")) {
                            TextEditor(text: $recipeText)
                                .frame(minHeight: 200)
                                .overlay(
                                    Group {
                                        if recipeText.isEmpty {
                                            Text("Paste recipe text from your notes, email, or any text source...")
                                                .foregroundColor(.secondary)
                                                .padding(8)
                                                .allowsHitTesting(false)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        }
                                    }
                                )
                            
                            Button(action: processRecipeText) {
                                Text("Process Recipe")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(recipeText.isEmpty)
                        }
                        
                        Section(header: Text("Tips")) {
                            Text("Include the recipe title, ingredients, and instructions for best results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Import Text Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func processRecipeText() {
        guard !recipeText.isEmpty else { return }
        
        isLoading = true
        
        // Convert the text to lines
        let lines = recipeText.components(separatedBy: .newlines)
        
        Task {

            
            await MainActor.run {
                
                // Clean up and dismiss
                isLoading = false
                dismiss()
                
                // Show recipe processing view after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showRecipeProcessing = true
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showRecipeProcessing = false
        
        var body: some View {
            RecipeTextImportView(
                showRecipeProcessing: $showRecipeProcessing
            )
            .modelContainer(DataController.previewContainer)
        }
    }
    
    return PreviewWrapper()
}
