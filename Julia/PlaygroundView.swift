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
                    //.padding()
                    .background(.green)
                    .presentationCornerRadius(0)
                    //.frame(maxWidth: 400)
                    //.presentationBackground(content: EmptyView)
                    //.presentationBackground(.black.opacity(0))
                    .presentationDragIndicator(.hidden)
                    //                    .presentationBackground(content: {
                    //                        Rectangle()
                    //                            .fill(.blue)
                    //                            .frame(width: 200, height: 200)
                    //                    })
                    //.padding()
                    //.
                    //.presentation
                    //.presentationSizing(.fitted)
                    //                      .frame(
                    //                        minWidth: 200, idealWidth: 300, maxWidth: 500,
                    //                        minHeight: 100, maxHeight: 600)
            })
        }
    }
      //  .background(.mint)
    
}
func didDismiss() {
    // Handle the dismissing action.
}



struct PlaygroundView_Previews: PreviewProvider {
    static var previews: some View {
        PlaygroundView()
    }
}
