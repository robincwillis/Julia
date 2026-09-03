//
//  FloatingActionMenu.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI

struct FloatingActionMenu: View {
    var processingState: RecipeProcessingState
    var onOpen: () -> Void

    @State private var isLoading = false
    @State private var isExpanded = false  // always false, needed by Dot binding

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Dot(isLoading: $isLoading, isExpanded: $isExpanded)
                    .onTapGesture {
                        guard !isLoading else { return }
                        onOpen()
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 5)
            }
        }
        .onChange(of: processingState.isProcessing) { _, v in if v { isLoading = true } }
        .onChange(of: processingState.processingComplete) { _, v in if v { isLoading = false } }
        .onChange(of: processingState.processingFailed) { _, v in if v { isLoading = false } }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var state = RecipeProcessingState()
        var body: some View {
            ZStack { FloatingActionMenu(processingState: state, onOpen: {}) }
        }
    }
    return PreviewWrapper()
}
