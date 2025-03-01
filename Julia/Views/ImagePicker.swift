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

struct ImagePicker: View {
  @Binding var showModal: Bool
  @State var recognizedText: [String] = []
  @State private var selectedTab = 0
  
  @State private var isProcessing = false
  @State private var showingCameraPermissionAlert = false
  
  
  @State private var image: UIImage?
  @State private var selectedItem: PhotosPickerItem? = nil
  
  var body: some View {
    VStack {
      
      if !recognizedText.isEmpty {
        
        TabView(selection: $selectedTab) {
          
          ProcessOCRView(ocrText: recognizedText)
            .tabItem {
              Label("Classify", systemImage: "square.and.pencil")
            }
            .tag(0)
          
          AddRecipe(recognizedText: recognizedText)
            .tabItem {
              Label("Editor", systemImage: "doc.text")
            }
            .tag(1)
          
          ResultsDebug(recognizedText: recognizedText, image: image, clearState: clearState)
            .tabItem {
              Label("Raw Text", systemImage: "list.bullet")
            }
            .tag(2)
        }
        
        
      } else {
        Spacer()
        
        if isProcessing {
          ProgressView("Processing Image...")
        }
        
        
        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
          Text("Select from Photos")
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .onChange(of: selectedItem) { oldItem, newItem in
          Task {
            isProcessing = true
            defer { isProcessing = false }
            
            if let data = try? await newItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
              image = uiImage
              processImage(uiImage)
            }
          }
        }
        .alert("Camera Access Required", isPresented: $showingCameraPermissionAlert) {
          Button("Open Settings", role: .none) {
            // Open app settings
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(settingsURL)
            }
          }
          Button("Cancel", role: .cancel) {}
        } message: {
          Text("Please grant camera access in Settings to take photos for recipe recognition.")
        }
      }
    }
  }
  
  
  private func clearState() {
    image = nil
    recognizedText = []
    selectedItem = nil
  }
  
  private func processImage(_ image: UIImage) {
    recognizeText(from: image) { recognizedStrings in
      recognizedText = recognizedStrings
    }
  }
}

func checkCameraPermission() -> Bool {
  switch AVCaptureDevice.authorizationStatus(for: .video) {
  case .authorized:
    return true
  case .notDetermined:
    // Request permission
    AVCaptureDevice.requestAccess(for: .video) { granted in
      // Handle async response if needed
    }
    return false
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
  let rawText = ["88", "GREEN SALAD", "with Dill & Lemon Dressing", "Serves 4 to 6", "FOR THE DRESSING:", "3 tablespoons (45 milliliters) lemon", "juice (from 1/2 large lemons)", "½ teaspoon kosher salt", "¼/ cup (60 milliliters) extra-virgin", "olive oil", "FOR THE SALAD:", "1 small head romaine lettuce", "1 small head green-leaf lettuce", "¼4 cup (15 grams) roughly chopped", "fresh dill", "2 tablespoons finely chopped", "fresh chives", "This is my version of a classic Greek dish, marouli salata, which simply", "means lettuce salad. It\'s often served with sliced raw scallions but I", "substitute chives because they have a less overpowering bite. The", "freshness of the dill with the tangy lemon makes a great palate cleanser", "atter a heavy or particularly rich meal.", "Make the dressing: In a small bowl or cup, combine the lemon juice", "and salt and mix well to dissolve. Add the oil and whisk with a fork until", "emulsified.", "Make the salad: Remove any brown or wilted outer leaves from both", "heads of lettuce. Cut the lettuce crosswise into ribbons about ½2 inch", "(12 millimeters) thick. Rinse in cold water, drain, and dry in a salad spinner.", "Place the lettuce in a large serving bowl. Add the dill and chives and", "toss to combine. Drizzle with the dressing, toss well, and serve."]
  return ImagePicker(showModal: $showModal, recognizedText:rawText)
}
