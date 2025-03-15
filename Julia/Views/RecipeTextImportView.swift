import SwiftUI
import SwiftData

struct RecipeTextImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Binding var recipeText: String?
    @Binding var showRecipeProcessing: Bool
    
    @State private var isLoading = false
  
   // Create a computed property that provides a non-optional binding
    private var recipeTextBinding: Binding<String> {
      Binding<String>(
        get: { self.recipeText ?? "" },
        set: { self.recipeText = $0 }
      )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Processing recipe...")
                        .padding()
                } else {
                    Form {
                        Section(header: Text("Paste Recipe Text")) {
                            TextEditor(text: recipeTextBinding)
                                .frame(minHeight: 200)
//                                .overlay(
//                                    Group {
//                                        if recipeText.isEmpty {
//                                            Text("Paste recipe text from your notes, email, or any text source...")
//                                                .foregroundColor(.secondary)
//                                                .padding(8)
//                                                .allowsHitTesting(false)
//                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//                                        }
//                                    }
//                                )
                            
                            Button(action: processRecipeText) {
                                Text("Process Recipe")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(recipeText?.isEmpty ?? true)
                        }
                    }
                }
            }
            .navigationTitle("Import Text")
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
        guard let text = recipeText, !text.isEmpty else { return }

        // Convert the text to lines
        // let lines = text.components(separatedBy: .newlines)
        
        Task {
            await MainActor.run {
                // Clean up and dismiss
                isLoading = false
                showRecipeProcessing = true
                dismiss()
                // Show recipe processing view after a short delay
                //DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                //}
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var recipeText: String? = ""
        @State private var showRecipeProcessing = false
        
        var body: some View {
            RecipeTextImportView(
                recipeText: $recipeText,
                showRecipeProcessing: $showRecipeProcessing
            )
            .modelContainer(DataController.previewContainer)
        }
    }
    
    return PreviewWrapper()
}
