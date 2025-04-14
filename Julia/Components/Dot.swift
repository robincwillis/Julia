import SwiftUI

struct Dot: View {
  @Binding var isLoading: Bool
  @Binding var isExpanded: Bool
  
  @State private var rotation: Double = 0
  @State private var animationState: AnimationState = .closed
  @State private var xMarkScale: CGFloat = 0.25
  
  enum AnimationState {
    case closed        // Main circle
    case transitioning // intermediate circle
    case loading       // Ring of circles
    case open          // Circle with X mark
  }
  
  let numberOfCircles = 10
  let mainCircleSize: CGFloat = 60
  let smallCircleSize: CGFloat = 10
  let expandedRadius: CGFloat = 25
  let animationDuration: Double = 0.2
  let pauseDuration: Double = 0.05
  let xMarkDelay: Double = 0.05 // Delay for X mark appearance
  let openCircleSize: CGFloat = 50 // Slightly smaller than main circle
  
  var body: some View {
    ZStack {
      // Main circle (visible when not in loading state)
      Circle()
        .fill(Color.red)
        .frame(width: circleSize, height: circleSize)
        .opacity(animationState != .loading ? 1 : 0)
        .animation(.easeInOut(duration: animationDuration), value: animationState)
      
      // X Mark (visible in open state)
      if animationState == .open {
        Image(systemName: "xmark")
          .font(.system(size: openCircleSize * 0.5, weight: .bold)) // Made bolder
          .foregroundColor(.white)
          .scaleEffect(xMarkScale)
          .opacity(animationState == .open ? 1 : 0)
      }
      
      // Small circles (visible when in loading state)
      ForEach(0..<numberOfCircles, id: \.self) { index in
        Circle()
          .fill(Color.red)
          .frame(width: smallCircleSize, height: smallCircleSize)
          .position(
            x: frameSize/2 + (animationState == .loading ? expandedRadius * cos(angle(for: index)) : 0),
            y: frameSize/2 + (animationState == .loading ? expandedRadius * sin(angle(for: index)) : 0)
          )
          .opacity(animationState == .loading ? 1 : 0)
          .animation(.easeInOut(duration: animationDuration), value: animationState)
      }
    }
    .rotationEffect(Angle(degrees: rotation))
    .frame(width: frameSize, height: frameSize)
    .onChange(of: isLoading) { _, newValue in
      handleLoadingChange(isNowLoading: newValue)
    }
    .onChange(of: isExpanded) { _, newValue in
      handleExpandedChange(isNowExpanded: newValue)
    }
  }
  
  // Compute the size of the circle based on current state
  private var circleSize: CGFloat {
    switch animationState {
    case .closed:
      return mainCircleSize
    case .transitioning:
      return smallCircleSize
    case .loading:
      return 0 // Hidden when loading
    case .open:
      return openCircleSize
    }
  }
  
  private func stopRotation() {
    withAnimation(.easeInOut(duration: 0.1)) {
      rotation = 0
    }
  }
  
  private func handleLoadingChange(isNowLoading: Bool) {
    if isNowLoading {
      // Reset X mark scale for next appearance
      xMarkScale = 0.5
      
      // Transition to loading state
      animationState = .transitioning
      
      // After pause, expand to ring and start rotation
      DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + pauseDuration) {
        animationState = .loading
        
        // Start continuous rotation when loading
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
          rotation = 360
        }
      }
    } else if !isExpanded {
      // Only transition to closed if not going to open state
      // Stop rotation animation
      stopRotation()
      
      // Collapse to small circle
      animationState = .transitioning
      
      // After pause, expand to main circle
      DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + pauseDuration) {
        animationState = .closed
      }
    }
  }
  
  private func handleExpandedChange(isNowExpanded: Bool) {
    if isNowExpanded {
      // Reset X mark scale for animation
      xMarkScale = 0.1
      
      // Transition to open state with X mark
      stopRotation()
      animationState = .transitioning
      
      DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + pauseDuration) {
        animationState = .open
        
        // After a short delay, animate X mark scale up
        DispatchQueue.main.asyncAfter(deadline: .now() + xMarkDelay) {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            xMarkScale = 1.0
          }
        }
      }
    } else {
      // Only transition to closed if not going to loading state
      // Collapse to small circle
      animationState = .transitioning
      
      // After pause, expand to main circle
      DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + pauseDuration) {
        animationState = .closed
      }
    }
  }
  
  // Calculate the frame size to ensure it can contain all states
  private var frameSize: CGFloat {
    return max(mainCircleSize, (expandedRadius + smallCircleSize/2) * 2)
  }
  
  private func angle(for index: Int) -> Double {
    return (2 * .pi / Double(numberOfCircles)) * Double(index)
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State var isLoading = false
    @State var isExpanded = false
    
    var body: some View {
      VStack {
        HStack(spacing: 20) {
          Button("Toggle Loading") {
            isLoading.toggle()
            if isLoading { isExpanded = false }
          }
          .padding()
          
          Button("Toggle Open") {
            isExpanded.toggle()
            if isExpanded { isLoading = false }
          }
          .padding()
        }
        
        Dot(
          isLoading: $isLoading,
          isExpanded: $isExpanded
        )
        .padding()
        
        Text("Tap the dot to cycle through states")
          .padding()
      }
    }
  }
  
  return PreviewWrapper()
}
