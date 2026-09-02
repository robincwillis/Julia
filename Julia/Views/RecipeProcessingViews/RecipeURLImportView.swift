import SwiftUI
import SwiftData

struct RecipeURLImportView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var urlText = ""

  @FocusState private var isUrlTextFieldFocused: Bool

  @Binding var selectedURL: String?

  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
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
          HStack {
            Spacer()
            Button("Paste") {
              if let clipboardString = UIPasteboard.general.string {
                urlText = clipboardString
              }
            }
            .prominentKeyboardAccessoryStyle()
          }
          .keyboardAccessoryBarStyle()
          .padding(.bottom, 24)
        }
        .hidesSharedGlassBackground()
      }
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

    // Hand the URL to the shared processing pipeline and dismiss —
    // extraction progress is shown by the floating status sheet
    selectedURL = processedURLTemp
    dismiss()
  }

}

#Preview {
  struct PreviewWrapper: View {
    @State private var selectedURL: String?

    var body: some View {
      RecipeURLImportView(
        selectedURL: $selectedURL
      )
      .modelContainer(DataController.previewContainer)
    }
  }

  return PreviewWrapper()
}
