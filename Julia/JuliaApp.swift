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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupErrorObserver()
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
}
