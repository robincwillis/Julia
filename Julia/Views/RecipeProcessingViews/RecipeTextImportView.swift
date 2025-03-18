import SwiftUI
import SwiftData

struct RecipeTextImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Binding var recipeText: String?
    @Binding var showRecipeProcessing: Bool
    
    @State private var isLoading = false
    
    @FocusState var isRecipeTextFieldFocused: Bool

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
                        Section{
                          TextEditor(text: recipeTextBinding)
                            .font(.system(size: 12, design: .monospaced))
                          //.padding(0)
                            .frame(minHeight: 200)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                            .background(.white)
                            .cornerRadius(12)
                            .focused($isRecipeTextFieldFocused)
                            .onSubmit {
                              isRecipeTextFieldFocused = false
                            }
                            .toolbar {
                              ToolbarItemGroup(placement: .keyboard) {
                                if isRecipeTextFieldFocused {
                                  Spacer()
                                  Button("Done") {
                                    isRecipeTextFieldFocused = false
                                  }
                                }
                              }
                            }

                            
                            Button("Process") {
                              processRecipeText()
                            }                            
                            .disabled(recipeText?.isEmpty ?? true)
                        } header: {
                          HStack(alignment: .center) {
                            Text("Recipe Text")
                            Spacer()
                            Button("Paste from Clipboard") {
                              if let clipboardString = UIPasteboard.general.string {
                                recipeText = (recipeText ?? "") + clipboardString
                              }
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.85, green: 0.92, blue: 1.0))
                            .cornerRadius(8)
                          }
                          .frame(maxWidth: .infinity, alignment: .leading)

                        }
                    }
                }
            }
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
              ToolbarItem(placement: .primaryAction) {
                  Button("Process") {
                    processRecipeText()
                  }
                  .disabled(recipeText?.isEmpty ?? true)
                }
            }
            .onAppear {
              if recipeText == nil {
                recipeText = ""
              }
              isLoading = false
              isRecipeTextFieldFocused = true
            }
            .onDisappear {
              // Clear if we're not in the middle of processing
              if !isLoading && !showRecipeProcessing {
                recipeText = nil
              }
              
              if recipeText == "" {
                recipeText = nil
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
