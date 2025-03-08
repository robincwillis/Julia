//
//  FloatingActionMenu.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct FloatingActionMenu: View {
    @Binding var selectedImage: UIImage?
    @Binding var showRecipeProcessing: Bool
  
    // State variables for modal presentations
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var isLoading = false
    @State private var photosPickerItem: PhotosPickerItem?
    
    // Error handling
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Loading indicator
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 10)
            } else {
                // Regular menu button
                Menu {
                    Button(action: {
                      showCamera = true
                      showRecipeProcessing = false
                    }) {
                        Label("Camera", systemImage: "camera")
                    }
                  
                    Button(action: {
                      showPhotosPicker = true
                      showRecipeProcessing = false
                    }) {
                      Label("Photos", systemImage: "photo.on.rectangle")
                    }
    
                } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                .menuOrder(.fixed)
                .menuStyle(.borderlessButton)
            }
        }
        // Camera component
        .fullScreenCover(isPresented: $showCamera) {
            Camera(
                image: $selectedImage,
                isPresented: $showCamera
            ) { capturedImage in
                print("Camera returned with image: \(capturedImage.size)")
                // First set the image
                selectedImage = capturedImage
                
                // Then show the processing modal with a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showRecipeProcessing = true
                }
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photosPickerItem, matching: .any(of: [.images, .screenshots, .livePhotos]))
        .onChange(of: photosPickerItem) { _, newValue in
          if let item = newValue {
            loadTransferable(from: item)
          }
        }
        // Error alert
        .alert("Image Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
  
  private func loadTransferable(from item: PhotosPickerItem) {
    print("Starting to load image from PhotosPickerItem")
    isLoading = true
    Task {
      do {
        print("Attempting to load transferable")
        if let data = try await item.loadTransferable(type: Data.self) {
          if let uiImage = UIImage(data: data) {
            print("Successfully loaded image of size: \(uiImage.size)")
            
            // Important: Use MainActor for UI updates
            await MainActor.run {
              self.selectedImage = uiImage
              self.isLoading = false
              print("Image set to selectedImage, preparing to show recipe processing")
              
              // Delay slightly to ensure the image is set before showing the modal
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("Showing recipe processing view")
                self.showRecipeProcessing = true
              }
            }
          } else {
            await MainActor.run {
              self.isLoading = false
              self.errorMessage = "The selected file couldn't be loaded as an image."
              self.showError = true
              print("Error: Could not create UIImage from data")
            }
          }
        } else {
          await MainActor.run {
            self.isLoading = false
            self.errorMessage = "Could not load the selected image."
            self.showError = true
            print("Error: Could not load transferable data")
          }
        }
      } catch {
        print("Failed to load image: \(error)")
        await MainActor.run {
          self.isLoading = false
          self.errorMessage = "Error loading image: \(error.localizedDescription)"
          self.showError = true
        }
      }
    }
  }
}

#Preview {
    struct PreviewWrapper: View {
        @State var image: UIImage? = nil
        @State var showProcessing: Bool = false
        
        var body: some View {
            VStack {
                Spacer()
                FloatingActionMenu(
                    selectedImage: $image,
                    showRecipeProcessing: $showProcessing
                )
            }
        }
    }
    
    return PreviewWrapper()
}
