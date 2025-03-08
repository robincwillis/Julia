//
//  FloatingBottomSheet.swift
//  Julia
//
//  Created by Robin Willis on 11/4/24.
//

import SwiftUI
import Combine

enum SheetDetent: Equatable {
  case medium
  case large
  
  var heightRatio: CGFloat {
    switch self {
    case .medium: return 0.5
    case .large: return 0.85
    }
  }
}

struct FloatingBottomSheet<Content: View>: View {
  @Binding var isPresented: Bool
  @Binding var selectedDetent: SheetDetent
  
  let content: Content
  
  @GestureState private var dragOffset: CGFloat = 0
  @State private var offset: CGFloat = 12
  @State private var keyboardOffset: CGFloat = 0
  
  init(
    isPresented: Binding<Bool>,
    selectedDetent: Binding<SheetDetent> = .constant(.medium),
    @ViewBuilder content: () -> Content
  ) {
    self._isPresented = isPresented
    self._selectedDetent = selectedDetent
    self.content = content()
  }
  
  var body: some View {
    GeometryReader {
      geometry in if isPresented {
        ZStack {
          Color.black
            .opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
              dismiss()
            }
          
          VStack {
            Spacer ()
            
            content
              .padding(8)
            
              .frame(maxWidth: .infinity)
            //.frame(height: geometry.size.height * selectedDetent.heightRatio + dragOffset)
              .background(
                RoundedRectangle(cornerRadius: 24)
                  .fill(Color(UIColor.systemBackground))
                  .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: -5)
              )
              .offset(y: dragOffset - keyboardOffset)
              .animation(.spring(), value: dragOffset) // Animate changes to dragOffsetY
              .transition(.move(edge: .bottom))
              .padding(.horizontal, 12)
            
          }
          
        }
        .gesture(
          DragGesture()
            .updating($dragOffset) { value, state, _ in
              state = value.translation.height
            }
            .onEnded { value in
              handleDragEnd(value: value, geometry: geometry)
            }
        )
        .frame(width: geometry.size.width, height: geometry.size.height)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedDetent)
        .onAppear {
          setupKeyboardObservers()
        }
      }
    }
  }
  
  private func handleDragEnd(value: DragGesture.Value, geometry: GeometryProxy) {
    let dragPercentage = value.translation.height / geometry.size.height
    
    withAnimation(.spring()) {
      if dragPercentage > 0.25 {
        // Dismiss if dragged down more than 25% of screen height
        dismiss()
      } else if dragPercentage < -0.1 && selectedDetent == .medium {
        // selectedDetent = .large
      } else if dragPercentage > 0.1 && selectedDetent == .large {
        // selectedDetent = .medium
      }
      // offset = 0
    }
  }
  
  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillShowNotification,
      object: nil,
      queue: .main
    ) { notification in
      withAnimation(.spring()) {
        self.keyboardOffset = 12 //height
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
    withAnimation(.spring()) {
      isPresented = false
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var showSheet = true
    @State private var sheetDetent: SheetDetent = .medium
    @State private var textInput = ""
    
    @FocusState private var isFocused: Bool // Focus state for text field
    
    var body: some View {
      ZStack {
        
        
        FloatingBottomSheet(
          isPresented: $showSheet,
          selectedDetent: $sheetDetent
        ) {
          VStack(spacing: 24) {
            Text("Sheet Content")
            Button("Change Sheet Detent") {
              sheetDetent = .large
            }
            .buttonStyle(.borderedProminent)
            TextField("Type something...", text: $textInput)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .padding(.horizontal)
              .focused($isFocused) // Bind focus to this text field
              .onAppear {
                isFocused = true // Automatically focus when the view appears
              }
          }
        }
      }
    }
  }
  
  return PreviewWrapper()
    .preferredColorScheme(.light)
    .previewDisplayName("Light Mode")
}
