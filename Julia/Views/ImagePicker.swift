//
//  ImagePicker.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import PhotosUI
import Vision

struct ImagePicker: View {
    @Binding var showModal: Bool
    
    @State private var image: UIImage?
    @State private var recognizedText: [String] = []
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("Take a photo of a recipe")
                    .foregroundColor(.gray)
            }
            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                Text("Take a photo")
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .onChange(of: selectedItem) { oldItem, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        image = uiImage
                        processImage(uiImage)
                    }
                }
            }
            
            List(recognizedText, id: \.self) {
                Text($0)
            }
            
            Spacer()
            
            Button("Clear State and Start Over") {
                clearState()
            }
            .padding()
            .background(.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            
            Button(action: {
                showModal = false
            }) {
                Text("Close")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
            
            
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


//#Preview {
//  @State var showModal = true
//  ImagePicker(showModal: $showModal)
//}
