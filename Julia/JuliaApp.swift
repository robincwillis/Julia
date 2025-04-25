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
    @State private var debugModeEnabled = true
    
    var body: some Scene {
        WindowGroup {
            // Environment objects are set at the top level of the app
            let _ = UserDefaults.standard.register(defaults: [
                "debugMode": true
            ])
            ContentView()
                .environment(\.debugMode, debugModeEnabled)
                .onAppear {
                    setupErrorObserver()
                    setupDebugModeObserver()
                    // Initialize from UserDefaults
                    debugModeEnabled = UserDefaults.standard.bool(forKey: "debugMode")
                }
                .alert("Database Error", isPresented: $showDBError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("There was a problem loading your data: \(dbError?.localizedDescription ?? "Unknown error")")
                }
        }
        .modelContainer(DataController.appContainer)
    }
    
    private func setupErrorObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ModelContainerError"),
            object: nil,
            queue: .main
        ) { notification in
            if let error = notification.object as? Error {
                dbError = error
                showDBError = true
            }
        }
    }
    
    private func setupDebugModeObserver() {
        // Observe changes to the debug mode UserDefault
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Check if debugMode specifically changed
            debugModeEnabled = UserDefaults.standard.bool(forKey: "debugMode")
        }
    }
}
