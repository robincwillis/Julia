//
//  PlaygroundView.swift
//  Julia
//
//  Created by Robin Willis on 7/3/24.
//

import SwiftUI
import Combine



struct PlaygroundView<Content: View>: View {
  @Binding var isPresented: Bool
  let content: Content
  let maxHeightPercentage: CGFloat
  let showHideTabBar: Bool

  init(
    isPresented: Binding<Bool>,
    maxHeightPercentage: CGFloat = 0.85,
    showHideTabBar : Bool = false,
    @ViewBuilder content: () -> Content
  ) {
    self._isPresented = isPresented
    self.maxHeightPercentage = maxHeightPercentage
    self.showHideTabBar = showHideTabBar
    self.content = content()
  }
  
  // Initial State
  @GestureState private var dragOffset: CGFloat = 0
  
  @State private var dragEndOffset: CGFloat = 0
  // TODO Add Keyboard
  @State private var keyboardOffset: CGFloat = 0
  @State private var animationOffset: CGFloat = 0
  @State private var opacity: Double = 0
  @State private var contentHeight: CGFloat = 0
  
  @State private var isContentVisible: Bool = false
  @State private var isInView: Bool = false

  
  var body: some View {
    ZStack {
      if isInView {
        GeometryReader { geometry in
          ZStack (alignment: .bottom) {
            if isContentVisible {
              Color.black.opacity(0.05)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                  isPresented = false
                }
            }
            
            VStack {
              Spacer()
              ZStack {
                VStack(spacing: 0) {
                  // Handle indicator
                  RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)
                  
                  // Content with sizing
                  content
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(
                      GeometryReader { contentGeometry in
                        Color.clear
                          .ignoresSafeArea()
                          .onAppear {
                            // Store the content height when it appears
                            contentHeight = contentGeometry.size.height
                          }
                      }
                    )
                }
                
                // Style the Sheet
                .background(.white)
                .cornerRadius(24)
                .padding(.horizontal, 12)
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 4)
                .offset(y: (dragOffset < 0 ? dragOffset * 0.25 : dragOffset) + dragEndOffset - keyboardOffset)
                
              }
            }
            // Full View
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isContentVisible ? 1.0 : 0.0)
            .offset(y: isContentVisible ? 0 : contentHeight)
          }
          .background(
            Color.clear
              .contentShape(Rectangle())
              .allowsHitTesting(isContentVisible)
          )
          .simultaneousGesture(
            DragGesture()
              .updating($dragOffset) { value, state, _ in
                state = value.translation.height
              }
              .onEnded { value in
                handleDragEnd(value: value, geometry: geometry)
              }
          )
          .animation(.interactiveSpring(), value: dragOffset)
          .onAppear {
            setupKeyboardObservers()
          }
          
        }
      }
    }
    //.animation(.easeInOut(duration: 0.2), value: isContentVisible)
    .onChange(of: isPresented) { oldValue, newValue in
      if newValue {
        dragEndOffset = 0
        isInView = newValue
        Task { @MainActor in
          withAnimation(.easeInOut(duration: 0.3)) {
            isContentVisible = newValue
          }
        }
        if (showHideTabBar) {
          NotificationCenter.default.post(name: .hideTabBar, object: nil)
        }
      } else {
        
        withAnimation(.easeInOut(duration: 0.3)) {
          isContentVisible = newValue
        } completion: {
          isInView = false
        }
        if (showHideTabBar) {
          NotificationCenter.default.post(name: .showTabBar, object: nil)

        }
      }
    }
    .onAppear {
      isContentVisible = isPresented
      isInView = isPresented
    }
  }
  
  
  private func handleDragEnd(value: DragGesture.Value, geometry: GeometryProxy) {
    let dragPercentage = value.translation.height / geometry.size.height
    if dragPercentage > 0.15 {
      dragEndOffset = value.translation.height
      isPresented = false
    }
  }
  
  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillShowNotification,
      object: nil,
      queue: .main
    ) { notification in
      if notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] is CGRect {
        withAnimation(.spring()) {
          self.keyboardOffset = 12
        }
      }
    }
    
    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main
    ) { _ in
      withAnimation(.spring()) {
        self.keyboardOffset = 0
      }
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var showSheet = true
    @State private var textInput = ""
    @State private var showExtraContent = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
      ZStack {
        // Main content
        VStack {
          Text("Main View")
          Button("Show Sheet") {
            showSheet = true
          }
        }
        
        PlaygroundView(
          isPresented: $showSheet
        ) {
          VStack(spacing: 16) {
            Text("Dynamic Content Sheet")
              .font(.headline)
            
            TextField("Type something...", text: $textInput)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .focused($isFocused)
            
            Button("Toggle Extra Content") {
              withAnimation {
                showExtraContent.toggle()
              }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Dismiss") {
              showSheet = false
            }
            .buttonStyle(.borderedProminent)
            
            if showExtraContent {
              // This content will only appear when toggled
              VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                  Text("Additional item \(index)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
              }
              .transition(.opacity.combined(with: .move(edge: .bottom)))
              
            }
          }
          .animation(.spring(), value: showExtraContent)
        }
      }
    }
  }
  
  return PreviewWrapper()
}
