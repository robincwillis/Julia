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

// Keyboard observer class
//class KeyboardObserver: ObservableObject {
//  @Published var isKeyboardVisible: Bool = false
//  
//  private var cancellables = Set<AnyCancellable>()
//  
//  init() {
//    NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
//      .receive(on: DispatchQueue.main)
//      .sink { [weak self] _ in
//        guard let self = self else { return }
//        // Using MainActor to safely update the published property
//        Task { @MainActor in
//          self.isKeyboardVisible = true
//        }
//      }
//      .store(in: &cancellables)
//    
//    NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
//      .receive(on: DispatchQueue.main)
//      .sink { [weak self] _ in
//        guard let self = self else { return }
//        // Using MainActor to safely update the published property
//        Task { @MainActor in
//          self.isKeyboardVisible = false
//        }
//      }
//      .store(in: &cancellables)
//  }
//}

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
      return "refrigerator" // "sink" // "house"
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
  @State private var isTabBarVisible: Bool = true
  @State private var selectedTab: String = "grocery"
  @State private var selectedLocation: IngredientLocation = .grocery
  @State private var selectedImage: UIImage?
  @State private var showRecipeProcessing = false
  
  // @StateObject private var keyboardObserver = KeyboardObserver()
  
  var body: some View {
    ZStack(alignment: .bottom) {
      TabView(selection: $selectedTab) {
        RecipesView()
          .tag("recipe")
          .toolbar(.hidden, for: .tabBar)
          .frame(maxHeight: .infinity)
        IngredientsView(
          location: IngredientLocation.pantry
        )
        .tag("pantry")
        .toolbar(.hidden, for: .tabBar)
        .frame(maxHeight: .infinity)
        IngredientsView(
          location: IngredientLocation.grocery
        )
        .tag("grocery")
        .toolbar(.hidden, for: .tabBar)
        .frame(maxHeight: .infinity)
        
      }
      
      // Bottom Navigation
      VStack {
        Spacer() // Push tab bar to bottom
        ZStack{
          HStack(spacing: 10) {
            // Tabs
            HStack{
              ForEach((Tabs.allCases), id: \.self){ item in
                Button {
                  withAnimation(.spring()) {
                    selectedTab = item.rawValue
                    selectedLocation = item.location
                  }
                } label: {
                  TabItem(imageName: item.iconName, title: item.title, isActive: (selectedTab == item.rawValue))
                }
              }
            }
            .padding(6)
            .frame(height: 70)
            .background(Color(red: 0.85, green: 0.92, blue: 1.0))
            .coordinateSpace(name: "TabStack")
            .cornerRadius(35)
            
            // Floating action menu
            FloatingActionMenu(
              selectedImage: $selectedImage,
              showRecipeProcessing: $showRecipeProcessing
            )
          }
        }
        .padding(.horizontal, 24)
        .opacity(isTabBarVisible ? 1.0 : 0.0)
        .offset(y: isTabBarVisible ? 0 : 100) // Slide down when hiding
        .animation(.easeInOut(duration: 0.3), value: isTabBarVisible)
      }
      
      // Recipe Processing Sheet
      .sheet(isPresented: $showRecipeProcessing) {
        if let image = selectedImage {
          RecipeProcessingView(image: image)
            .ignoresSafeArea(.keyboard)
            .onAppear {
              print("RecipeProcessingView appeared with image size: \(image.size)")
            }
        } else {
          VStack(spacing: 20) {
            Text("Error: No Image Selected")
              .font(.headline)
            
            Text("Please try selecting an image again")
              .foregroundColor(.secondary)
            
            Button("Dismiss") {
              showRecipeProcessing = false
            }
            .buttonStyle(.borderedProminent)
            .padding()
          }
          .padding()
          .onAppear {
            print("ERROR: RecipeProcessingView appeared without an image")
          }
        }
      }
      .onChange(of: showRecipeProcessing) { oldValue, newValue in
        print("showRecipeProcessing changed from \(oldValue) to \(newValue)")
      }
      .onChange(of: selectedImage) { oldValue, newValue in
        print("selectedImage changed: \(newValue != nil ? "Image set" : "nil")")
      }
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .onAppear {
      setupNotificationObservers()
    }
    .onDisappear {
      removeNotificationObservers()
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
