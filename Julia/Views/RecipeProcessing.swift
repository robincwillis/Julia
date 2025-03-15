import SwiftUI
import SwiftData
import Vision
import Foundation

// Create a typealias for the result structure to avoid ambiguity
typealias ProcessingTextResult = TextReconstructorResult

struct RecipeProcessingView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  
  // Make this static so it can be used in property initializers
  static let confidenceThreshold: Double = 0.65
  
  @StateObject private var processingState = RecipeProcessingState()
  
  init(image: UIImage?, text: String?) {
    // Set the image in the processing stateW
    if let image = image {
      _processingState = StateObject(wrappedValue: {
        let state = RecipeProcessingState()
        state.reset() // Ensure state is fully reset
        state.image = image
        state.processingStage = .processing
        // Clear any saved processing results to ensure we process the new image from scratch
        UserDefaults.standard.removeObject(forKey: "latestRecipeProcessingResults")
        return state
      }())
    }
    // Set text
    if let text = text {
      _processingState = StateObject(wrappedValue: {
        let state = RecipeProcessingState()
        state.reset() // Ensure state is fully reset
        state.recognizedText = text.components(separatedBy: .newlines)
        state.processingStage = .processing
        // Clear any saved processing results to ensure we process the new image from scratch
        UserDefaults.standard.removeObject(forKey: "latestRecipeProcessingResults")
        return state
      }())
    }

    
    // Reset all other state variables to default values
    // These will be set properly when the view appears because _processingState is just initializing the StateObject
  }
  
  // Reset all state variables for a new recipe
  private func resetState() {
    processingState.reset()
    reconstructedText = ProcessingTextResult(title: "", reconstructedLines: [], artifacts: [])
    title = ""
    ingredients = []
    instructions = []
    skippedLines = []
    classifiedLines = []
    hasUnsavedChanges = false
    filterType = nil
    showSkippedOnly = false
    sortByConfidence = true
  }
  
  // Check for saved processing results in onAppear
  private func checkForSavedResults() {
    // Only attempt recovery if we haven't already processed text
    if processingState.recognizedText.isEmpty && !isClassifying {
      if let savedData = UserDefaults.standard.dictionary(forKey: "latestRecipeProcessingResults") {
        // Check if the data is recent (within 24 hours)
        if let timestamp = savedData["timestamp"] as? TimeInterval,
           Date().timeIntervalSince1970 - timestamp < 86400 { // 24 hours
          
          if let rawText = savedData["rawText"] as? [String] {
            processingState.recognizedText = rawText
            processingState.processingStage = .completed
          }
          
          // For backward compatibility with older saved data
          if let reconstructedLines = savedData["reconstructedText"] as? [String] {
            reconstructedText = ProcessingTextResult(
              title: savedData["reconstructedTitle"] as? String ?? "",
              reconstructedLines: reconstructedLines,
              artifacts: savedData["reconstructedArtifacts"] as? [String] ?? []
            )
          }
          
          if let savedTitle = savedData["title"] as? String {
            title = savedTitle
          }
          
          if let savedIngredients = savedData["ingredients"] as? [String] {
            ingredients = savedIngredients
          }
          
          if let savedInstructions = savedData["instructions"] as? [String] {
            instructions = savedInstructions
          }
          
          hasUnsavedChanges = true
        }
      }
    }
  }
  
  @State private var classifier = RecipeTextClassifier(confidenceThreshold: RecipeProcessingView.confidenceThreshold)
  
  @State private var skippedLines: [(String, RecipeLineType, Double)] = []
  @State private var classifiedLines: [(String, RecipeLineType, Double)] = []
  @State private var reconstructedText = ProcessingTextResult(title: "", reconstructedLines: [], artifacts: [])
  @State private var title: String = ""
  @State private var ingredients: [String] = []
  @State private var instructions: [String] = []
  
  @State private var isClassifying = false
  @State private var showDismissAlert = false
  @State private var hasUnsavedChanges = false
  
  // State for the classified text view
  @State private var filterType: RecipeLineType? = nil
  @State private var showSkippedOnly: Bool = false
  @State private var sortByConfidence: Bool = true
  
  var body: some View {
    NavigationStack {
      VStack {
        if processingState.processingStage == .processing {
          // Always show the processing view when in processing stage
          processingView
        } else if processingState.recognizedText.isEmpty {
          // Only show the "no text found" view when processing is complete AND text is empty
          noTextFoundView
        } else {
          // Processing complete and we have text
          resultView
        }
      }
      .onAppear {
        // Don't reset state here - that's happening in the init and processImage methods
        
        // Set processing stage if we have an image
        if processingState.image != nil && processingState.recognizedText.isEmpty {
          processingState.processingStage = .processing
          
          // Only process if we're in processing stage and don't have results yet
          processImage()
        } else if processingState.image == nil {
          // Error state - no image provided
          print("Error: RecipeProcessingView appeared without an image")
        }
      }
      .navigationTitle("Process Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .alert("Unsaved Recipe", isPresented: $showDismissAlert) {
        Button("Discard Changes", role: .destructive) {
          dismiss()
        }
        Button("Save Recipe", role: .none) {
          saveRecipe()
        }
        Button("Cancel", role: .cancel) { }
      } message: {
        Text("You have an unsaved recipe. What would you like to do?")
      }
      .toolbar {
        // Cancel with confirmation if needed
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            if hasUnsavedChanges && (!title.isEmpty || !ingredients.isEmpty || !instructions.isEmpty) {
              showDismissAlert = true
            } else {
              dismiss()
            }
          }
        }
        
        // Primary - Save
        ToolbarItem(placement: .primaryAction) {
          if !title.isEmpty || !ingredients.isEmpty || !instructions.isEmpty {
            Button("Save") {
              saveRecipe()
            }
          }
        }
        
      }
    }
  }
  
  // Processing View
  private var processingView: some View {
    VStack(spacing: 20) {
      if let image = processingState.image {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(height: 200)
          .cornerRadius(12)
      }
      
      if isClassifying {
        ProgressView("Classifying recipe text...")
          .padding()
      } else {
        ProgressView("Extracting text from image...")
          .padding()
      }
    }
  }
  
  // Results View
  private var resultView: some View {
    TabView(selection: $processingState.selectedTab) {
      recipeView
        .tabItem {
          Label("Recipe", systemImage: "fork.knife")
        }
        .tag(0)
      
      rawTextDebugView
        .tabItem {
          Label("Raw Text", systemImage: "text.quote")
        }
        .tag(1)
      
      reconstructedTextDebugView
        .tabItem {
          Label("Reconstructed Text", systemImage: "text.badge.checkmark")
        }
        .tag(2)
      
      classifiedTextDebugView
        .tabItem {
          Label("Classified Text", systemImage: "sparkles")
        }
        .tag(3)
    }
    // .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
    .toolbar {
      // Actions
      ToolbarItem(placement: .primaryAction) {
        Menu {
          // Dynamic copy button based on current tab
          switch processingState.selectedTab {
          case 0: // Recipe tab
            Button("Copy Recipe as Text") {
              let recipeText = [
                "# \(title)",
                "",
                "## Ingredients",
                ingredients.joined(separator: "\n"),
                "",
                "## Instructions",
                instructions.joined(separator: "\n")
              ].joined(separator: "\n")
              
              UIPasteboard.general.string = recipeText
            }
            
          case 1: // Raw Text tab
            Button("Copy Raw OCR Text") {
              UIPasteboard.general.string = processingState.recognizedText.joined(separator: "\n")
            }
            
          case 2: // Reconstructed Text tab
            Button("Copy Reconstructed Text") {
              UIPasteboard.general.string = reconstructedText.reconstructedLines.joined(separator: "\n")
            }
            
            if !reconstructedText.title.isEmpty {
              Button("Copy Detected Title") {
                UIPasteboard.general.string = reconstructedText.title
              }
            }
            
            if !reconstructedText.artifacts.isEmpty {
              Button("Copy Artifacts") {
                UIPasteboard.general.string = reconstructedText.artifacts.joined(separator: "\n")
              }
            }
            
          case 3: // Classified Text tab
            Button("Copy All Classified Lines") {
              let classifiedText = classifiedLines.map { line, type, confidence in
                "[\(type.rawValue.uppercased())] (\(String(format: "%.2f", confidence))): \(line)"
              }.joined(separator: "\n")
              
              UIPasteboard.general.string = classifiedText
            }
            
            Button("Copy Only Used Lines") {
              let usedLines = classifiedLines
                .filter { _, _, confidence in confidence >= RecipeProcessingView.confidenceThreshold }
                .map { line, type, confidence in
                  "[\(type.rawValue.uppercased())] (\(String(format: "%.2f", confidence))): \(line)"
                }
                .joined(separator: "\n")
              
              UIPasteboard.general.string = usedLines
            }
            
          default:
            Button("Copy Raw OCR Text") {
              UIPasteboard.general.string = processingState.recognizedText.joined(separator: "\n")
            }
          }
          
          
          
          Button("Re-classify Text") {
            classifyText()
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 14))
            .foregroundColor(.blue)
            .padding(12)
            .frame(width: 30, height: 30)
            .background(Color(red: 0.85, green: 0.92, blue: 1.0))
            .clipShape(Circle())
            .transition(.opacity)
        }
      }
    }
  }
  
  // Result View Tabs
  private var recipeView: some View {
    Form {
      Section("Recipe Title") {
        TextField("Title", text: Binding(
          get: { title },
          set: {
            title = $0
            hasUnsavedChanges = true
            saveProcessingResults()
          }
        ))
        .font(.headline)
        .submitLabel(.done)
      }
      
      Section("Ingredients") {
        ForEach(0..<ingredients.count, id: \.self) { index in
          TextField("Ingredient \(index + 1)", text: Binding(
            get: { ingredients[index] },
            set: {
              ingredients[index] = $0
              hasUnsavedChanges = true
              saveProcessingResults()
            }
          ))
          .submitLabel(.done)
        }
      }
      
      Section("Instructions") {
        ForEach(0..<instructions.count, id: \.self) { index in
          TextField("Step \(index + 1)", text: Binding(
            get: { instructions[index] },
            set: {
              instructions[index] = $0
              hasUnsavedChanges = true
              saveProcessingResults()
            }
          ))
          .submitLabel(.done)
        }
      }
    }
  }
  
  private var rawTextDebugView: some View {
    VStack {
      HStack {
        Text("Raw OCR Text (\(processingState.recognizedText.count) lines)")
          .font(.headline)
      }
      .padding(.horizontal)
      
      List {
        ForEach(Array(processingState.recognizedText.enumerated()), id: \.offset) { index, line in
          VStack(alignment: .leading) {
            HStack(alignment: .top) {
              Text("\(index + 1).")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
                .padding(.top, 2)
              
              Text(line)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
            }
          }
          .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
          .listRowSeparator(.visible)
        }
      }
      .listStyle(.inset)
    }
  }
  
  private var reconstructedTextDebugView: some View {
    VStack(spacing: 16) {
      // Title Section
      if !reconstructedText.title.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Detected Title")
            .font(.headline)
          
          Text(reconstructedText.title)
            .font(.body.bold())
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal)
      }
      
      // Reconstructed Lines Section
      VStack(alignment: .leading, spacing: 8) {
        Text("Reconstructed Text (\(reconstructedText.reconstructedLines.count) lines)")
          .font(.headline)
          .padding(.horizontal)
        
        List {
          ForEach(Array(reconstructedText.reconstructedLines.enumerated()), id: \.offset) { index, line in
            VStack(alignment: .leading) {
              HStack(alignment: .top) {
                Text("\(index + 1).")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .frame(width: 30, alignment: .trailing)
                  .padding(.top, 2)
                
                Text(line)
                  .font(.system(.body, design: .monospaced))
                  .textSelection(.enabled)
              }
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .listRowSeparator(.visible)
          }
        }
        .frame(maxHeight: 300)
        .listStyle(.inset)
      }
      
      // Artifacts Section
      if !reconstructedText.artifacts.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Artifacts (\(reconstructedText.artifacts.count) lines)")
            .font(.headline)
            .padding(.horizontal)
          
          List {
            ForEach(Array(reconstructedText.artifacts.enumerated()), id: \.offset) { index, line in
              VStack(alignment: .leading) {
                HStack(alignment: .top) {
                  Text("\(index + 1).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .trailing)
                    .padding(.top, 2)
                  
                  Text(line)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                }
              }
              .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
              .listRowSeparator(.visible)
            }
          }
          .frame(maxHeight: 200)
          .listStyle(.inset)
        }
      }
    }
    .padding(.horizontal, 8)
  }
  
  private var classifiedTextDebugView: some View {
    VStack {
      // Filter / Sort controls
      
      HStack {
        Menu {
          Button("All Types") { filterType = nil }
          Divider()
          ForEach(RecipeLineType.allCases, id: \.self) { type in
            Button(type.rawValue.capitalized) { filterType = type }
          }
        } label: {
          Label(
            filterType == nil ? "Filter: All" : "Filter: \(filterType!.rawValue.capitalized)",
            systemImage: "line.3.horizontal.decrease.circle"
          )
        }
        .font(.caption)
        
        Toggle("Skipped Only", isOn: $showSkippedOnly)
          .toggleStyle(.button)
          .font(.caption)
        
        Spacer()
        
        Button(sortByConfidence ? "Sort: Confidence" : "Sort: Order") {
          withAnimation {
            sortByConfidence.toggle()
          }
        }
        .font(.caption)
      }
      .padding(.horizontal)
      
      List {
        // Filter and sort the classified lines
        let filteredLines = classifiedLines.enumerated().filter { index, item in
          let (_, type, confidence) = item
          let typeMatch = filterType == nil || type == filterType
          let confidenceMatch = !showSkippedOnly || confidence < RecipeProcessingView.confidenceThreshold
          return typeMatch && confidenceMatch
        }.sorted { a, b in
          if sortByConfidence {
            return a.element.2 > b.element.2 // Sort by confidence descending
          } else {
            return a.offset < b.offset // Sort by original order
          }
        }
        
        if filteredLines.isEmpty {
          Text("No matching lines")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        } else {
          Section("Classified Lines (\(filteredLines.count) of \(classifiedLines.count))") {
            ForEach(filteredLines, id: \.offset) { index, lineData in
              let (text, type, confidence) = lineData
              VStack(alignment: .leading) {
                Text(text)
                  .font(.body)
                  .foregroundColor(confidence >= RecipeProcessingView.confidenceThreshold ? .primary : .secondary)
                
                HStack {
                  Label(type.rawValue.capitalized, systemImage: typeIcon(for: type))
                    .foregroundColor(typeColor(for: type))
                  
                  Spacer()
                  
                  Text("Confidence: \(String(format: "%.2f", confidence))")
                    .font(.caption2)
                    .foregroundColor(confidence >= RecipeProcessingView.confidenceThreshold ? .green : .red)
                }
                .font(.caption)
                
                if confidence < RecipeProcessingView.confidenceThreshold {
                  HStack {
                    Button("Add as Ingredient") {
                      ingredients.append(text)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    
                    Button("Add as Instruction") {
                      instructions.append(text)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                  }
                  .padding(.top, 2)
                }
              }
              .padding(.vertical, 4)
            }
          }
        }
      }
    }
  }
  
  private var noTextFoundView: some View {
    VStack(spacing: 24) {
      if let image = processingState.image {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(height: 200)
          .cornerRadius(12)
      }
      
      VStack(spacing: 16) {
        Image(systemName: "text.magnifyingglass")
          .font(.system(size: 70))
          .foregroundColor(.secondary)
        
        Text("No Text Detected")
          .font(.headline)
        
        Text("We couldn't find any text in this image. Try another image with clear, visible text.")
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal)
      }
      
      Button("Try Again") {
        dismiss()
      }
      .buttonStyle(.borderedProminent)
      .padding(.top)
    }
    .padding()
  }
  

  //  Fuctions
  private func typeIcon(for type: RecipeLineType) -> String {
    switch type {
    case .title: return "text.badge.star"
    case .ingredient: return "list.bullet"
    case .instruction: return "1.square"
    case .unknown: return "questionmark.circle"
    }
  }
  
  private func typeColor(for type: RecipeLineType) -> Color {
    switch type {
    case .title: return .blue
    case .ingredient: return .green
    case .instruction: return .orange
    case .unknown: return .gray
    }
  }
  
  private func processImage() {
    guard let image = processingState.image else {
      return
    }
    
    // Make sure we're in processing state
    processingState.processingStage = .processing
    
    // Clear UserDefaults but don't reset state yet
    UserDefaults.standard.removeObject(forKey: "latestRecipeProcessingResults")
    
    // Start OCR processing
    Task {
      let recognizedText = await TextRecognitionService.shared.recognizeText(from: image)
      
      await MainActor.run {
        // Only now, once we have results, update the processing state
        processingState.recognizedText = recognizedText
        processingState.processingStage = .completed
        
        // Auto-classify if we have text
        if !recognizedText.isEmpty {
          // These should be reset before classification
          reconstructedText = ProcessingTextResult(title: "", reconstructedLines: [], artifacts: [])
          title = ""
          ingredients = []
          instructions = []
          skippedLines = []
          classifiedLines = []
          
          classifyText()
        }
      }
    }
  }
  
  private func classifyText() {
    // Skip empty lines
    let filteredText = processingState.recognizedText.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    isClassifying = true
    
    // Process on background thread
    Task {
      // Step 1: Reconstruct the text
      let reconstructed = await reconstructTextAsync(filteredText)
      
      // Step 2: Classify the reconstructed text
      let processed = await classifier.processRecipeTextAsync(reconstructed.reconstructedLines)
      
      // Update UI on main thread
      await MainActor.run {
        reconstructedText = reconstructed
        // Use title from reconstructor if available, otherwise use the one from classifier
        title = !reconstructed.title.isEmpty ? reconstructed.title : processed.title
        ingredients = processed.ingredients
        instructions = processed.instructions
        skippedLines = processed.skipped
        classifiedLines = processed.classified
        isClassifying = false
        hasUnsavedChanges = true
        
        // Auto-save processing results to UserDefaults for recovery
        saveProcessingResults()
      }
    }
  }
  
  private func reconstructTextAsync(_ lines: [String]) async -> ProcessingTextResult {
    return await withCheckedContinuation { continuation in
      DispatchQueue.global().async {
        let reconstructed = RecipeTextReconstructor.reconstructText(from: lines)
        continuation.resume(returning: reconstructed)
      }
    }
  }
  
  private func saveProcessingResults() {
    // Create a dictionary to store all the processing results
    let processingData: [String: Any] = [
      "rawText": processingState.recognizedText,
      "reconstructedText": reconstructedText.reconstructedLines,
      "reconstructedTitle": reconstructedText.title,
      "reconstructedArtifacts": reconstructedText.artifacts,
      "title": title,
      "ingredients": ingredients,
      "instructions": instructions,
      "timestamp": Date().timeIntervalSince1970
    ]
    
    // Save to UserDefaults
    UserDefaults.standard.set(processingData, forKey: "latestRecipeProcessingResults")
  }
  
  private func saveRecipe() {
    let recipe = Recipe(
      title: title,
      ingredients: [],
      instructions: instructions,
      rawText: processingState.recognizedText
    )
    
    // Add ingredients
    for ingredientText in ingredients {
      if let ingredient = IngredientParser.fromString(input: ingredientText, location: .recipe) {
        recipe.ingredients.append(ingredient)
      }
    }
    
    // Save to context
    context.insert(recipe)
    
    // Clear unsaved changes flag
    hasUnsavedChanges = false
    
    // Remove from UserDefaults since we've saved properly
    UserDefaults.standard.removeObject(forKey: "latestRecipeProcessingResults")
    
    dismiss()
  }
}

// Make classifier work async
extension RecipeTextClassifier {
  func processRecipeTextAsync(_ text: [String]) async -> (title: String, ingredients: [String], instructions: [String], skipped: [(String, RecipeLineType, Double)], classified: [(String, RecipeLineType, Double)]) {
    return await withCheckedContinuation { continuation in
      DispatchQueue.global().async {
        let result = self.processRecipeText(text)
        continuation.resume(returning: result)
      }
    }
  }
}

// Helper extension
extension Collection {
  var isNotEmpty: Bool {
    return !isEmpty
  }
}

#Preview {
  let image = UIImage(named: "julia") ?? UIImage()
  //let text = nil
  
  return RecipeProcessingView(image: image, text:nil)
    .modelContainer(DataController.previewContainer)
}
