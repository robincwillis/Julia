//
//  Camera.swift
//  Julia
//
//  Created by Claude on 3/2/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct Camera: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.modalPresentationStyle = .fullScreen
        
        // Enable camera controls
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        picker.showsCameraControls = true
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: Camera
        
        init(_ parent: Camera) {
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

// Helper for checking camera permissions
func checkCameraPermission() async -> Bool {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        return true
    case .notDetermined:
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    case .denied, .restricted:
        return false
    @unknown default:
        return false
    }
}

#Preview {
    struct CameraPreview: View {
        @State private var image: UIImage?
        @State private var isPresented = true
        
        var body: some View {
            Camera(image: $image, isPresented: $isPresented) { _ in }
        }
    }
    
    return CameraPreview()
}
