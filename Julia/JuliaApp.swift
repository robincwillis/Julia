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
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Ingredient.self, Recipe.self])
        
    }

}
