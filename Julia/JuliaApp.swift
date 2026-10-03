//
//  JuliaApp.swift
//  Julia
//
//  Created by Robin Willis on 6/19/24.
//

import SwiftUI
import SwiftData


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
                    // Warm the Foundation Models on-device model for faster first request
                    Task { await FoundationModelsService.shared.prewarm() }
                }
                .alert("Data Isn't Being Saved", isPresented: $showDBError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your saved data couldn't be loaded, so Julia is running on a temporary, in-memory database. Recipes, ingredients, and lists will NOT be saved once you close the app.\n\n\(dbError?.localizedDescription ?? "Unknown error")")
                }
        }
        .modelContainer(DataController.appContainer)
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
