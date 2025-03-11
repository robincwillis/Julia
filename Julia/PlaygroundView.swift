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

  init(
    isPresented: Binding<Bool>,
    // TODO Add Max Height
    maxHeightPercentage: CGFloat = 0.85,
    @ViewBuilder content: () -> Content
  ) {
    self._isPresented = isPresented
    self.content = content()
    self.maxHeightPercentage = maxHeightPercentage
  }
  
  // Initial State
  @GestureState private var dragOffset: CGFloat = 0
  
  @State private var dragEndOffset: CGFloat = 0
  // TODO Add Keyboard
  @State private var keyboardOffset: CGFloat = 0
  @State private var animationOffset: CGFloat = 0
  @State private var opacity: Double = 0
  @State private var contentHeight: CGFloat = 0
  
  var body: some View {
    GeometryReader { geometry in
      //if isPresented {
        ZStack (alignment: .bottom) {
          if isPresented {
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
//                        .preference(key: ContentHeightPreferenceKey.self, value: contentGeometry.size.height)
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
          .opacity(isPresented ? 1.0 : 0.0)
          .offset(y: isPresented ? 0 : contentHeight)
          .animation(.easeInOut(duration: 0.2), value: isPresented)
        }
        
        .background(
          Color.clear
            .contentShape(Rectangle())
            .allowsHitTesting(isPresented)
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
        
        .onAppear {
          setupKeyboardObservers()
        }
        .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
          contentHeight = height
        }
      }
      //.edgesIgnoringSafeArea(.vertical)
  }
  
  
  private func handleDragEnd(value: DragGesture.Value, geometry: GeometryProxy) {
    let dragPercentage = value.translation.height / geometry.size.height
    if dragPercentage > 0.15 {
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


// Preference key to track content height
//struct ContentHeightPreferenceKey: PreferenceKey {
//  static var defaultValue: CGFloat = 0
//  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//    value = nextValue()
//  }
//}

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
