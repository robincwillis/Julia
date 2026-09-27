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
              .font(.system(size: 14, design: .monospaced))
              .frame(minHeight: 200)
              .frame(maxWidth: .infinity)
              .foregroundColor(Color.app.textPrimary)
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
                      .foregroundStyle(Color.app.secondary)

                      Button("Done") {
                        isRecipeTextFieldFocused = false
                      }
                      .foregroundStyle(Color.app.primary)
                      .fontWeight(.medium)
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
              HStack(spacing: 4) {
                Image(systemName: "sparkles")
                Text("Import")
              }
            }
            .foregroundStyle(inputText.isEmpty ? Color.app.primary.opacity(0.4) : Color.app.primary)
            .disabled(inputText.isEmpty)
          }
          .listRowBackground(Color.app.backgroundSheet)
        }
        .scrollContentBackground(.hidden)
      }
      .background(Color.app.backgroundSecondary.ignoresSafeArea())
      .navigationTitle("Import Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(Color.app.primary)
          }
          .circleToolbarButtonStyle()
          .buttonStyle(.plain)
        }
        .hidesSharedGlassBackground()
        ToolbarItem(placement: .primaryAction) {
          Button {
            processRecipeText()
          } label: {
            Image(systemName: "checkmark")
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(.white)
              .frame(width: 44, height: 44)
              .background(inputText.isEmpty ? Color.app.primary.opacity(0.35) : Color.app.primary, in: Circle())
              .shadow(color: inputText.isEmpty ? .clear : Color.app.primary.opacity(0.3), radius: 4, x: 0, y: 2)
          }
          .buttonStyle(.plain)
          .disabled(inputText.isEmpty)
        }
        .hidesSharedGlassBackground()
      }
      .onAppear {
        isRecipeTextFieldFocused = true
      }
      .onDisappear {
      }
    }
    .presentationBackground(Color.app.backgroundSecondary)
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
