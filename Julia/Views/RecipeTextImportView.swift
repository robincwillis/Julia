import SwiftUI
import SwiftData

struct RecipeTextImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @Binding var showRecipeProcessing: Bool
    @Binding var selectedImage: UIImage?
    
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
            // Simulate processing delay for UI feedback
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
            await MainActor.run {
                // Convert text to an image for processing pipeline compatibility
                let textImage = textToImage(recipeText, size: CGSize(width: 800, height: 1200))
                selectedImage = textImage
                
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
    
    // Helper function to convert text to an image (for processing pipeline compatibility)
    private func textToImage(_ text: String, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Fill background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            text.draw(in: CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40), withAttributes: attributes)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showRecipeProcessing = false
        @State private var selectedImage: UIImage? = nil
        
        var body: some View {
            RecipeTextImportView(
                showRecipeProcessing: $showRecipeProcessing,
                selectedImage: $selectedImage
            )
            .modelContainer(DataController.previewContainer)
        }
    }
    
    return PreviewWrapper()
}