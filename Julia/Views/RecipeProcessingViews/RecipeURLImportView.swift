import SwiftUI
import SwiftData

struct RecipeURLImportView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
    
  @State private var urlText = ""

  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var showError = false
  @State private var extractedRecipe: Recipe?
  
  @FocusState private var isUrlTextFieldFocused: Bool
  
  @Binding var extractedRecipeData: RecipeData?

  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        if isLoading {
          ProgressView("Extracting recipe...")
            .padding()
        } else {
          // Input form
          Form {
            Section(header: Text("Recipe URL")) {
              TextField("Enter Recipe URL to import", text: $urlText)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isUrlTextFieldFocused)
                .onSubmit {
                  isUrlTextFieldFocused = false
                }
              
              Button(action: importRecipe) {
                Label("Import", systemImage: "sparkles")
              }
              .disabled(urlText.isEmpty)
            }
            
            
          }
          .scrollContentBackground(.hidden)
        }
      }
      .background(Color.app.backgroundSecondary)
      .navigationTitle("Import Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .primaryAction) {
          Button("Import") {
            importRecipe()
          }
          .disabled(urlText.isEmpty)
        }
        ToolbarItemGroup(placement: .keyboard) {
          HStack(spacing: 6) {
            Spacer()
            Button("Paste") {
              if let clipboardString = UIPasteboard.general.string {
                urlText = clipboardString
              }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
            .background(.blue)
            .cornerRadius(12)
            .padding(.vertical, 3)
          
          }
        }
      }
    }
    .alert("Error", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage ?? "Unknown error occurred")
    }
    .onAppear {
      isUrlTextFieldFocused = true
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
        
  
        await MainActor.run {
  
          
          // Don't Insert into Database
          // context.insert(recipe)

          extractedRecipeData = recipe
          // Lets hold off of setting import text for now
          // let rawText = (recipe.rawText ?? []).joined(separator: "\n")
          // selectedText = rawText

          
          // Clean up and dismiss
          isLoading = false
          dismiss()

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
    @State private var extractedRecipeData: RecipeData?
    
    var body: some View {
      RecipeURLImportView(
        extractedRecipeData: $extractedRecipeData
      )
      .modelContainer(DataController.previewContainer)
    }
  }
  
  return PreviewWrapper()
}
