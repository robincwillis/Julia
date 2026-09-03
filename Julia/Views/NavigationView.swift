//
//  NavigationView.swift
//  Julia
//
//  Created by Robin Willis on 7/1/24.
//

import SwiftUI
import SwiftData
import PhotosUI
import VisionKit


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
      return "cabinet"
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
  @State private var selectedTab: Tabs = .grocery

  @State private var isSettingsDrawerVisible = false
  @State private var dragOffset: CGFloat = 0

  // Recipe processing state
  @State private var selectedImage: UIImage?
  @State private var selectedText: String?
  @State private var extractedRecipeData: RecipeData?
  @Environment(\.scenePhase) private var scenePhase
  @State private var recipeProcessor = RecipeProcessor()

  // Receipt processing state
  @State private var receiptProcessor = ReceiptProcessor()

  // Julia chat
  @State private var showJulia = false
  @State private var screenSize: CGSize = .zero

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
    .gesture(
      DragGesture(minimumDistance: 20, coordinateSpace: .global)
        .onChanged { gesture in
          let edgeWidth: CGFloat = 100
          let startLocation = gesture.startLocation.x

          if (startLocation < edgeWidth && !isSettingsDrawerVisible) || isSettingsDrawerVisible {
            if gesture.translation.width > 0 && !isSettingsDrawerVisible {
              dragOffset = min(280, gesture.translation.width)
            } else if gesture.translation.width < 0 && isSettingsDrawerVisible {
              dragOffset = max(-280, gesture.translation.width)
            }
          }
        }
        .onEnded { gesture in
          let edgeWidth: CGFloat = 100
          let startLocation = gesture.startLocation.x

          if (startLocation < edgeWidth && !isSettingsDrawerVisible) || isSettingsDrawerVisible {
            if gesture.translation.width > 50 && !isSettingsDrawerVisible {
              isSettingsDrawerVisible = true
            } else if gesture.translation.width < -50 && isSettingsDrawerVisible {
              isSettingsDrawerVisible = false
            }
          }
          dragOffset = 0
        }
    )
    .onGeometryChange(for: CGSize.self) { $0.size } action: { screenSize = $0 }
    .simultaneousGesture(
      DragGesture(minimumDistance: 60, coordinateSpace: .global)
        .onEnded { gesture in
          let screenWidth = screenSize.width
          let screenHeight = screenSize.height
          guard gesture.translation.height < -60,
                abs(gesture.translation.width) < 60,
                gesture.startLocation.x > screenWidth * 0.65,
                gesture.startLocation.y > screenHeight * 0.88
          else { return }
          showJulia = true
        }
    )
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .onAppear {
      setupNotificationObservers()
      recipeProcessor.setModelContext(context)
      receiptProcessor.setModelContext(context)
      importNextSharedItem()
    }
    .onDisappear {
      removeNotificationObservers()
    }
    // Share extension hand-off. The deep link covers the common case; the
    // scenePhase check catches items queued while the app was backgrounded, or
    // when opening the app was refused.
    .onOpenURL { url in
      if SharedImportInbox.isImportLink(url) {
        importNextSharedItem()
      }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        importNextSharedItem()
      }
    }
    .onChange(of: recipeProcessor.processingState.showResultsSheet) { wasShowing, isShowing in
      // Once the user finishes with one shared item, pick up the next.
      if wasShowing && !isShowing {
        importNextSharedItem()
      }
    }
    .onChange(of: selectedImage) { _, newValue in
      if let image = newValue {
        Task { await classifyAndProcess(image) }
      }
    }
    .onChange(of: selectedText) { _, newValue in
      if let text = newValue {
        recipeProcessor.processText(text)
      }
    }
    .onChange(of: extractedRecipeData) { _, newValue in
      if let recipeData = newValue {
        recipeProcessor.processData(recipeData)
      }
    }
}

// MARK: - Share Extension Hand-off

