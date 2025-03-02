//
//  NavigationView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData
import Combine

// Define notification names for tab bar visibility
extension Notification.Name {
    static let hideTabBar = Notification.Name("hideTabBar")
    static let showTabBar = Notification.Name("showTabBar")
}

// Simple observer class (we're not using the height anymore)
class KeyboardObserver: ObservableObject {
  @Published var isKeyboardVisible: Bool = false
  
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
      .sink { [weak self] _ in
        self?.isKeyboardVisible = true
      }
      .store(in: &cancellables)
    
    NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
      .sink { [weak self] _ in
        self?.isKeyboardVisible = false
      }
      .store(in: &cancellables)
  }
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
      return "cart"
    case .pantry:
      return "list.bullet"
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

  @State private var selectedTab: String = "grocery"
  @State private var selectedLocation: IngredientLocation = .grocery
  @State private var showModal = false
  @State private var showCameraDirectly = false
  @State private var showPhotoLibraryDirectly = false
  @State private var showBottomSheet = false
  @State private var currentIngredient: Ingredient? = nil
  @State private var isTabBarVisible: Bool = true
  @StateObject private var keyboardObserver = KeyboardObserver()


  var body: some View {
    ZStack(alignment: .bottom) {
      TabView(selection: $selectedTab) {
        RecipesView()
          .tag("recipe")
          .toolbar(.hidden, for: .tabBar)
          .frame(maxHeight: .infinity)
        IngredientsView(
          location: IngredientLocation.pantry,
          showBottomSheet: $showBottomSheet,
          currentIngredient: $currentIngredient
        )
          .tag("pantry")
          .toolbar(.hidden, for: .tabBar)
          .frame(maxHeight: .infinity)
        IngredientsView(
          location: IngredientLocation.grocery,
          showBottomSheet: $showBottomSheet,
          currentIngredient: $currentIngredient
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
            
            Menu {
              Button(action: {
                showTakePhoto()
              }) {
                Label("Camera", systemImage: "camera")
                  .foregroundColor(.blue)
              }
              
              Button(action: {
                showPhotoLibrary()
              }) {
                Label("Photos", systemImage: "photo.on.rectangle")
                  .foregroundColor(.blue)
              }
            } label: {
              Image(systemName: "plus")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 10)
            }
            .menuOrder(.fixed)
            .menuStyle(.borderlessButton)
            .offset(x: -10, y: -15) // Move menu up and left
            
            .fullScreenCover(isPresented: $showModal) {
              ImagePicker(showModal: $showModal, showCameraDirectly: showCameraDirectly)
            }
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10) // Keep some space at the bottom
        .opacity(isTabBarVisible ? 1.0 : 0.0)
        .offset(y: isTabBarVisible ? 0 : 100) // Slide down when hiding
        .animation(.easeInOut(duration: 0.3), value: isTabBarVisible)
        .ignoresSafeArea(.keyboard)
      }
      
      
      FloatingBottomSheet(isPresented: $showBottomSheet) {
        AddIngredient(
          ingredientLocation: $selectedLocation, 
          ingredient: $currentIngredient,
          showBottomSheet: $showBottomSheet
        )
      }.onChange(of: showBottomSheet) {
        // Remove currentIngredient if AddIngredientSheet is dismissed
        if(showBottomSheet == false) {
          currentIngredient = nil
        }
      }
    }
    .onAppear {
      setupNotificationObservers()
    }
    .onDisappear {
      removeNotificationObservers()
    }
  }
  
  // MARK: - Notification Observers
  
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
  
  // MARK: - Action Functions
  
  private func showTakePhoto() {
    showCameraDirectly = true
    showModal = true
  }
  
  private func showPhotoLibrary() {
    showCameraDirectly = false
    showModal = true
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
    .frame(width: isActive ? .infinity : 60, height: 60)
    .background(isActive ? .blue : .clear)
    .cornerRadius(30)
  }
}

#Preview {
  NavigationView()
    .modelContainer(DataController.previewContainer)
  
}
