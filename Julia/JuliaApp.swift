//
//  JuliaApp.swift
//  Julia
//
//  Created by Robin Willis on 6/19/24.
//

import SwiftUI
import SwiftData
import UIKit


@main
struct JuliaApp: App {
    @State private var showDBError = false
    @State private var dbError: Error?
    @State private var debugModeEnabled = false

    var body: some Scene {
        WindowGroup {
            let _ = UserDefaults.standard.register(defaults: [
                "debugMode": false
            ])
            ContentView()
                .environment(\.debugMode, debugModeEnabled)
                .onAppear {
                    // Debug mode is a dev tool — always start off, never persist across launches
                    UserDefaults.standard.set(false, forKey: "debugMode")
                    debugModeEnabled = false
                    setupDebugModeObserver()
                    // `appContainer` already finished initializing by this point (it's forced by
                    // `.modelContainer(...)` above), so this is a plain, race-free state check —
                    // not a notification that could arrive before anything is listening.
                    if DataController.isRunningInMemoryFallback {
                        dbError = DataController.containerLoadError
                        showDBError = true
                    }
                    // Enables Undo for AI-driven recipe edits (see RecipeDetails/UpdateRecipeTool,
                    // which group their changes into a single undo step). `.modelContainer(...)`
                    // above makes this the same context every `@Environment(\.modelContext)` sees.
                    if DataController.appContainer.mainContext.undoManager == nil {
                        DataController.appContainer.mainContext.undoManager = UndoManager()
                    }
                    // Warm the Foundation Models on-device model for faster first request
                    Task { await FoundationModelsService.shared.prewarm() }
                    updateAppIconForBuildType()
                }
                .alert("Data Isn't Being Saved", isPresented: $showDBError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your saved data couldn't be loaded, so Julia is running on a temporary, in-memory database. Recipes, ingredients, and lists will NOT be saved once you close the app.\n\n\(dbError?.localizedDescription ?? "Unknown error")")
                }
        }
        .modelContainer(DataController.appContainer)
    }

    // True for a Debug build, or a Release build installed through TestFlight (its receipt
    // lives at a "sandboxReceipt" path; an App Store install's does not). Used to pick the
    // dev/TestFlight alternate app icon automatically, with no user action required.
    private var isDevOrTestFlightBuild: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    // Switches to the dev/TestFlight icon (or back to the primary icon) to match the
    // current build. Guarded against redundant calls — setAlternateIconName shows a
    // system alert on an actual change, so this must be a no-op once already correct.
    private func updateAppIconForBuildType() {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let targetIconName = isDevOrTestFlightBuild ? "AppIcon-Dev" : nil
        guard UIApplication.shared.alternateIconName != targetIconName else { return }
        UIApplication.shared.setAlternateIconName(targetIconName)
    }

    private func setupDebugModeObserver() {
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            debugModeEnabled = UserDefaults.standard.bool(forKey: "debugMode")
        }
    }
}
