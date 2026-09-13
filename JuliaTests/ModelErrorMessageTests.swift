//
//  ModelErrorMessageTests.swift
//  JuliaTests
//
//  Error classification and user-facing copy. Offline — no model involved.
//
//  Worth testing directly rather than waiting for the environment to misbehave:
//  the classification decides whether a failing pipeline test means "the model
//  would not answer" or "the pipeline is broken", and the failure it guards
//  against is intermittent by nature.
//

import Testing
import Foundation
import FoundationModels
@testable import Julia

@Suite("Model error messages (offline)")
struct ModelErrorMessageTests {

    // MARK: - Classification

    @Test("An unavailable model is environmental", arguments: [
        SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible,
        .appleIntelligenceNotEnabled,
        .modelNotReady
    ])
    func availabilityErrorsAreEnvironmental(
        reason: SystemLanguageModel.Availability.UnavailableReason
    ) {
        #expect(ModelErrorMessage.isEnvironmental(ModelAvailabilityError.unavailable(reason)))
    }

    @Test("The service's own unavailable error is environmental")
    func serviceUnavailableIsEnvironmental() {
        #expect(ModelErrorMessage.isEnvironmental(
            FoundationModelsService.FoundationModelsServiceError.unavailable
        ))
    }

    @Test("Our own pipeline errors are not environmental", arguments: [
        RecipeProcessor.ProcessingError.noTextDetected,
        .emptyContent,
        .classificationFailed
    ])
    func pipelineErrorsAreNotEnvironmental(error: RecipeProcessor.ProcessingError) {
        // These mean the input or the pipeline is at fault, so a test hitting
        // one must fail rather than quietly skip.
        #expect(!ModelErrorMessage.isEnvironmental(error))
    }

    @Test("Unrelated errors are not environmental")
    func unrelatedErrorsAreNotEnvironmental() {
        #expect(!ModelErrorMessage.isEnvironmental(URLError(.notConnectedToInternet)))
        #expect(!ModelErrorMessage.isEnvironmental(CocoaError(.fileNoSuchFile)))
    }

    // MARK: - Copy

    @Test("Every unavailability reason has actionable copy", arguments: [
        SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible,
        .appleIntelligenceNotEnabled,
        .modelNotReady
    ])
    func availabilityCopyIsUsable(reason: SystemLanguageModel.Availability.UnavailableReason) {
        let message = ModelErrorMessage.message(for: reason)
        #expect(!message.isEmpty)
        // The whole point of this helper is to replace framework text, so a
        // message that reads like a developer error has failed its job.
        #expect(!message.contains("Error Domain"))
        #expect(!message.contains("error -1"))
    }

    @Test("The unavailable-in-region case does not claim a distinction the API cannot make")
    func deviceNotEligibleCoversRegion() {
        // There is no distinct "unsupported region" reason: regional
        // ineligibility arrives as .deviceNotEligible, so the copy has to cover
        // both rather than naming only the device.
        let message = ModelErrorMessage.message(for: .deviceNotEligible)
        #expect(message.lowercased().contains("region"))
    }

    @Test("An error with good copy of its own passes through untouched")
    func passesThroughLocalizedErrors() {
        // FoundationModelsServiceError and WebScrapeError already carry usable
        // text; friendlyMessage must not replace it with something vaguer.
        let error = FoundationModelsService.FoundationModelsServiceError.unavailable
        #expect(ModelErrorMessage.friendlyMessage(for: error) == error.localizedDescription)
    }

    @Test("An unrecognised error falls back to its own description")
    func unrecognisedFallsBack() {
        let error = URLError(.timedOut)
        #expect(ModelErrorMessage.friendlyMessage(for: error) == error.localizedDescription)
    }
}
