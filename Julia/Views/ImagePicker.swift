//
//  ImagePicker.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import PhotosUI
import Vision
import AVFoundation


struct ResultsDebug: View {
  var recognizedText : [String]
  var image: UIImage?
  var clearState: () -> Void
  
  var body: some View {
    VStack {
      Button("Clear State and Start Over") {
        clearState()
      }
      .padding()
      .background(.red)
      .foregroundColor(.white)
      .cornerRadius(12)
      List(recognizedText, id: \.self) {
        Text($0)
      }
    }
    if let image = image {
      Image(uiImage: image)
        .resizable()
        .scaledToFit()
    }
  }
}

struct CameraView: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  @Binding var isPresented: Bool
  var onImageCaptured: (UIImage) -> Void
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = .camera
    return picker
  }
  
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: CameraView
    
    init(_ parent: CameraView) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let image = info[.originalImage] as? UIImage {
        parent.image = image
        parent.onImageCaptured(image)
      }
      parent.isPresented = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.isPresented = false
    }
  }
}

// AppStorage for persisting processing state
class PhotoProcessingState: ObservableObject {
  @Published var image: UIImage?
  @Published var recognizedText: [String] = []
  @Published var processingStage: ProcessingStage = .notStarted
  @Published var selectedTab = 0
  
  enum ProcessingStage {
    case notStarted
    case processing
    case completed
  }
  
  func reset() {
    image = nil
    recognizedText = []
    processingStage = .notStarted
    selectedTab = 0
  }
}

struct ImagePicker: View {
  @Binding var showModal: Bool
  @StateObject private var processingState = PhotoProcessingState()
  
  @State private var showingCameraPermissionAlert = false
  @State private var showingCamera = false
  @State private var selectedItem: PhotosPickerItem? = nil
  
  // Use direct @State properties instead of computed properties
  @State private var selectedTab = 0
  
  var showCameraDirectly: Bool = false
  
  var body: some View {
    VStack {
      // Check if we should show the camera directly
      if showCameraDirectly && processingState.recognizedText.isEmpty {
        CameraView(image: $processingState.image, isPresented: $showingCamera) { capturedImage in
          handleCapturedImage(capturedImage)
        }
        .ignoresSafeArea()
        .onAppear {
          showingCamera = true
        }
      } else if !processingState.recognizedText.isEmpty {
        TabView(selection: $processingState.selectedTab) {
          ProcessOCRView(ocrText: processingState.recognizedText)
            .tabItem {
              Label("Classify", systemImage: "square.and.pencil")
            }
            .tag(0)
          
          AddRecipe(recognizedText: processingState.recognizedText)
            .tabItem {
              Label("Editor", systemImage: "doc.text")
            }
            .tag(1)
          
          ResultsDebug(recognizedText: processingState.recognizedText, image: processingState.image, clearState: clearState)
            .tabItem {
              Label("Raw Text", systemImage: "list.bullet")
            }
            .tag(2)
        }
      } else {
        Spacer()
        
        if processingState.processingStage == .processing {
          ProgressView("Processing Image...")
        } else {
          imagePickerContent
        }
      }
    }
    .onAppear {
      // Set up the onChange effect manually
      handleSelectionChanges()
    }
    .fullScreenCover(isPresented: $showingCamera) {
      CameraView(image: $processingState.image, isPresented: $showingCamera) { capturedImage in
        handleCapturedImage(capturedImage)
      }
      .ignoresSafeArea()
    }
    .alert(
      "Camera Access Required",
      isPresented: $showingCameraPermissionAlert
    ) {
      Button("Open Settings") {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsURL)
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Please grant camera access in Settings to take photos for recipe recognition.")
    }
  }
  
  // MARK: - Change handling
  private func handleSelectionChanges() {
    if let item = selectedItem {
      handleSelectedItem(item)
    }
  }
  
  var imagePickerContent: some View {
    VStack(spacing: 20) {
      PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
        HStack {
          Image(systemName: "photo.on.rectangle")
          Text("Select from Photos")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
      }
      .onChange(of: selectedItem) { oldValue, newValue in
        if let item = newValue {
          handleSelectedItem(item)
        }
      }
      
      Button {
        let cameraAuthorized = checkCameraPermission()
        if cameraAuthorized {
          showingCamera = true
        } else {
          showingCameraPermissionAlert = true
        }
      } label: {
        HStack {
          Image(systemName: "camera")
          Text("Take a Photo")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.green)
        .foregroundColor(.white)
        .cornerRadius(12)
      }
    }
    .padding(.horizontal)
  }
  
  private func handleSelectedItem(_ item: PhotosPickerItem) {
    Task {
      processingState.processingStage = .processing
      defer { processingState.processingStage = .notStarted }
      
      if let data = try? await item.loadTransferable(type: Data.self),
         let uiImage = UIImage(data: data) {
        processingState.image = uiImage
        processImage(uiImage)
      }
    }
  }
  
  private func handleCapturedImage(_ capturedImage: UIImage) {
    processingState.processingStage = .processing
    processImage(capturedImage)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      processingState.processingStage = .notStarted
    }
  }
  
  private func clearState() {
    processingState.reset()
    selectedItem = nil
  }
  
  private func processImage(_ image: UIImage) {
    recognizeText(from: image) { recognizedStrings in
      processingState.recognizedText = recognizedStrings
      processingState.processingStage = .completed
    }
  }
}

func checkCameraPermission() -> Bool {
  switch AVCaptureDevice.authorizationStatus(for: .video) {
  case .authorized:
    return true
  case .notDetermined:
    // Request permission synchronously
    var isAuthorized = false
    let semaphore = DispatchSemaphore(value: 0)
    
    AVCaptureDevice.requestAccess(for: .video) { granted in
      isAuthorized = granted
      semaphore.signal()
    }
    
    // Wait for permission result with a timeout
    _ = semaphore.wait(timeout: .now() + 1.0)
    return isAuthorized
    
  case .denied, .restricted:
    return false
  @unknown default:
    return false
  }
}

func recognizeText(from image: UIImage, completion: @escaping ([String]) -> Void) {
  guard let cgImage = image.cgImage else {
    completion([])
    return
  }
  let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
  let request = VNRecognizeTextRequest { (request, error) in
    guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
      completion([])
      return
    }
    let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string
      
    }
    print(recognizedStrings)
    completion(recognizedStrings)
  }
  request.recognitionLevel = .accurate
  
  do {
    try requestHandler.perform([request])
  } catch {
    print("Unable to perform the requests: \(error).")
    completion([])
  }
  
}


#Preview {
  @State var showModal = true
  return ImagePicker(showModal: $showModal)
}
