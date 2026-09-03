//
//  FoundationModelsService.swift
//  Julia
//

import Foundation
import FoundationModels

/// Singleton actor that owns the LanguageModelSession and serializes all
/// Foundation Models requests across the app. Creating a new session per
/// request avoids context accumulation between independent tasks.
actor FoundationModelsService {
    static let shared = FoundationModelsService()
    private init() {}

    private let model = SystemLanguageModel.default

    var isAvailable: Bool {
        model.availability == .available
    }

    /// Warms the on-device model so the first real request is fast.
    /// Call once at app launch.
    func prewarm() async {
        guard isAvailable else { return }
        let warmupSession = LanguageModelSession()
        warmupSession.prewarm()
    }

    /// Generates a structured result for the given prompt.
    /// Creates a fresh session per call to avoid context accumulation.
    func generate<T: Generable>(
        _ prompt: String,
        type: T.Type,
        instructions: String? = nil
    ) async throws -> T {
        guard isAvailable else {
            throw FoundationModelsServiceError.unavailable
        }
        let session: LanguageModelSession
        if let instructions {
            session = LanguageModelSession { instructions }
        } else {
            session = LanguageModelSession()
        }
        let response = try await session.respond(to: prompt, generating: type)
        return response.content
    }

    enum FoundationModelsServiceError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            "Apple Intelligence is not available on this device. Enable it in Settings → Apple Intelligence & Siri."
        }
    }
}
