import SwiftUI

struct Dot: View {
  @Binding var isLoading: Bool
  @Binding var isExpanded: Bool

  @State private var rotation: Double = 0
  @State private var animationState: AnimationState = .closed
  @State private var xMarkScale: CGFloat = 0.25

  enum AnimationState {
    case closed
    case transitioning
    case loading
    case open
  }

  let numberOfCircles = 10
  // Matches the bottom tab menu height (see NavigationView.tabButtons)
  let mainCircleSize: CGFloat = 70
  let smallCircleSize: CGFloat = 10
  let expandedRadius: CGFloat = 25
  let animationDuration: Double = 0.2
  let pauseDuration: Double = 0.05
  let xMarkDelay: Double = 0.05
  let openCircleSize: CGFloat = 60

  private let buttonColor = Color(red: 1.0, green: 0.30, blue: 0.15)

  var body: some View {
    ZStack {
      // Main circle
      Circle()
        .fill(buttonColor)
        .frame(width: circleSize, height: circleSize)
        .shadow(color: buttonColor.opacity(0.5), radius: 8, x: 0, y: 3)
        .shadow(color: buttonColor.opacity(0.2), radius: 16, x: 0, y: 5)
        .opacity(animationState != .loading ? 1 : 0)
        .animation(.easeInOut(duration: animationDuration), value: animationState)

      // X Mark
      if animationState == .open {
        Image(systemName: "xmark")
          .font(.system(size: openCircleSize * 0.5, weight: .bold)) // Made bolder
          .foregroundColor(Color.app.textOnPrimary)
          .scaleEffect(xMarkScale)
          .opacity(animationState == .open ? 1 : 0)
      }

      // Loading ring of small dots
      ForEach(0..<numberOfCircles, id: \.self) { index in
        Circle()
          .fill(buttonColor)
          .frame(width: smallCircleSize, height: smallCircleSize)
          .shadow(color: buttonColor.opacity(0.4), radius: 3)
          .position(
            x: frameSize / 2 + (animationState == .loading ? expandedRadius * cos(angle(for: index)) : 0),
            y: frameSize / 2 + (animationState == .loading ? expandedRadius * sin(angle(for: index)) : 0)
          )
          .opacity(animationState == .loading ? 1 : 0)
          .animation(.easeInOut(duration: animationDuration), value: animationState)
      }
    }
    .rotationEffect(Angle(degrees: rotation))
    .frame(width: frameSize, height: frameSize)
    .onChange(of: isLoading) { _, newValue in handleLoadingChange(isNowLoading: newValue) }
    .onChange(of: isExpanded) { _, newValue in handleExpandedChange(isNowExpanded: newValue) }
  }

  // MARK: - Helpers

  private var circleSize: CGFloat {
    switch animationState {
    case .closed:       return mainCircleSize
    case .transitioning: return smallCircleSize
    case .loading:      return 0
    case .open:         return openCircleSize
    }
  }

  private var frameSize: CGFloat {
    max(mainCircleSize, (expandedRadius + smallCircleSize / 2) * 2)
  }

  private func angle(for index: Int) -> Double {
    (2 * .pi / Double(numberOfCircles)) * Double(index)
  }

  private func stopRotation() {
    withAnimation(.easeInOut(duration: 0.1)) { rotation = 0 }
  }

  private func handleLoadingChange(isNowLoading: Bool) {
    if isNowLoading {
      xMarkScale = 0.5
      animationState = .transitioning
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(animationDuration + pauseDuration))
        animationState = .loading
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
          rotation = 360
        }
      }
    } else if !isExpanded {
      stopRotation()
      animationState = .transitioning
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(animationDuration + pauseDuration))
        animationState = .closed
      }
    }
  }

  private func handleExpandedChange(isNowExpanded: Bool) {
    if isNowExpanded {
      xMarkScale = 0.1
      stopRotation()
      animationState = .transitioning
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(animationDuration + pauseDuration))
        animationState = .open
        try? await Task.sleep(for: .seconds(xMarkDelay))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
          xMarkScale = 1.0
        }
      }
    } else {
      animationState = .transitioning
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(animationDuration + pauseDuration))
        animationState = .closed
      }
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State var isLoading = false
    @State var isExpanded = false

    var body: some View {
      ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 32) {
          HStack(spacing: 20) {
            Button("Toggle Loading") {
              isLoading.toggle()
              if isLoading { isExpanded = false }
            }
            .foregroundStyle(.white)

            Button("Toggle Open") {
              isExpanded.toggle()
              if isExpanded { isLoading = false }
            }
            .foregroundStyle(.white)
          }

          Dot(isLoading: $isLoading, isExpanded: $isExpanded)
        }
      }
    }
  }
  return PreviewWrapper()
}
