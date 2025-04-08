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
          ProgressView("Importing recipe...")
            .padding()
        } else {
          Form {
            Section ("Recipe Text") {
              TextEditor(text: recipeTextBinding)
                .font(.system(size: 12, design: .monospaced))
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
                    HStack (spacing: 6) {
                      
                      if isRecipeTextFieldFocused {
                        Spacer()
                        
                        Button("Paste") {
                          if let clipboardString = UIPasteboard.general.string {
                            recipeText = (recipeText ?? "") + clipboardString
                          }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(.blue)
                        .cornerRadius(12)
                        .padding(.vertical, 3)
                        
                        Button("Done") {
                          isRecipeTextFieldFocused = false
                        }
                      }
                    }
                  }
                }
              
              
              Button {
                processRecipeText()
              } label: {
                Label("Import", systemImage: "sparkles")
                  .disabled(recipeText?.isEmpty ?? true)
              }
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
          Button("Import") {
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
