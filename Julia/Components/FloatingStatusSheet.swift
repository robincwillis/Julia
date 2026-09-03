//
//  FloatingStatusSheet.swift
//  Julia
//

import SwiftUI

struct FloatingStatusSheet<Content: View>: View {
  @Binding var isPresented: Bool
  let content: Content

  // Configuration options
  var dismissAfter: Double   // Auto-dismiss after seconds (0 = no auto-dismiss)
  var minimumDuration: Double // Minimum display time before allowing dismiss
  var tapToDismiss: Bool      // Whether tapping outside dismisses the sheet
  var onDismiss: (() -> Void)?

  // Animation state
  @State private var dismissTimer: Timer?
  @State private var presentationTimestamp: Date?

  @State private var isInView: Bool = false

  init(
    isPresented: Binding<Bool>,
    dismissAfter: Double = 0,
    minimumDuration: Double = 0,
    tapToDismiss: Bool = true,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self._isPresented = isPresented
    self.dismissAfter = dismissAfter
    self.minimumDuration = minimumDuration
    self.tapToDismiss = tapToDismiss
    self.onDismiss = onDismiss
    self.content = content()
  }

  var body: some View {
    ZStack {
      if isInView {
        Color.black
          .ignoresSafeArea()
          .opacity(0.05)
          .animation(.easeInOut(duration: 0.3), value: isInView)
          .onTapGesture {
            if tapToDismiss && canDismiss() {
              isPresented = false
            }
          }
        GeometryReader { geometry in
          VStack {
            content
          }
          .frame(width: geometry.size.width * 0.5)
          .padding(36)
          .background(Color.app.white)
          .cornerRadius(24)
          .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
          .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
      }
    }
    .onChange(of: isPresented) { oldValue, newValue in
      if newValue && !oldValue {
        withAnimation(.easeIn(duration: 0.2)) {
          isInView = true
        }
        startPresentation()
      } else if !newValue && oldValue {
        withAnimation {
          isInView = false
        }
        startDismissal()
      }
    }
    .onAppear {
      if isPresented {
        startPresentation()
      }
    }
    .onDisappear {
      dismissTimer?.invalidate()
    }
  }

  private func startPresentation() {
    presentationTimestamp = Date()
    setupDismissTimer()
  }

  private func startDismissal() {
    onDismiss?()
    dismissTimer?.invalidate()
    dismissTimer = nil
  }

  private func canDismiss() -> Bool {
    guard minimumDuration > 0, let timestamp = presentationTimestamp else {
      return true
    }
    return Date().timeIntervalSince(timestamp) >= minimumDuration
  }

  private func setupDismissTimer() {
    dismissTimer?.invalidate()
    if dismissAfter > 0 {
      dismissTimer = Timer.scheduledTimer(withTimeInterval: dismissAfter, repeats: false) { _ in
        if canDismiss() {
          isPresented = false
        }
      }
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var isPresented = false
    let processingState = RecipeProcessingState()

    var body: some View {
      ZStack {
        FloatingStatusSheet(
          isPresented: $isPresented,
          dismissAfter: 0,
          minimumDuration: 0.5,
          tapToDismiss: true,
          onDismiss: { print("Sheet dismissed") }
        ) {
          RecipeProcessing(processingState: processingState)
        }

        VStack(spacing: 20) {
          Spacer()
          Button {
            isPresented.toggle()
            if isPresented {
              processingState.statusMessage = "Processing recipe..."
            } else {
              processingState.reset()
            }
          } label: {
            Text(isPresented ? "Hide Status" : "Show Status")
              .padding()
              .background(.blue)
              .foregroundColor(Color.app.textPrimary)
              .cornerRadius(12)
          }
        }
      }
      .frame(maxWidth: .infinity)
    }
  }

  return PreviewWrapper()
}
