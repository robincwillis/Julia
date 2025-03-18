//
//  AdaptiveNavigationTitleModifier.swift
//  Julia
//
//  Created by Robin Willis on 3/17/25.
//
import SwiftUI

struct AdaptiveNavigationTitleModifier: ViewModifier {
  // Title to display
  let title: String
  
  // Configuration options
  var expandedTitleFont: Font = .largeTitle
  var titleColor: Color = .primary
  var backgroundColor: Color = Color(UIColor.systemBackground)
  
  // Optional binding to expose scrolled state
  var isScrolledBinding: Binding<Bool>?
  
  // Scroll position tracking
  @State private var scrollOffset: CGFloat = 0
  @State private var titleHeight: CGFloat = 0
  @State private var localIsScrolled: Bool = false
  
  // Function to update scroll state
  private func updateScrollState(_ newValue: Bool) {
    if localIsScrolled != newValue {
      localIsScrolled = newValue
      // Update binding if provided
      isScrolledBinding?.wrappedValue = newValue
    }
  }
  
  // Calculated properties for animations
  private var expandedTitleOpacity: CGFloat {
    // Fade out the large title as we scroll
    // More gradual fade based on title height
    let fadeRate = min(1.0, max(0.0, -scrollOffset / titleHeight))
    return 1.0 - fadeRate
  }
  
  func body(content: Content) -> some View {
    ZStack(alignment: .top) {
      // Main content with navigation title (handled externally)
      content
      // Add padding to top to make room for our custom title
        .padding(.top, titleHeight)
      
      // Expandable title at the top that scrolls with content
      VStack(alignment: .leading, spacing: 0) {
        // Title with background
        VStack(alignment: .leading) {
          Text(title)
            .font(expandedTitleFont)
            .fontWeight(.bold)
            .foregroundColor(titleColor)
            .multilineTextAlignment(.leading)
            .lineLimit(nil) // Allow text to wrap
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(
              GeometryReader { geo in
                Color.clear
                  .onAppear {
                    // Store the height of the title
                    titleHeight = geo.size.height
                  }
              }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .opacity(expandedTitleOpacity)
        
        // Scroll position observer
        GeometryReader { geometry -> Color in
          let offset = geometry.frame(in: .global).minY
          
          // Update state on next render cycle
          // Update state on main actor
          Color.clear
            .onAppear {
              scrollOffset = offset
              // Only consider scrolled when we've passed the title height
              // Adding a small buffer (e.g., -10) for a smoother transition
              updateScrollState(offset <= -titleHeight + 10)
            }
            .onChange(of: offset) { _, newOffset in
              scrollOffset = newOffset
              // Only consider scrolled when we've passed the title height
              updateScrollState(newOffset <= -titleHeight + 10)
            }
          
          return Color.clear
        }
        .frame(height: 0) // Zero height, just for tracking
      }
      .zIndex(1) // Keep title on top
    }
  }
}

extension View {
  // Version without binding
  func adaptiveNavigationTitle(
    _ title: String,
    expandedFont: Font = .largeTitle,
    titleColor: Color = .primary,
    backgroundColor: Color = Color(UIColor.systemBackground)
  ) -> some View {
    self.modifier(AdaptiveNavigationTitleModifier(
      title: title,
      expandedTitleFont: expandedFont,
      titleColor: titleColor,
      backgroundColor: backgroundColor,
      isScrolledBinding: nil
    ))
  }
  
  // Version with binding to expose scrolled state
  func adaptiveNavigationTitle(
    _ title: String,
    isScrolled: Binding<Bool>,
    expandedFont: Font = .largeTitle,
    titleColor: Color = .primary,
    backgroundColor: Color = Color(UIColor.systemBackground)
  ) -> some View {
    self.modifier(AdaptiveNavigationTitleModifier(
      title: title,
      expandedTitleFont: expandedFont,
      titleColor: titleColor,
      backgroundColor: backgroundColor,
      isScrolledBinding: isScrolled
    ))
  }
}


struct ExampleWithDynamicNavTitle: View {
  let longTitle = "This is a Very Long Page Title That Will Need to Wrap to Multiple Lines When Expanded"
  @State private var isScrolled = false
  
  var body: some View {
    NavigationStack {
      List {
        Section(header: Text("Section 1")) {
          ForEach(1...20, id: \.self) { item in
            Text("List item \(item)")
          }
        }
        
        Section(header: Text("Section 2")) {
          ForEach(21...30, id: \.self) { item in
            Text("List item \(item)")
          }
        }
      }
      .adaptiveNavigationTitle(longTitle, isScrolled: $isScrolled)
      .navigationTitle(isScrolled ? longTitle : "") // Dynamic title based on scroll state
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: {}) {
            Image(systemName: "square.and.arrow.up")
          }
        }
      }
    }
  }
}

struct ExampleRecipeForm: View {
  let recipeTitle = "Homemade Classic Margherita Pizza with Fresh Basil and Mozzarella"
  @State private var isScrolled = false
  @State private var notes = "Recipe notes go here with detailed information about the preparation..."
  
  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Description")) {
          TextEditor(text: $notes)
            .frame(minHeight: 100)
        }
        
        Section(header: Text("Ingredients")) {
          ForEach(1...8, id: \.self) { item in
            Text("Ingredient \(item)")
          }
        }
        
        Section(header: Text("Instructions")) {
          ForEach(1...5, id: \.self) { step in
            Text("Step \(step): Detailed cooking instruction goes here.")
              .padding(.vertical, 4)
          }
        }
        
        // Additional sections
        ForEach(1...3, id: \.self) { section in
          Section(header: Text("Additional Information \(section)")) {
            ForEach(1...4, id: \.self) { item in
              Text("Item \(item)")
            }
          }
        }
      }
      .adaptiveNavigationTitle(recipeTitle, isScrolled: $isScrolled)
      .navigationTitle(isScrolled ? recipeTitle : "")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            Button(action: {}) {
              Label("Share Recipe", systemImage: "square.and.arrow.up")
            }
            Button(action: {}) {
              Label("Edit Recipe", systemImage: "pencil")
            }
            Button(action: {}) {
              Label("Add to Favorites", systemImage: "heart")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
      }
    }
  }
}

struct ExampleScrollView: View {
  let title = "Photo Gallery"
  @State private var isScrolled = false
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          ForEach(1...30, id: \.self) { item in
            Text("Photo \(item)")
              .frame(height: 200)
              .frame(maxWidth: .infinity)
              .background(Color.blue.opacity(0.1 + (Double(item % 5) / 50.0)))
              .cornerRadius(8)
          }
        }
        .padding()
      }
      .adaptiveNavigationTitle(title, isScrolled: $isScrolled)
      .navigationTitle(isScrolled ? title : "")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

#Preview {
  // Main content view with tab navigation
  struct PreviewWrapper: View {
    var body: some View {
      TabView {
        ExampleWithDynamicNavTitle()
          .tabItem {
            Label("List", systemImage: "list.bullet")
          }
        
        ExampleRecipeForm()
          .tabItem {
            Label("Recipe", systemImage: "fork.knife")
          }
        
        ExampleScrollView()
          .tabItem {
            Label("Gallery", systemImage: "photo")
          }
      }
    }
  }
  return PreviewWrapper()
}
