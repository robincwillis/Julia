//
//  NavigationView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData

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
  @State private var showBottomSheet = false
  @State private var currentIngredient: Ingredient? = nil


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
          .background(.blue.opacity(0.2))
          .coordinateSpace(name: "TabStack")
          .cornerRadius(35)
          
          Button(action: {
            showModal.toggle()
          }) {
            Image(systemName: "plus")
              .font(.system(size: 24))
              .foregroundColor(.white)
              .frame(width: 60, height: 60)
              .background(Color.blue)
              .clipShape(Circle())
              .shadow(radius: 10)
          }
          
          .sheet(isPresented: $showModal) {
            ImagePicker(showModal: $showModal)
          }
        }
      }
      .padding(.horizontal, 24)
      .ignoresSafeArea(.keyboard)
      
      
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
