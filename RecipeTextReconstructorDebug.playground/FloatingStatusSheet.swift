  import SwiftUI
  import Combine

  struct FloatingStatusSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    // Configuration options
    var dismissAfter: Double // Auto-dismiss after seconds (0 = no auto-dismiss)
    var minimumDuration: Double // Minimum display time before allowing dismiss
    var tapToDismiss: Bool // Whether tapping outside dismisses the sheet
    var onDismiss: (() -> Void)? // Action to perform on dismiss
    
    // Animation state
    @State private var dismissTimer: Timer?
    @State private var presentationTimestamp: Date?
    
    // Visibility and animation states
    @State private var isInView: Bool = false
    @State private var isContentVisible: Bool = false
    
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
          // .opacity(0.05)
            .ignoresSafeArea()
            .opacity(isInView ? 0.05 : 0)
            .animation(.easeInOut(duration: 0.3), value: isInView)
            .onTapGesture {
              if tapToDismiss && canDismiss() {
                isPresented = false
              }
            }
          GeometryReader { geometry in
            
            VStack {
              // if isContentVisible {
                content
              //}
            }
            .frame(width: geometry.size.width * 0.5)
            .padding(36)
            .background(.white)
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
            //isContentVisible = true
          }
          // Start presentation
          startPresentation()
        } else if !newValue && oldValue {
          withAnimation {
            // isContentVisible = false
            isInView = false
          }
          // Start dismissal sequence
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
    
    // Sequential animation for dismissing the sheet
    private func startDismissal() {
      if let onDismiss = onDismiss {
        onDismiss()
      }
      // Cancel any dismiss timer
      dismissTimer?.invalidate()
      dismissTimer = nil
    }
    
    private func canDismiss() -> Bool {
      guard minimumDuration > 0, let timestamp = presentationTimestamp else {
        return true
      }
      
      let elapsedTime = Date().timeIntervalSince(timestamp)
      return elapsedTime >= minimumDuration
    }
    
    private func setupDismissTimer() {
      dismissTimer?.invalidate()
      
      // Create timer if auto-dismiss is enabled
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
    PreviewWrapper()
  }

  // Helper struct to manage state for the preview
  private struct PreviewWrapper: View {
    @State private var isPresented = false
    //@State private var isLoading: Bool = true
    let processingState = RecipeProcessingState()
    
    let image = UIImage(named: "preview_image") ?? UIImage()
    
    var body: some View {
      ZStack {
        
        FloatingStatusSheet(
          isPresented: $isPresented,
          dismissAfter: 0,
          minimumDuration: 0.5,
          tapToDismiss: true,
          onDismiss: {
            print("Sheet dismissed")
          }
        ) {
          RecipeProcessing(processingState: processingState)
        }
        
        VStack(spacing: 20) {
          Spacer()
          Button(action: {
            isPresented.toggle()

            if isPresented {
              processingState.isProcessing.toggle()
              processingState.image = image
              processingState.statusMessage = "Some really long status message here"
            } else {
             processingState.reset()
            }
          }) {
            Text(isPresented ? "Hide Status" : "Show Status")
              .padding()
              .background(.blue)
              .foregroundColor(.white)
              .cornerRadius(12)
          }
        }
        
      }
      .frame(maxWidth: .infinity)
    }
  }
