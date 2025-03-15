import SwiftUI
import SwiftData

struct RecipeURLImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @Binding var showRecipeProcessing: Bool
    
    @State private var urlText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var extractedRecipe: Recipe?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Extracting recipe...")
                        .padding()
                } else {
                    // Input form
                    Form {
                        Section(header: Text("Enter Recipe URL")) {
                            TextField("https://example.com/recipe", text: $urlText)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                            
                            Button(action: importRecipe) {
                                Text("Import Recipe")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(urlText.isEmpty)
                        }
                        
                        Section(header: Text("Examples")) {
                            Text("Try popular recipe sites like AllRecipes, Food Network, or NYT Cooking")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Import from Website")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }
    
    private func importRecipe() {
        guard !urlText.isEmpty else { return }
        
        // Trim whitespace and make sure URL has a scheme
        var processedURLTemp = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add https:// if no scheme present
        if !processedURLTemp.contains("://") {
            processedURLTemp = "https://" + processedURLTemp
        }
        
        // Create a local immutable copy to avoid the capture warning
        let finalURL = processedURLTemp
        
        isLoading = true
        
        Task {
            do {
                // Create a recipe web extractor and extract the recipe
                let extractor = RecipeWebExtractor()
                let recipe = try await extractor.extractRecipe(from: finalURL)
                
                // Save the recipe to the context
                await MainActor.run {
                    context.insert(recipe)
                    
                    let rawText = (recipe.rawText ?? []).joined(separator: "\n")
                    
                    // Clean up and dismiss
                    isLoading = false
                    dismiss()
                    
                    // Show recipe processing view
                    //DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showRecipeProcessing = true
                    //}
                }
            } catch let error as RecipeWebExtractor.ExtractionError {
                await MainActor.run {
                    isLoading = false
                    
                    switch error {
                    case .invalidURL:
                        errorMessage = "The URL provided is invalid"
                    case .networkError(let underlyingError):
                        errorMessage = "Network error: \(underlyingError.localizedDescription)"
                    case .parsingFailed(let reason):
                        errorMessage = "Parsing failed: \(reason)"
                    case .noRecipeFound:
                        errorMessage = "No recipe could be found on this page"
                    }
                    
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Unexpected error: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showRecipeProcessing = false
        
        var body: some View {
            RecipeURLImportView(
                showRecipeProcessing: $showRecipeProcessing
            )
            .modelContainer(DataController.previewContainer)
        }
    }
    
    return PreviewWrapper()
}
