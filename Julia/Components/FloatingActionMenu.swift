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
  @Binding var extractedRecipeData: RecipeData?
  @Binding var showRecipeProcessing: Bool
  
  // State variables for modal presentations
  @State private var showCamera = false
  @State private var showPhotosPicker = false
  @State private var showRecipeURLImport = false
  @State private var showRecipeTextImport = false
  @State private var isLoading = false
  @State private var photosPickerItem: PhotosPickerItem?
  
  // State variables for menu control
  @State private var animationTriggered = false
  @State var isExpanded: Bool = false

  
  // Error handling
  @State private var showError = false
  @State private var showDone = false
  @State private var doneMessage = ""
  @State private var errorMessage = ""
  @State private var localError = ""
  
  var body: some View {
    ZStack {
      if isExpanded {
        Color.black.opacity(0.05)
          .ignoresSafeArea()
          .transition(.opacity)
          .animation(.easeInOut(duration: 0.2), value: isExpanded)
          .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
              isExpanded = false
            }
          }
      }
   
    VStack {
      Spacer()
      
      HStack {
        Spacer()
        
        // The menu container
        VStack(alignment: .trailing, spacing: 12) {
          // Menu items - only show when expanded
          if animationTriggered {
            VStack(alignment: .trailing, spacing: 10) {
              // FROM Text
              menuItem(
                icon: "text.quote",
                text: "Text",
                action: resetStateAndOpenTextImport
              )
              .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom))
                  .combined(with: .offset(y: 20)),
                removal: .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom))
              ))
              .slideInFromLeft(isVisible: isExpanded, delay: 0.4)
              
              // FROM NOTES
              menuItem(
                icon: "note.text",
                text: "Notes",
                action: resetStateAndOpenTextImport
              )
              .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom))
                  .combined(with: .offset(y: 20)),
                removal: .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom))
              ))
              .slideInFromLeft(isVisible: isExpanded, delay: 0.3)
              
              // FROM WEBSITE
              menuItem(
                icon: "globe",
                text: "Website",
                action: resetStateAndOpenURLImport
              )
              .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom))
                  .combined(with: .offset(y: 20)),
                removal: .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom))
              ))
              .slideInFromLeft(isVisible: isExpanded, delay: 0.2)
              
              // FROM PHOTOS
              menuItem(
                icon: "photo.on.rectangle",
                text: "Photos",
                action: resetStateAndOpenPhotosPicker
              )
              .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom))
                  .combined(with: .offset(y: 20)),
                removal: .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom))
              ))
              .slideInFromLeft(isVisible: isExpanded, delay: 0.1)
              
              // FROM CAMERA
              menuItem(
                icon: "camera",
                text: "Camera",
                action: resetStateAndOpenCamera
              )
              .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom))
                  .combined(with: .offset(y: 20)),
                removal: .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom))
              ))
              .slideInFromLeft(isVisible: isExpanded, delay: 0)
            }
            .padding(.bottom, 12)
          }
          
          // Main action button - always positioned at the same spot
          ZStack {
            Button(action: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isExpanded.toggle()
                
                if !animationTriggered {
                  animationTriggered = true
                }
              }
            }) {
              Image(systemName: isExpanded ? "xmark" : "sparkles")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 10)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0 : 1)
            
            // Loading indicator
            if isLoading {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 10)
            }
          }
        }
        .padding(.trailing, 24)
      }
    }
    }
    //.zIndex(10)
    // URL Import Sheet
    .sheet(isPresented: $showRecipeURLImport) {
      RecipeURLImportView(
        showRecipeProcessing: $showRecipeProcessing,
        selectedText: $selectedText,
        extractedRecipeData: $extractedRecipeData
      )
      .presentationDetents([.height(250), .medium])
      .background(.background.secondary)
      .presentationDragIndicator(.hidden)

      
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
  
  
  // Menu item
  @ViewBuilder
  private func menuItem(icon: String, text: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 16))
          .foregroundColor(.blue)
          .frame(width: 24, height: 24)
        
        Text(text)
          .font(.system(size: 16))
          .foregroundColor(.primary)
        
      }
      //.frame(width: 100)
      .padding(.vertical, 12)
      .padding(.horizontal, 16)
      .background(Color.white)
      .cornerRadius(16)
      .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    .buttonStyle(PlainButtonStyle())
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


// Animation extension
extension View {
  func scaleAndFade(isVisible: Bool, delay: Double = 0) -> some View {
    self
      .opacity(isVisible ? 1 : 0)
      .scaleEffect(isVisible ? 1 : 0.8, anchor: .bottomTrailing)
      .animation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0).delay(delay), value: isVisible)
  }
  
  func slideInFromLeft(
    isVisible: Bool,
    delay: Double = 0,
    distance: CGFloat = -150
  ) -> some View {
    self
      .opacity(isVisible ? 1 : 0)
      .offset(x: isVisible ? 0 : distance)
      .animation(
        .spring(
          response: 0.4,
          dampingFraction: 0.8,
          blendDuration: 0
        )
        .delay(delay),
        value: isVisible
      )
  }
}


#Preview {
    struct PreviewWrapper: View {
      @State var image: UIImage? = nil
      @State var text: String? = nil
      @State var showProcessing: Bool = false
      @State var extractedRecipeData: RecipeData? = nil
        
      var body: some View {
        
        FloatingActionMenu(
          selectedImage: $image,
          selectedText: $text,
          extractedRecipeData: $extractedRecipeData,
          showRecipeProcessing: $showProcessing
        )
      }
    }
    
    return PreviewWrapper()
}
