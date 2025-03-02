//
//  Photos.swift
//  Julia
//
//  Created by Claude on 3/2/25.
//

import SwiftUI
import PhotosUI

struct Photos: View {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    var onImageSelected: (UIImage) -> Void
    
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading image...")
                        .padding()
                } else {
                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Select a Photo")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding()
                    }
                }
            }
            .onChange(of: photosPickerItem) { _, newValue in
                if let item = newValue {
                    loadTransferable(from: item)
                }
            }
            .navigationTitle("Choose Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func loadTransferable(from item: PhotosPickerItem) {
        isLoading = true
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = uiImage
                    onImageSelected(uiImage)
                    isLoading = false
                    isPresented = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    struct PhotosPreview: View {
        @State private var isPresented = true
        @State private var selectedImage: UIImage?
        
        var body: some View {
            Photos(isPresented: $isPresented, selectedImage: $selectedImage) { _ in }
        }
    }
    
    return PhotosPreview()
}
