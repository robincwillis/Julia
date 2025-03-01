//
//  PlaygroundView.swift
//  Julia
//
//  Created by Robin Willis on 7/3/24.
//

import SwiftUI

struct PlaygroundView: View {
    @State private var sheetIsPresented = false
    @State private var coverIsPresented = false
    
    var body: some View {
        VStack {
        
            Button("Show Cover") {
                self.coverIsPresented.toggle()
            }
            .padding(24)
            .fullScreenCover(isPresented: $coverIsPresented,
                            onDismiss: didDismiss) {
                Spacer()
                VStack {
                    Text("A full-screen modal view.")
                        .font(.title)
                    Text("Tap to Dismiss")
                }
                .onTapGesture {
                    coverIsPresented.toggle()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .presentationBackground(.black.opacity(0.25))
                .padding()
                .presentationBackgroundInteraction(.enabled)
                
            }
            
            Button("Show Sheet") {
                self.sheetIsPresented.toggle()
            }
            .padding(24)
            .sheet(isPresented: $sheetIsPresented, content: {
                VStack {
                    Text("Hello")
                        .background(.blue)
                }
                    .padding(24)
                    .presentationDetents([.height(300), .medium, .large])
                    .background(.green)
                    .presentationCornerRadius(0)
                    .presentationDragIndicator(.hidden)
            })
        }
    }
    
}
func didDismiss() {
    // Handle the dismissing action.
}



#Preview {
    PlaygroundView()
}
