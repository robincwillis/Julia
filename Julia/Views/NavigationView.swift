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
  
  // Recipe processing state
  @State private var selectedImage: UIImage?
  @State private var selectedText: String?
  @State private var extractedRecipeData: RecipeData?
  @StateObject private var recipeProcessor = RecipeProcessor()
  
  var body: some View {
    ZStack(alignment: .bottom) {
      tabView
      bottomNavigationAndActions
    }
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
      RecipesView()
        .tag("recipe")
        .toolbar(.hidden, for: .tabBar)
        .frame(maxHeight: .infinity)
      
      IngredientsView(location: IngredientLocation.pantry)
        .tag("pantry")
        .toolbar(.hidden, for: .tabBar)
        .frame(maxHeight: .infinity)
      
      IngredientsView(location: IngredientLocation.grocery)
        .tag("grocery")
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
    .animation(.easeInOut(duration: 0.3), value: isTabBarVisible)
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
        }
      }
    }
    .padding(5)
    .frame(height: 70)
    .background(Color(red: 0.85, green: 0.92, blue: 1.0))
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
  }
  
  private func removeNotificationObservers() {
    NotificationCenter.default.removeObserver(self, name: .hideTabBar, object: nil)
    NotificationCenter.default.removeObserver(self, name: .showTabBar, object: nil)
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
