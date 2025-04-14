import SwiftUI
import SwiftData
import Vision
import Foundation


struct RecipeProcessing: View {
  @ObservedObject var processingState: RecipeProcessingState
  
  // Animation namespace for coordinating animations
  @Namespace private var animation
  
  @State var showHeader = false
  @State var showImage = false
  @State var showStatus = false
  
  var body: some View {
    VStack(spacing: 18) {
      Loader(isLoading: $processingState.isProcessing)
      if showHeader {
        Text(processingState.processingStage.rawValue)
          .font(.headline)
          .padding(.top, 6)
          .transition(.opacity)
          .animation(.easeInOut, value: processingState.isProcessing)
        
      }
      if showImage {
        if let image = processingState.image {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .cornerRadius(12)
            .transition(.opacity)
            .animation(.easeInOut, value: processingState.isProcessing)
        }
      }
      
      if showStatus {
        if (processingState.processingFailed) {
          ProcessingError(
            message: processingState.errorMessage,
            processingState: processingState
          )
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .transition(.opacity)
          .animation(.easeInOut, value: processingState.isProcessing)
        } else {
          Text(processingState.statusMessage)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .transition(.opacity)
            .animation(.easeInOut, value: processingState.isProcessing)
        }
      }

    }
    .onAppear {
      withAnimation (.spring(response: 0.4,dampingFraction: 0.8,blendDuration: 0).delay(0.5))  {
        showHeader = true
      }
      
      withAnimation (.spring(response: 0.4,dampingFraction: 0.8,blendDuration: 0).delay(0.75)) {
        showImage = true
      }
      
      withAnimation (.spring(response: 0.4,dampingFraction: 0.8,blendDuration: 0).delay(1.25))  {
        showStatus = true
      }
    }
    .onChange(of: processingState.processingComplete) { _, newValue in
      if (newValue) {
        
        print("Recipe Processing on Disappear")
        withAnimation (.spring(response: 0.4,dampingFraction: 0.8,blendDuration: 0).delay(3))  {
          showStatus = false
        }
        
        withAnimation (.spring(response: 0.4,dampingFraction: 0.8,blendDuration: 0).delay(0.5)) {
          showImage = false
        }
        
        withAnimation (.spring(response: 0.4,dampingFraction: 0.8,blendDuration: 0).delay(0.75))  {
          showHeader = false
        }
      }
    }
  }
}
  // Enhanced preview to demonstrate the animation
  #Preview {
    struct PreviewWrapper: View {
      let image = UIImage(named: "preview_image") ?? UIImage()
      let processingState = RecipeProcessingState()
      
      var body: some View {
        VStack {
          RecipeProcessing(processingState: processingState)
          
          Button("Toggle Processing") {
            withAnimation {
              processingState.isProcessing.toggle()
              if processingState.isProcessing {
                processingState.image = image
              } else {
                processingState.image = nil
                processingState.processingComplete = true
              }
            }
          }
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
          .padding(.top, 20)
        }
        .padding()
      }
    }
    
    return PreviewWrapper()
  }
