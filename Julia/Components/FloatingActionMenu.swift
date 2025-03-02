//
//  FloatingActionMenu.swift
//  Julia
//
//  Created by Claude on 3/2/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct FloatingActionMenu: View {
    @Binding var selectedImage: UIImage?
    @Binding var showRecipeProcessing: Bool
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    
    var body: some View {
        Menu {
            Button(action: {
                showingCamera = true
            }) {
                Label("Camera", systemImage: "camera")
            }
            
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Label("Photos", systemImage: "photo.on.rectangle")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 10)
        }
        .menuOrder(.fixed)
        .tint(.blue)
        .menuStyle(.borderlessButton)
        
        // Camera component
        .fullScreenCover(isPresented: $showingCamera) {
            Camera(
                image: $selectedImage,
                isPresented: $showingCamera
            ) { capturedImage in
                selectedImage = capturedImage
                showRecipeProcessing = true
            }
        }
        .onChange(of: photosPickerItem) { _, newValue in
            if let newValue {
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        showRecipeProcessing = true
                    }
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