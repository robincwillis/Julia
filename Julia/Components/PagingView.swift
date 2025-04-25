//
//  PagingView.swift
//  Julia
//
//  Created by Robin Willis on 4/20/25.
//

import SwiftUI

// Non-generic preference key
struct TagPreferenceKey: PreferenceKey {
  typealias Value = [AnyHashable]
  static var defaultValue: [AnyHashable] = []
  
  static func reduce(value: inout [AnyHashable], nextValue: () -> [AnyHashable]) {
    value.append(contentsOf: nextValue())
  }
}

struct PagingView<Content: View, T: Hashable>: View {
  @Binding var selection: T
  let content: Content
  
  @GestureState private var translation: CGFloat = 0
  @State private var tags: [T] = []
  @State private var sortedIndices: [Int] = []
  
  init(selection: Binding<T>, @ViewBuilder content: () -> Content) {
    self._selection = selection
    self.content = content()
  }
  
  var body: some View {
    GeometryReader { geometry in
      content
        .frame(width: geometry.size.width * CGFloat(max(1, tags.count)), alignment: .leading)
        .offset(x: -CGFloat(currentIndex) * geometry.size.width)
        .offset(x: translation)
        .animation(.easeInOut(duration: 0.25), value: selection) // Smoother, slightly longer duration
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8), value: translation) // Less bouncy
        .gesture(
          DragGesture().updating($translation) { value, state, _ in
            state = value.translation.width
          }.onEnded { value in
            let offset = value.translation.width / geometry.size.width
            let newIndex = (CGFloat(currentIndex) - offset).rounded()
            let boundedIndex = min(max(Int(newIndex), 0), tags.count - 1)
            
            if boundedIndex < tags.count {
              selection = tags[boundedIndex]
            }
          }
        )
        .onPreferenceChange(TagPreferenceKey.self) { preferences in
          // Filter and cast preference values to the correct type
          let typedTags = preferences.compactMap { $0 as? T }
          self.tags = Array(Set(typedTags)) // Remove duplicates
        }
    }
  }
  
  // Find current index from selection value
  private var currentIndex: Int {
    tags.firstIndex(of: selection) ?? 0
  }
}

// Extension to make the tag value available for paging
extension View {
  func pagingTag<T: Hashable>(_ value: T) -> some View {
    self.preference(key: TagPreferenceKey.self, value: [value as AnyHashable])
  }
}
// Example implementation
struct PagingViewExample: View {
  @State private var selectedTab: Tabs = .grocery
  
  var body: some View {
    ZStack(alignment: .bottom) {
      // Main content area with paging
      PagingView(selection: $selectedTab) {
        HStack(spacing: 0) {
          GeometryReader { geo in
            IngredientsView(location: .grocery)
              .pagingTag(Tabs.grocery)
              .frame(width: geo.size.width)
          }
          
          GeometryReader { geo in
            IngredientsView(location: .pantry)
              .pagingTag(Tabs.pantry)
              .frame(width: geo.size.width)
          }
          
          GeometryReader { geo in
            RecipesView()
              .pagingTag(Tabs.recipe)
              .frame(width: geo.size.width)
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.green)
      
      // Custom tab bar
      HStack(spacing: 0) {
        ForEach(Tabs.allCases, id: \.self) { tab in
          Button(action: {
            withAnimation {
              selectedTab = tab
            }
          }) {
            VStack {
              Image(systemName: tab.iconName)
                .font(.system(size: 22))
              Text(tab.title)
                .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(selectedTab == tab ? .blue : .gray)
          }
        }
      }
      .background(
        RoundedRectangle(cornerRadius: 25)
          .fill(Color(.systemBackground))
          .shadow(radius: 2)
      )
      .padding(.horizontal, 16)
      .padding(.bottom, 8)
    }
  }
}



#Preview {
  PagingViewExample()
}
