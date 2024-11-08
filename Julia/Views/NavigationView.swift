//
//  TabView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData

enum Tabs: Int, CaseIterable{
    case groceries
    case ingredients
    case recipes
    
    var title: String{
        switch self {
        case .groceries:
            return "Groceries"
        case .ingredients:
            return "Ingredients"
        case .recipes:
            return "Recipes"
            
        }
    }
    var iconName: String{
        switch self {
        case .groceries:
            return "cart"
        case .ingredients:
            return "list.bullet"
        case .recipes:
            return "book"
        }
    }
    
}


struct NavigationView: View {


    @State private var selectedTab = 0
    @State private var showModal = false
    
    @State private var selectedTabFrame: CGRect = .zero
    
    @State private var showSheet = false
    @FocusState private var isFocused: Bool // Focus state for text field
    @State private var textInput = ""

    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            TabView(selection: $selectedTab) {
                RecipesView()
                    .tag(2)
                IngredientsView()
                    .tag(1)
                GroceriesView(showSheet: $showSheet)
                    .tag(0)
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
            
            // Sheets // Refactor as Add Ingredient
            FloatingBottomSheet(isPresented: $showSheet) {
               VStack(spacing: 20) {
                   Text("Add Item")
                       .font(.headline)
                   
                   TextField("Type something...", text: $textInput)
                       .textFieldStyle(RoundedBorderTextFieldStyle())
                       .padding(.horizontal)
                       .focused($isFocused) // Bind focus to this text field
                       .onAppear {
                           isFocused = true // Automatically focus when the view appears
                       }
                       .onSubmit {
                           // Do this thing depending on where it was called from
                       }
                   
               }

           }
        }
    }
    
    fileprivate func updateTabFrame(_ frame: CGRect) {
        selectedTabFrame = frame
   }
}

extension NavigationView{
    func TabItem(imageName: String, title: String, isActive: Bool) -> some View{
        
        
        HStack(spacing: 10){
            Spacer()
            Image(systemName: imageName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(isActive ? .black : .gray)
                .frame(width: 20, height: 20)
            if isActive{
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? .black : .gray)
            }
            Spacer()
        }
        .frame(width: isActive ? .infinity : 60, height: 60)
        .background(isActive ? .blue.opacity(0.4) : .clear)
        .cornerRadius(30)
    }
}

#Preview {
  do {
    return NavigationView()
    .modelContainer(DataController.previewContainer)
  } catch {
    return Text("Failed to create container: \(error.localizedDescription)")
  }
}
