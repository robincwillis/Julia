//
//  TestResult.swift
//  Julia
//
//  Created by Robin Willis on 5/10/25.
//
import SwiftUI
@testable import Julia


struct TestResult {
    enum TestType {
        case image
        case text
    }
    
    var name: String
    var type: TestType
    var success: Bool = false
    var startTime: Date?
    var endTime: Date?
    var resultData: RecipeData?
    var titleMatch: Bool?
    var hasMultipleRecipes: Bool?
    var errorMessage: String?
    
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
}
