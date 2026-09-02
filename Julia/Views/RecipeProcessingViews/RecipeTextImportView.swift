import SwiftUI
import SwiftData

struct RecipeTextImportView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  
  @Binding var recipeText: String?
  @FocusState var isRecipeTextFieldFocused: Bool

  @State private var inputText: String = ""
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        Form {
          Section ("Recipe Text") {
            TextEditor(text: $inputText)
              .font(.system(size: 12, design: .monospaced))
              .frame(minHeight: 200)
              .frame(maxWidth: .infinity)
              .foregroundColor(.secondary)
              .background(Color.app.white)
              .cornerRadius(12)
              .focused($isRecipeTextFieldFocused)
              .onSubmit {
                isRecipeTextFieldFocused = false
              }
              .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                  if isRecipeTextFieldFocused {
                    HStack(spacing: 12) {
                      Spacer()

                      Button("Paste") {
                        if let clipboardString = UIPasteboard.general.string {
                          inputText = inputText + clipboardString
                        }
                      }
                      .prominentKeyboardAccessoryStyle()

                      Button("Done") {
                        isRecipeTextFieldFocused = false
                      }
                    }
                    .keyboardAccessoryBarStyle()
                    .padding(.bottom, 24)
                  }
                }
                .hidesSharedGlassBackground()
              }
            
            
            Button {
              processRecipeText()
            } label: {
              Label("Import", systemImage: "sparkles")
                .disabled(inputText.isEmpty)
            }
          }
        }
        .scrollContentBackground(.hidden)
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
            processRecipeText()
          }
          .disabled(inputText.isEmpty)
        }
      }
      .onAppear {
        isRecipeTextFieldFocused = true
      }
      .onDisappear {
      }
    }
  }
  
  private func processRecipeText() {
    guard !inputText.isEmpty else { return }
    recipeText = inputText
    dismiss()
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var recipeText: String? = ""
    
    var body: some View {
      RecipeTextImportView(
        recipeText: $recipeText
      )
      .modelContainer(DataController.previewContainer)
    }
  }
  
  return PreviewWrapper()
}
