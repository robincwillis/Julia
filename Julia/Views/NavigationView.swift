//
//  NavigationView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData
import Combine
import UIKit
import PhotosUI


// Define notification names for tab bar visibility
extension Notification.Name {
  static let hideTabBar = Notification.Name("hideTabBar")
  static let showTabBar = Notification.Name("showTabBar")
  
  static let hideSettingsDrawer = Notification.Name("hideSettingsDrawer")
  static let showSettingsDrawer = Notification.Name("showSettingsDrawer")
}

enum Tabs: String, CaseIterable{
  case grocery
  case pantry
  case recipe
  
  var title: String{
    switch self {
    case .grocery:
      return "Groceries"
    case .pantry:
      return "Pantry"
    case .recipe:
      return "Recipes"
      
    }
  }
  var iconName: String{
    switch self {
    case .grocery:
      return "basket"
    case .pantry:
      return "cabinet" // "refrigerator" // "sink" // "house"
    case .recipe:
      return "book"
    }
  }
  
  var location: IngredientLocation {
    switch self {
    case.grocery:
      return IngredientLocation.grocery
    case.pantry:
      return IngredientLocation.pantry
    case.recipe:
      return IngredientLocation.recipe
    }
  }
}


struct NavigationView: View {
  @Environment(\.modelContext) private var context
  
  // Tab bar state
  @State private var isTabBarVisible: Bool = true
  @State private var selectedTab: String = "grocery"
  @State private var selectedLocation: IngredientLocation = .grocery
  
  @State private var isSettingsDrawerVisible = false
  @State private var dragOffset: CGFloat = 0
  
  // Recipe processing state
  @State private var selectedImage: UIImage?
  @State private var selectedText: String?
  @State private var extractedRecipeData: RecipeData?
  @StateObject private var recipeProcessor = RecipeProcessor()
  
  var body: some View {
    
    ZStack(alignment: .leading) {
      settingsDrawer
      ZStack(alignment: .bottom) {
        tabView
        bottomNavigationAndActions
      }
      .offset(x: isSettingsDrawerVisible ? 280 : 0)
      .animation(.easeInOut(duration: 0.3), value: isTabBarVisible)

    }
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSettingsDrawerVisible)
    //.background(.pink)
    .gesture(
      // Use a DragGesture with gesture detection logic
      DragGesture(minimumDistance: 20, coordinateSpace: .global)
        .onChanged { gesture in
          // Only process edge swipes for the drawer
          let edgeWidth: CGFloat = 100 // Area on edge that activates drawer
          let startLocation = gesture.startLocation.x
          // let screenWidth = UIScreen.main.bounds.width
          
          // Only handle gestures that start near the left edge (for opening drawer)
          // or that start when drawer is open (for closing)
          if (startLocation < edgeWidth && !isSettingsDrawerVisible) || isSettingsDrawerVisible {
            if gesture.translation.width > 0 && !isSettingsDrawerVisible {
              // Swiping right to open drawer
              dragOffset = min(280, gesture.translation.width)
            } else if gesture.translation.width < 0 && isSettingsDrawerVisible {
              // Swiping left to close drawer
              dragOffset = max(-280, gesture.translation.width)
            }
          }
        }
        .onEnded { gesture in
          // Same edge detection logic
          let edgeWidth: CGFloat = 100
          let startLocation = gesture.startLocation.x
          // let screenWidth = UIScreen.main.bounds.width
          
          if (startLocation < edgeWidth && !isSettingsDrawerVisible) || isSettingsDrawerVisible {
            // If swiped more than 50 points, toggle drawer state
            if gesture.translation.width > 50 && !isSettingsDrawerVisible {
              isSettingsDrawerVisible = true
            } else if gesture.translation.width < -50 && isSettingsDrawerVisible {
              isSettingsDrawerVisible = false
            }
          }
          dragOffset = 0
        }
    )
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .onAppear {
      setupNotificationObservers()
      recipeProcessor.setModelContext(context)
    }
    .onDisappear {
      removeNotificationObservers()
    }
    .onChange(of: selectedImage) { oldValue, newValue in
      if let image = selectedImage {
        recipeProcessor.processImage(image)
      }
    }
    .onChange(of: selectedText) { oldValue, newValue in
      if let text = selectedText {
        recipeProcessor.processText(text)
      }
    }
    .onChange(of: extractedRecipeData) { oldValue, newValue in
      if let recipeData = newValue {
        recipeProcessor.processData(recipeData)
      }
    }
}

// MARK: - View Components

private var tabView: some View {
  TabView(selection: $selectedTab) {
    IngredientsView(location: IngredientLocation.grocery)
      .tag("grocery")
      .toolbar(.hidden, for: .tabBar)
      .frame(maxHeight: .infinity)
    
    IngredientsView(location: IngredientLocation.pantry)
      .tag("pantry")
      .toolbar(.hidden, for: .tabBar)
      .frame(maxHeight: .infinity)
    
    RecipesView()
      .tag("recipe")
      .toolbar(.hidden, for: .tabBar)
      .frame(maxHeight: .infinity)
    
  }

  
}