/// Takes one item at a time from the shared inbox. Importing runs through a
/// single RecipeProcessor, so items are handled sequentially — the next is
/// picked up when the results sheet for the previous one is dismissed.
private func importNextSharedItem() {
  guard !recipeProcessor.processingState.isProcessing,
        !recipeProcessor.processingState.showResultsSheet,
        let item = SharedImportInbox.dequeue()
  else { return }

  switch item {
  case .text(let text):
    recipeProcessor.importSharedText(text)
  case .url(let urlString):
    recipeProcessor.importSharedURL(urlString)
  }
}

// MARK: - View Components

private var tabView: some View {
  TabView(selection: $selectedTab) {
    IngredientsView(location: .grocery)
      .tag(Tabs.grocery)
      .toolbar(.hidden, for: .tabBar)
      .frame(maxHeight: .infinity)

    IngredientsView(location: .pantry)
      .tag(Tabs.pantry)
      .toolbar(.hidden, for: .tabBar)
      .frame(maxHeight: .infinity)

    RecipesView()
      .tag(Tabs.recipe)
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
  .sheet(isPresented: $receiptProcessor.processingState.showResultsSheet) {
    ProcessingResultsReceipt(
      receiptData: $receiptProcessor.receiptData,
      saveItems: receiptProcessor.saveSelectedItems
    )
    .presentationDragIndicator(.hidden)
    .interactiveDismissDisabled()
  }
  .fullScreenCover(isPresented: $showJulia) {
    ChefChatView(
      selectedImage: $selectedImage,
      selectedText: $selectedText,
      extractedRecipeData: $extractedRecipeData
    )
  }
}

private var bottomNavigation: some View {
  VStack {
    Spacer()
    HStack(spacing: 10) {
      tabButtons
      Circle()
        .fill(Color.clear)
        .frame(width: 70, height: 70)
    }
    .padding(.horizontal, 24)
  }
}

private var tabButtons: some View {
  HStack {
    ForEach(Tabs.allCases, id: \.self) { item in
      Button {
        withAnimation(.spring(duration: 0.3)) {
          selectedTab = item
        }
      } label: {
        TabItem(
          imageName: item.iconName,
          title: item.title,
          isActive: (selectedTab == item)
        )
        .animation(.spring(duration: 0.3), value: selectedTab)
      }
    }
  }
  .padding(5)
  .frame(height: 70)
  .background(Color.app.white)
  .coordinateSpace(name: "TabStack")
  .clipShape(.rect(cornerRadius: 35))
}

private var floatingActionMenu: some View {
  FloatingActionMenu(
    processingState: recipeProcessor.processingState,
    onOpen: { showJulia = true }
  )
}

private func classifyAndProcess(_ image: UIImage) async {
  let lines = await TextRecognitionService.shared.recognizeText(from: image)
  let type = await DocumentClassifier.classify(lines: lines)
  switch type {
  case .recipe:
    recipeProcessor.processImage(image)
  case .receipt:
    receiptProcessor.processLines(lines)
  }
}

private var settingsDrawer: some View {
  SettingsDrawer(isOpen: $isSettingsDrawerVisible)
    .ignoresSafeArea(.container, edges: .vertical)
    .zIndex(1)
    .offset(x: isSettingsDrawerVisible ? 0 : -280)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSettingsDrawerVisible)
    .shadow(color: isSettingsDrawerVisible ? Color.black.opacity(0.1) : Color.clear, radius: 10, x: -5, y: 0)
}


private var processingStatusSheet: some View {
  FloatingStatusSheet(
    isPresented: $recipeProcessor.processingState.showProcessingSheet,
    onDismiss: {
      selectedImage = nil
      selectedText = nil
      extractedRecipeData = nil
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
      isSettingsDrawerVisible = false
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
  func TabItem(imageName: String, title: String, isActive: Bool) -> some View {
    HStack(spacing: 10) {
      Spacer()
      Image(systemName: imageName)
        .resizable()
        .renderingMode(.template)
        .foregroundStyle(isActive ? .white : .blue)
        .frame(width: 20, height: 20)
      if isActive {
        Text(title)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(isActive ? .white : .blue)
      }
      Spacer()
    }
    .frame(width: isActive ? nil : 60, height: 60)
    .background(isActive ? .blue : .clear)
    .clipShape(.rect(cornerRadius: 30))
  }
}

#Preview {
  NavigationView()
    .modelContainer(DataController.previewContainer)
}
