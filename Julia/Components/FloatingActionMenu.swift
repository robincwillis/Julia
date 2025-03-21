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
  @Binding var selectedText: String?
  @Binding var showRecipeProcessing: Bool
  
  // State variables for modal presentations
  @State private var showCamera = false
  @State private var showPhotosPicker = false
  @State private var showRecipeURLImport = false
  @State private var showRecipeTextImport = false
  @State private var isLoading = false
  @State private var photosPickerItem: PhotosPickerItem?
  
  // Error handling
  @State private var showError = false
  @State private var showDone = false
  @State private var doneMessage = ""
  @State private var errorMessage = ""
  @State private var localError = ""
  
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
            Label("From Camera", systemImage: "camera")
          }
          
          Button(action: {
            showPhotosPicker = true
            showRecipeProcessing = false
          }) {
            Label("From Photos", systemImage: "photo.on.rectangle")
          }
          
          Button(action: {
            showRecipeURLImport = true
            showRecipeProcessing = false
          }) {
            Label("From Website", systemImage: "globe")
          }
          
          Button(action: {
            showRecipeTextImport = true
            showRecipeProcessing = false
          }) {
            Label("From Notes", systemImage: "text.quote")
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
    
    // URL Import Sheet
    .sheet(isPresented: $showRecipeURLImport) {
      RecipeURLImportView(
        showRecipeProcessing: $showRecipeProcessing
      )
    }
    .interactiveDismissDisabled()
    // Text Import Sheet
    .sheet(isPresented: $showRecipeTextImport) {
      RecipeTextImportView(
        recipeText: $selectedText,
        showRecipeProcessing: $showRecipeProcessing
      )
    }
    .interactiveDismissDisabled()
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
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          showRecipeProcessing = true
        //}
      }
      .ignoresSafeArea()
    }
    // Photos Picker
    .photosPicker(
      isPresented: $showPhotosPicker,
      selection: $photosPickerItem,
      matching: .images
      //preferredItemEncoding: .automatic
    )
    .onChange(of: photosPickerItem) { _, newValue in
      self.isLoading = true
      Task {
        do {
          guard let newItem = newValue else {
            self.isLoading = false
            return
          }
          
          // Use try instead of try? to allow errors to propagate to the catch block
          let imageData = try await newItem.loadTransferable(type: Data.self)
          
          guard let imageData else {
            self.errorMessage = "Failed to load image data"
            self.showError = true
            self.isLoading = false
            return
          }
          
          guard let inputImage = UIImage(data: imageData) else {
            self.errorMessage = "Failed to create image from data"
            self.showError = true
            self.isLoading = false
            return
          }
          
          self.selectedImage = inputImage
          self.isLoading = false
          Task { @MainActor in
            self.showRecipeProcessing = true
          }
          
        } catch {
          self.errorMessage = "Error loading image: \(error.localizedDescription)"
          self.showError = true
          self.isLoading = false
        }
      }
    }
    .onChange(of: showRecipeProcessing) { _, newValue in
      if !newValue {
        reset()
      }
    }

    // Error alert
    .alert("Image Error", isPresented: $showError) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("errorMessage: \(self.errorMessage) localError:\(self.localError)")
    }
  }
  
  private func reset() {
    UserDefaults.standard.removeObject(forKey: "latestRecipeProcessingResults")
    selectedImage = nil
    selectedText = nil
    photosPickerItem = nil
  }
  
  private func resetStateAndOpenCamera() {
    reset()
    showCamera = true
  }
  
  private func resetStateAndOpenPhotosPicker() {
    reset()
    showPhotosPicker = true
  }
  
  private func resetStateAndOpenURLImport() {
    reset()
    showRecipeURLImport = true
  }
  
  private func resetStateAndOpenTextImport() {
    reset()
    showRecipeTextImport = true
  }
  
}


#Preview {
    struct PreviewWrapper: View {
      @State var image: UIImage? = nil
      @State var text: String? = nil
      @State var showProcessing: Bool = false
        
        var body: some View {
            VStack {
                Spacer()
                FloatingActionMenu(
                    selectedImage: $image,
                    selectedText: $text,
                    showRecipeProcessing: $showProcessing
                )
            }
        }
    }
    
    return PreviewWrapper()
}
