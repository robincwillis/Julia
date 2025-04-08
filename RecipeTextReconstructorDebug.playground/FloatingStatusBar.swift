//
//  FloatingStatusBar.swift
//  Julia
//
//  Created by Robin Willis on 4/7/25.
//

import SwiftUI
import UIKit


struct FloatingStatusBar: View {
  
  @Binding var isVisible: Bool
  @Binding var detectedURL: String?
  
  @State private var offsetY: CGFloat = 100
  @State private var dismissTimer: Timer?
  
  var onImportURL: (String) -> Void
  
  // Auto-dismiss after seconds (0 = no auto-dismiss)
  var dismissAfter: Double = 0
  
  
  var body: some View {
    ZStack {
      if isVisible {
        Color.black.opacity(0.05)
          .ignoresSafeArea()
          .transition(.opacity)
          .animation(.easeInOut(duration: 0.2), value: isVisible)
          .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
              isVisible = false
            }
          }
        if (detectedURL != nil) {
          HStack(spacing: 12) {
            // Icon
            Image(systemName: "list.clipboard")
              .font(.system(size: 18))
              .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
              .padding(12)
              .frame(width: 30, height: 30)
              //.background(Color(red: 0.85, green: 0.92, blue: 1.0))
            
            // URL preview text
            
            VStack (alignment: .leading) {
              Text("Website Avaliable")
              Text("On your clipboard")
              
            }
            
            //.font(.system(size: 15, weight: .medium))
            //.lineLimit(1)
            
            
            Spacer()
            
            Button(action: {
              if let url = detectedURL {
                onImportURL(url)
                dismiss()
              }
            }) {
              Text("Import")
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(.blue)
                .cornerRadius(12)
                .foregroundColor(.white)
            }
            
            
          }
          
          .padding(24)
          //.offset(y: offsetY)
          .background(.white)
          .cornerRadius(24)
          .animation(.spring(response: 0.4, dampingFraction: 0.7), value: offsetY)
          //.animation(.easeInOut, value: isVisible)
          .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
          .padding(.horizontal, 24)
        }
      }
    }
    .onChange(of: detectedURL) { _, newValue in
      // Show bar when URL is detected
      if newValue != nil {
        //show()
      } else {
        //dismiss()
      }
    }
    .onDisappear {
      // dismissTimer?.invalidate()
    }
    
  }
  
  private func show() {
    // Reset any existing timer
    dismissTimer?.invalidate()
    
    // Show the bar with animation
    withAnimation {
      isVisible = true
      offsetY = 0
    }
    
    // Set up auto-dismiss if enabled
    if dismissAfter > 0 {
      dismissTimer = Timer.scheduledTimer(withTimeInterval: dismissAfter, repeats: false) { _ in
        dismiss()
      }
    }
  }
  
  private func dismiss() {
    // Dismiss the bar with animation
    withAnimation {
      offsetY = 100
      
      // Set visibility to false after animation completes
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        isVisible = false
      }
    }
    
    // Clear the timer
    dismissTimer?.invalidate()
    dismissTimer = nil
  }
}


#Preview {
  
  PreviewWrapper()
  
  
}

// Helper struct to manage state for the preview
private struct PreviewWrapper: View {
  @State private var isVisible = true
  @State private var detectedURL: String? = "https://robincwillis.com"
  
  var body: some View {
    ZStack {
      Button(action: {
        withAnimation {
          isVisible.toggle()
        }
      }) {
        Label("Toggle", systemImage: "xmark.circle.fill")
          .font(.system(size: 16))
          .padding(24)
          .background(.blue)
          .foregroundColor(.white)
      }

          
      FloatingStatusBar(
        isVisible: $isVisible,
        detectedURL: $detectedURL,
        onImportURL: { url in
          print(url)
        }
      )
    }
  }
}

// ClipboardURLDetector
