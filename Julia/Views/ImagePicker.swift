//
//  ImagePicker.swift
//  Julia
//
//  Created by Claude on 3/2/25.
//

import SwiftUI
import UIKit

struct ImagePicker: View {
    @Binding var showModal: Bool
    @State private var selectedImage: UIImage?
    
    // Source selection from NavigationView
    var showCamera: Bool = false
    var showPhotoLibrary: Bool = false
    
    // Internal state for modal presentation
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingRecipeProcessing = false
    
    init(showModal: Binding<Bool>, showCamera: Bool = false, showPhotoLibrary: Bool = false) {
        self._showModal = showModal
        self.showCamera = showCamera
        self.showPhotoLibrary = showPhotoLibrary
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if selectedImage != nil {
                    // Image has been selected, show processing
                    RecipeProcessingView(image: selectedImage!)
                } else if !showCamera && !showPhotoLibrary {
                    // Main menu options
                    mainPickerMenu
                } else {
                    // Empty container for modal presentation
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showModal = false
                    }
                }
            }
            .task {
                // Handle direct navigation requests as a priority task
                // Using task instead of onAppear gives more reliable results
                if showCamera {
                    // Small delay to ensure view is fully loaded
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    showingCamera = true
                } else if showPhotoLibrary {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    showingPhotoLibrary = true
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                Camera(
                    image: $selectedImage,
                    isPresented: $showingCamera
                ) { capturedImage in
                    handleSelectedImage(capturedImage)
                }
            }
            .fullScreenCover(isPresented: $showingPhotoLibrary) {
                Photos(
                    isPresented: $showingPhotoLibrary,
                    selectedImage: $selectedImage
                ) { selectedImage in
                    handleSelectedImage(selectedImage)
                }
            }
        }
    }
    
    private var mainPickerMenu: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "text.viewfinder")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.8))
                .padding(.bottom, 20)
                        
            Text("Add a Recipe")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
                
            Text("Take a photo of a recipe or select one from your photo library")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            
            Button {
                showingCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera")
                        .font(.title3)
                    Text("Take a Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Button {
                showingPhotoLibrary = true
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                    Text("Choose from Photos")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func handleSelectedImage(_ image: UIImage) {
        selectedImage = image
    }
}

#Preview {
    @State var showModal = true
    return ImagePicker(showModal: $showModal)
}
