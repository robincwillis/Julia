//
//  ProcessingError.swift
//  Julia
//
//  Created by Robin Willis on 3/15/25.
//

import SwiftUI

struct ProcessingError: View {
  @Environment(\.dismiss) private var dismiss
  var message: String
  @ObservedObject var processingState: RecipeProcessingState
  var retry: (() -> Void)?

  private var displayMessage: String {
    if !message.isEmpty {
      return message
    } else {
      return "We couldn't process this content. Try another image with clear, visible text."
    }
  }
  
  private var iconName: String {
    if message.contains("text") {
      return "text.magnifyingglass"
    } else if message.contains("network") || message.contains("connection") {
      return "wifi.exclamationmark"
    } else if message.contains("permission") {
      return "lock.shield"
    } else {
      return "exclamationmark.triangle"
    }
  }

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: iconName)
        .font(.system(size: 24))
        .foregroundColor(.orange)
      
      Text(displayMessage)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
        .padding(.horizontal)

      // Action buttons
      HStack(spacing: 6) {
        // Cancel button
        Button("Cancel") {
          dismiss()
        }
        .buttonStyle(.bordered)
        
        // Retry button if handler provided
        if let retryAction = retry {
          Button("Retry") {
            retryAction()
          }
          .buttonStyle(.borderedProminent)
        }
      }
      
    }

  }
}

#Preview {
  struct PreviewWrapper: View {
    @StateObject private var processingState = RecipeProcessingState()
   private var message: String =  "We couldn't find any text in this image. Try another image with clear, visible text."
    var body: some View {
      ProcessingError(
        message: message,
        processingState: processingState,
        retry: {
          print("Retry tapped")
        }
      )
    }
  }
  return PreviewWrapper()
}
