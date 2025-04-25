import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsDrawer: View {
  @Binding var isOpen: Bool
  @Environment(\.debugMode) private var debugMode
  @State private var debugModeState: Bool = false
  @Environment(\.colorScheme) private var colorScheme
  
  // Import/Export states
  @State private var isExporting = false
  @State private var isImporting = false
  @State private var exportURL: URL?
  @State private var showExportSheet = false
  @State private var errorMessage: String?
  @State private var showError = false
  @State private var showSuccess = false
  @State private var successMessage = ""
  @State private var showLoadSampleConfirmation = false
  @State private var showClearDataConfirmation = false
  @State private var isLoadingSampleData = false
  @State private var isClearingData = false
  @State private var loadedCount = 0
  
  @Environment(\.modelContext) private var context
  
  let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
  let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
  
  var body: some View {
    ZStack {
      // Invisible background tap handler that covers the entire screen when drawer is open
      if isOpen {
        Color.clear
          .contentShape(Rectangle())
          .ignoresSafeArea()
          .onTapGesture {
            // Close drawer when tapping outside
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              isOpen = false
            }
          }
      }
      
      // Drawer panel
      HStack(spacing: 0) {
        // Actual drawer content
        ZStack {
          // Background
          Color.white
          
          VStack(alignment: .leading, spacing: 24) {
            // Logo
//            Image("julia")
//              .resizable()
//              .scaledToFit()
//              .frame(height: 72)
//              .padding(.bottom, 24)
            
            // Data Management Section
            VStack(alignment: .leading, spacing: 16) {
              // Export button
              Button(action: exportData) {
                HStack {
                  Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Color.app.primary)
                    .frame(width: 24)
                  Text("Export Recipes")
                    .font(.headline)
                  
                  if isExporting {
                    Spacer()
                    ProgressView()
                      .scaleEffect(0.7)
                  }
                }
                .foregroundColor(Color.app.textPrimary)
                .padding(.vertical, 8)
              }
              .disabled(isExporting || isImporting || isLoadingSampleData)
              
              // Import button
              Button(action: importData) {
                HStack {
                  Image(systemName: "square.and.arrow.down")
                    .foregroundColor(Color.app.primary)
                    .frame(width: 24)
                  Text("Import Recipes")
                    .font(.headline)
                  
                  if isImporting {
                    Spacer()
                    ProgressView()
                      .scaleEffect(0.7)
                  }
                }
                .foregroundColor(Color.app.textPrimary)
                .padding(.vertical, 8)
              }
              .disabled(isExporting || isImporting || isLoadingSampleData)
              
              // Load sample data button
              Button(action: { showLoadSampleConfirmation = true }) {
                HStack {
                  Image(systemName: "plus.square.on.square")
                    .foregroundColor(Color.app.primary)
                    .frame(width: 24)
                  Text("Load Sample Data")
                    .font(.headline)
                  
                  if isLoadingSampleData {
                    Spacer()
                    ProgressView()
                      .scaleEffect(0.7)
                  }
                }
                .foregroundColor(Color.app.textPrimary)
                .padding(.vertical, 8)
              }
              .disabled(isExporting || isImporting || isLoadingSampleData || isClearingData)
              
              Divider()
                .padding(.vertical, 4)
              
              // Clear all data button
              Button(action: { showClearDataConfirmation = true }) {
                HStack {
                  Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 24)
                  Text("Clear All Data")
                    .font(.headline)
                  
                  if isClearingData {
                    Spacer()
                    ProgressView()
                      .scaleEffect(0.7)
                  }
                }
                .foregroundColor(.red)
                .padding(.vertical, 8)
              }
              .disabled(isExporting || isImporting || isLoadingSampleData || isClearingData)
            }
            
            Divider()
              .padding(.vertical, 8)
            
            // Debug toggle
            Toggle(isOn: $debugModeState) {
              HStack {
                Image(systemName: "ladybug")
                  .foregroundColor(Color.app.primary)
                  .frame(width: 24)
                Text("Debug")
                  .font(.headline)
              }
              .foregroundColor(Color.app.textPrimary)
            }
            .onChange(of: debugModeState) { oldValue, newValue in
              // Set the user default which will be read by the environment value
              UserDefaults.standard.set(newValue, forKey: "debugMode")
            }
            
            Spacer()
            
            // Version info
            VStack(alignment: .leading, spacing: 4) {
              Text("Version \(appVersion)")
                .font(.caption)
                .foregroundColor(Color.app.grey300)
              Text("Build \(buildNumber)")
                .font(.caption)
                .foregroundColor(Color.app.grey300)
            }
            .padding(.bottom, 48)
          }
          .padding(.horizontal, 24)
          .padding(.top, 72)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
          .onAppear {
            // Initialize the state from the environment
            debugModeState = debugMode
          }
          
          // Processing overlay
          if isExporting || isImporting || isLoadingSampleData {
            ZStack {
              Color.black.opacity(0.2)
                .ignoresSafeArea()
              
              VStack(spacing: 16) {
                ProgressView()
                  .scaleEffect(1.2)
                
                Text(progressText)
                  .font(.subheadline)
                  .foregroundColor(.primary)
              }
              .padding(16)
              .background(Color.white)
              .cornerRadius(12)
              .shadow(radius: 5)
            }
            .transition(.opacity)
          }
        }
        .frame(width: 280)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 0)
        
        // Empty space for the rest of the screen
        if isOpen {
          Spacer()
        }
      }
      .offset(x: isOpen ? 0 : -280)
      .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOpen)
    }
    // Alerts and modal sheets
    .alert("Error", isPresented: $showError) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(errorMessage ?? "An unknown error occurred")
    }
    .alert("Success", isPresented: $showSuccess) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(successMessage)
    }
    .fileExporter(
      isPresented: $showExportSheet,
      document: JSONDocument(url: exportURL),
      contentType: .json,
      defaultFilename: "Julia-Data-Export.json"
    ) { result in
      handleExportResult(result)
    }
    .fileImporter(
      isPresented: $isImporting,
      allowedContentTypes: [.json],
      allowsMultipleSelection: false
    ) { result in
      handleImportResult(result)
    }
    .confirmationDialog(
      "Load Sample Data",
      isPresented: $showLoadSampleConfirmation,
      titleVisibility: .visible
    ) {
      Button("Load All Sample Data") {
        loadSampleData(.all)
      }
      
      Button("Load Sample Recipes Only") {
        loadSampleData(.recipes)
      }
      
      Button("Load Sample Pantry Items") {
        loadSampleData(.pantryIngredients)
      }
      
      Button("Load Sample Grocery Items") {
        loadSampleData(.groceryIngredients)
      }
      
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("This will add example data to help you get started with the app.")
    }
    .confirmationDialog(
      "Clear All Data",
      isPresented: $showClearDataConfirmation,
      titleVisibility: .visible
    ) {
      Button("Clear All Data", role: .destructive) {
        clearAllData()
      }
      .tint(Color.app.danger)
      
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("This action cannot be undone. All recipes, ingredients, and other data will be permanently deleted.")
    }
  }
  
  private var progressText: String {
    if isExporting {
      return "Exporting data..."
    } else if isImporting {
      return "Importing data..."
    } else if isLoadingSampleData {
      return "Loading sample data..."
    } else if isClearingData {
      return "Clearing all data..."
    }
    return ""
  }
  
  // MARK: - Import/Export Functions
  
  private func exportData() {
    isExporting = true
    
    Task {
      do {
        // Export the data
        let url = try await ImportExportManager.createRecipesExport(context: context)
          
        // Set UI state
        exportURL = url
        showExportSheet = true
        
      } catch {
        errorMessage = "Export failed: \(error.localizedDescription)"
        showError = true
        isExporting = false
      }
    }
  }
  
  private func importData() {
    isImporting = true
  }
  
  private func handleExportResult(_ result: Result<URL, Error>) {
    isExporting = false
    
    switch result {
    case .success:
      successMessage = "Data exported successfully"
      showSuccess = true
    case .failure(let error):
      errorMessage = "Failed to save file: \(error.localizedDescription)"
      showError = true
    }
  }
  
  private func handleImportResult(_ result: Result<[URL], Error>) {
    switch result {
    case .success(let urls):
      if let url = urls.first {
        importDataFromURL(url)
      } else {
        isImporting = false
      }
    case .failure(let error):
      errorMessage = "Failed to select file: \(error.localizedDescription)"
      showError = true
      isImporting = false
    }
  }
  
  private func importDataFromURL(_ url: URL) {
    guard url.startAccessingSecurityScopedResource() else {
      errorMessage = "Could not access the selected file"
      showError = true
      isImporting = false
      return
    }
    
    // Copy the file to a temporary location
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("import-\(UUID().uuidString).json")
    
    do {
      try FileManager.default.copyItem(at: url, to: tempURL)
      url.stopAccessingSecurityScopedResource()
      
      // Now process the import
      Task {
        do {
          // Import the data
          let count = try await ImportExportManager.importRecipesFile(from: tempURL, context: context)
          
          // Set UI state
          successMessage = "Imported \(count) items successfully"
          showSuccess = true
          isImporting = false
          try? FileManager.default.removeItem(at: tempURL)
        
        } catch {
          // Handle errors on the main actor
          errorMessage = "Import failed: \(error.localizedDescription)"
          showError = true
          isImporting = false
          try? FileManager.default.removeItem(at: tempURL)
          
        }
      }
    } catch {
      url.stopAccessingSecurityScopedResource()
      errorMessage = "Failed to prepare file for import: \(error.localizedDescription)"
      showError = true
      isImporting = false
    }
  }
  
  // MARK: - Sample Data Loading
  
  private func loadSampleData(_ type: SampleDataLoader.SampleDataType) {
    isLoadingSampleData = true
    
    Task {
      do {
        // Load sample data
        let count = try await SampleDataLoader.loadSampleData(
          type: type,
          context: context
        )
        
        // Set UI state
        loadedCount = count
        successMessage = "Added \(count) sample items"
        showSuccess = true
        isLoadingSampleData = false
      
      } catch {
        // Handle errors on the main actor
        errorMessage = "Failed to load sample data: \(error.localizedDescription)"
        showError = true
        isLoadingSampleData = false
        
      }
    }
  }
  
  // MARK: - Clear All Data
  
  private func clearAllData() {
    isClearingData = true
    
    Task {
      do {
        // Clear all data
        try await DataController.clearAllData(in: context)
        
        // Set UI state
        successMessage = "All data has been cleared successfully"
        showSuccess = true
        isClearingData = false
      
      } catch {
        errorMessage = "Failed to clear data: \(error.localizedDescription)"
        showError = true
        isClearingData = false
      }
    }
  }
}

// Document wrapper for file export
struct JSONDocument: FileDocument {
  var url: URL?
  
  static var readableContentTypes: [UTType] { [.json] }
  
  init(url: URL?) {
    self.url = url
  }
  
  init(configuration: ReadConfiguration) throws {
    // We don't need to read the document
    url = nil
  }
  
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    guard let url = url else {
      throw NSError(domain: "ImportExport", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "No file to export"
      ])
    }
    
    return try FileWrapper(url: url)
  }
}

#Preview {
  SettingsDrawer(isOpen: .constant(true))
    .modelContainer(DataController.previewContainer)
    .environment(\.debugMode, true)
}