private var bottomNavigationAndActions: some View {
  ZStack {
    bottomNavigation
    floatingActionMenu
    processingStatusSheet
  }
  .opacity(isTabBarVisible ? 1.0 : 0.0)
  .offset(y: isTabBarVisible ? 0 : 100)
  .sheet(
    isPresented: $recipeProcessor.processingState.showResultsSheet,
    onDismiss: {
      extractedRecipeData = nil
      selectedImage = nil
      selectedText = nil
    }
  ) {
    ProcessingResults(
      processingState: recipeProcessor.processingState,
      recipeData: $recipeProcessor.recipeData,
      saveRecipe: recipeProcessor.saveRecipe
    )
    .presentationDragIndicator(.hidden)
    .interactiveDismissDisabled()
  }
}

private var bottomNavigation: some View {
  VStack {
    Spacer()
    HStack(spacing: 10) {
      tabButtons
      Circle()
        .fill(Color.clear)
        .frame(width: 60, height: 60)
    }
    .padding(.horizontal, 24)
  }
}

private var tabButtons: some View {
  HStack {
    ForEach(Tabs.allCases, id: \.self) { item in
      Button {
        withAnimation(.spring(duration: 0.3)) {
          selectedTab = item.rawValue
          selectedLocation = item.location
        }
      } label: {
        TabItem(
          imageName: item.iconName,
          title: item.title,
          isActive: (selectedTab == item.rawValue)
        )
        .animation(.spring(duration: 0.3), value: selectedTab)
      }
    }
  }
  .padding(5)
  .frame(height: 70)
  .background(Color.white)
  .coordinateSpace(name: "TabStack")
  .cornerRadius(35)
}

private var floatingActionMenu: some View {
  FloatingActionMenu(
    selectedImage: $selectedImage,
    selectedText: $selectedText,
    extractedRecipeData: $extractedRecipeData,
    processingState: recipeProcessor.processingState
  )
}

private var settingsDrawer: some View {
  SettingsDrawer(isOpen: $isSettingsDrawerVisible)
    .edgesIgnoringSafeArea(.vertical)
    .zIndex(1)
    .offset(x: isSettingsDrawerVisible ? 0 : -280)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSettingsDrawerVisible)
    .shadow(color: isSettingsDrawerVisible ? Color.black.opacity(0.1) : Color.clear, radius: 10, x: -5, y: 0)
  
}

//  private var clipboardDetectView: some View {
//
//  }

private var processingStatusSheet: some View {
  FloatingStatusSheet(
    isPresented: $recipeProcessor.processingState.showProcessingSheet,
    dismissAfter: 5,
    // minimumDuration: 3,
    onDismiss: {
      selectedImage = nil
      selectedText = nil
    }
  ) {
    RecipeProcessing(
      processingState: recipeProcessor.processingState
    )
  }
}

private func setupNotificationObservers() {
  NotificationCenter.default.addObserver(
    forName: .hideTabBar,
    object: nil,
    queue: .main
  ) { _ in
    withAnimation {
      isTabBarVisible = false
    }
  }
  
  NotificationCenter.default.addObserver(
    forName: .showTabBar,
    object: nil,
    queue: .main
  ) { _ in
    withAnimation {
      isTabBarVisible = true
    }
  }
  
  NotificationCenter.default.addObserver(
    forName: .showSettingsDrawer,
    object: nil,
    queue: .main
  ) { _ in
    withAnimation {
      isSettingsDrawerVisible = true
    }
  }
  
  NotificationCenter.default.addObserver(
    forName: .hideSettingsDrawer,
    object: nil,
    queue: .main
  ) { _ in
    withAnimation {
      isSettingsDrawerVisible = true
    }
  }
}

private func removeNotificationObservers() {
  NotificationCenter.default.removeObserver(self, name: .hideTabBar, object: nil)
  NotificationCenter.default.removeObserver(self, name: .showTabBar, object: nil)
  NotificationCenter.default.removeObserver(self, name: .hideSettingsDrawer, object: nil)
  NotificationCenter.default.removeObserver(self, name: .showSettingsDrawer, object: nil)
}
}

extension NavigationView{
  func TabItem(imageName: String, title: String, isActive: Bool) -> some View{
    HStack(spacing: 10){
      Spacer()
      Image(systemName: imageName)
        .resizable()
        .renderingMode(.template)
        .foregroundColor(isActive ? .white : .blue)
        .frame(width: 20, height: 20)
      if isActive{
        Text(title)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(isActive ? .white : .blue)
      }
      Spacer()
    }
    .frame(width: isActive ? nil : 60, height: 60)
    .background(isActive ? .blue : .clear)
    .cornerRadius(30)
  }
}

#Preview {
  NavigationView()
    .modelContainer(DataController.previewContainer)
}
