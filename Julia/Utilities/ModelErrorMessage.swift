//
//  ModelErrorMessage.swift
//  Julia
//
//  Turns Foundation Models failures into something a user can act on.
//
//  Without this, `RecipeProcessor.handleError(error.localizedDescription)`
//  surfaces the framework's own text — "Exceeded model context window size",
//  or worse, "The operation couldn't be completed. (GenerationError error
//  -1.)". Neither tells anyone what to do next.
//

import Foundation
import FoundationModels

enum ModelErrorMessage {

    /// User-facing text for an error thrown anywhere in the import pipeline.
    ///
    /// Anything unrecognised falls through to `localizedDescription`, so types
    /// that already carry good copy — `FoundationModelsServiceError`,
    /// `RecipeProcessor.ProcessingError`, `WebScrapeError` — pass through
    /// untouched and need no case here.
    static func friendlyMessage(for error: Error) -> String {
        if let generation = error as? LanguageModelSession.GenerationError {
            return message(for: generation)
        }
        return error.localizedDescription
    }

    /// Explains why the on-device model cannot be used right now.
    ///
    /// Note the API exposes only three reasons. There is no distinct
    /// "unsupported region" case — regional ineligibility arrives as
    /// `.deviceNotEligible`, so the copy for it deliberately covers both
    /// rather than claiming a distinction we cannot actually make.
    static func message(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Recipe import needs Apple Intelligence, which isn't supported "
                 + "on this device or in this region. You can still add recipes by hand."
        case .appleIntelligenceNotEnabled:
            return "Recipe import needs Apple Intelligence. Turn it on in "
                 + "Settings → Apple Intelligence & Siri, then try again."
        case .modelNotReady:
            return "Apple Intelligence is still downloading on this device. "
                 + "Try again once it has finished."
        @unknown default:
            return "Apple Intelligence isn't available on this device right now."
        }
    }

    // MARK: - Private

    private static func message(for error: LanguageModelSession.GenerationError) -> String {
        switch error {
        case .exceededContextWindowSize:
            return "This recipe is too long to process at once. "
                 + "Try splitting it into smaller sections."
        case .guardrailViolation:
            return "This content couldn't be processed due to Apple's "
                 + "content safety guidelines."
        case .rateLimited:
            return "Too many requests right now — wait a moment and try again."
        case .assetsUnavailable:
            return "Apple Intelligence isn't ready on this device yet. "
                 + "Try again shortly."
        default:
            // .decodingFailure, .unsupportedGuide, .unsupportedLanguageOrLocale,
            // .concurrentRequests, .refusal and anything added later. These are
            // either developer errors or too rare to write copy for blind.
            return error.localizedDescription
        }
    }
}
