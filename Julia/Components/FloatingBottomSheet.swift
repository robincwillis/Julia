//
//  FloatingBottomSheet.swift
//  Julia
//
//  Created by Robin Willis on 11/4/24.
//

import SwiftUI
import Combine

struct FloatingBottomSheet<Content: View>: View {
  @Binding var isPresented: Bool
  let content: Content
  let showHideTabBar: Bool
  
  @GestureState private var dragOffset: CGFloat = 0
  @State private var keyboardOffset: CGFloat = 0
  @State private var dismissOffset: CGFloat = 400
  
  @State private var opacity: Double = 0
  @State private var contentHeight: CGFloat = 0

  // Maximum height constraint as percentage of screen (optional)
  let maxHeightPercentage: CGFloat
  
  init(
    isPresented: Binding<Bool>,
    showHideTabBar: Bool = true,
    maxHeightPercentage: CGFloat = 0.85,
    @ViewBuilder content: () -> Content
  ) {
    self._isPresented = isPresented
    self.showHideTabBar = showHideTabBar
    self.content = content()
    self.maxHeightPercentage = maxHeightPercentage
  }
  
  var body: some View {
    GeometryReader { geometry in
      if isPresented {
        ZStack(alignment: .bottom) {
          // Content container with dynamic height, fixed at bottom
          ZStack {
            // Background shape
            RoundedRectangle(cornerRadius: 24)
              .fill(Color(UIColor.systemBackground))
              .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 4)
            // Automatically sized content
            VStack(spacing: 0) {
              // Handle indicator
              RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
              
              // Content with sizing
              content
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
          }
          .frame(maxWidth: .infinity)          
          // Apply dynamic height with a maximum constraint
          // But position it from the bottom using alignment
          .frame(
            height: min(contentHeight + 40, geometry.size.height * maxHeightPercentage),
            alignment: .bottom
          )
          .padding(.horizontal, 12)
          .offset(y: (dragOffset < 0 ? dragOffset * 0.25 : dragOffset) - keyboardOffset + dismissOffset)
          .animation(.spring(), value: dragOffset)
          .animation(.spring(), value: dismissOffset)
        }
        .frame(width: geometry.size.width, height: geometry.size.height,  alignment: .bottom)
        // This explicitly defines the hit test area for the gesture
        .background(
          // Debugging
          //.black.opacity(0.05)
          Color.clear
            .contentShape(Rectangle())
        )
        .simultaneousGesture(
          DragGesture()
            .updating($dragOffset) { value, state, _ in
              withAnimation(.interactiveSpring()) {
                state = value.translation.height
              }
            }
            .onEnded { value in
              handleDragEnd(value: value, geometry: geometry)
            }
        )
        .edgesIgnoringSafeArea(.bottom) // Ignore bottom safe area for backdrop
        .opacity(opacity)
        .onAppear {
          setupKeyboardObservers()
        }
      }
    }
    .animation(.spring(), value: isPresented)
    .onChange(of: isPresented) { oldValue, newValue in
        if newValue {
          if (showHideTabBar) {
            NotificationCenter.default.post(name: .hideTabBar, object: nil)
          }
          dismissOffset = 0
          opacity = 1
        } else {
          if (showHideTabBar) {
            NotificationCenter.default.post(name: .showTabBar, object: nil)
          }
          dismissOffset = 400
          opacity = 0
        }
    }
  }
  
  private func handleDragEnd(value: DragGesture.Value, geometry: GeometryProxy) {
    let dragPercentage = value.translation.height / geometry.size.height
    if dragPercentage > 0.15 {
      //dismissOffset += value
      // Dismiss if dragged down more than 15% of screen height
      dismiss()
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
  
  
  private func dismiss() {
    
    // let currentOffset = dragOffset
    
    //withAnimation(.easeOut(duration: 0.2)) {
     // dismissOffset = 400
     // opacity = 0
    //}
    
    //DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      //withAnimation(.easeOut(duration: 0.1)) {
        // Reset the additional offset for next presentation
      isPresented = false
      // dismissOffset = 0
    //}
    
    
//    withAnimation(.spring()) {
//      isPresented = false
//    }
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
        
        FloatingBottomSheet(
          isPresented: $showSheet,
          showHideTabBar: false
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
