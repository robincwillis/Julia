//
//  ShareViewController.swift
//  JuliaShareExtension
//
//  Receives text or a URL from the system share sheet — a note from Notes, a
//  recipe page from Safari — queues it in the shared App Group container, then
//  deep-links Julia to import it.
//
//  The queue is written before the deep link is attempted, so if opening the
//  app fails (or the user dismisses), nothing is lost: the app drains the inbox
//  the next time it comes forward.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        presentStatus(.working)

        Task {
            do {
                let item = try await extractSharedItem()
                try SharedImportInbox.enqueue(item)
                await openHostApp()
                await finish(after: .saved)
            } catch {
                await finish(after: .failed(error.localizedDescription))
            }
        }
    }

    // MARK: - Extraction

    private enum ShareError: LocalizedError {
        case nothingUsable

        var errorDescription: String? {
            switch self {
            case .nothingUsable:
                return "Julia couldn't find recipe text or a link in what you shared."
            }
        }
    }

    /// Pulls the first usable payload out of the extension context. A URL wins
    /// over text when both are present — a shared Safari page carries its title
    /// as text too, and the page itself is what we want to scrape.
    private func extractSharedItem() async throws -> SharedImport {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }

        if let url = await firstURL(in: providers) {
            return .url(url.absoluteString)
        }
        if let text = await firstText(in: providers) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw ShareError.nothingUsable }
            // Notes sometimes hands over a bare link as plain text.
            if let url = Self.bareURL(in: trimmed) {
                return .url(url.absoluteString)
            }
            return .text(trimmed)
        }
        throw ShareError.nothingUsable
    }

    private func firstURL(in providers: [NSItemProvider]) async -> URL? {
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL,
               url.scheme?.hasPrefix("http") == true {
                return url
            }
        }
        return nil
    }

    private func firstText(in providers: [NSItemProvider]) async -> String? {
        for provider in providers {
            for identifier in [UTType.plainText.identifier, UTType.text.identifier] {
                guard provider.hasItemConformingToTypeIdentifier(identifier) else { continue }
                let loaded = try? await provider.loadItem(forTypeIdentifier: identifier)
                if let string = loaded as? String { return string }
                if let data = loaded as? Data, let string = String(data: data, encoding: .utf8) {
                    return string
                }
                if let attributed = loaded as? NSAttributedString { return attributed.string }
            }
        }
        return nil
    }

    /// Detects a shared payload that is really just a link.
    private static func bareURL(in text: String) -> URL? {
        guard !text.contains("\n"), text.count < 2048 else { return nil }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, range: range)
        // Only treat it as a link if the link *is* the whole payload.
        guard matches.count == 1, let match = matches.first,
              match.range == range, let url = match.url,
              url.scheme?.hasPrefix("http") == true
        else { return nil }
        return url
    }

    // MARK: - Hand-off

    /// Brings Julia forward. Best-effort: the item is already queued, so a
    /// refusal here just means the app imports on next launch instead.
    @MainActor
    private func openHostApp() async {
        guard let url = SharedImportInbox.openURL, let context = extensionContext else { return }
        await withCheckedContinuation { continuation in
            context.open(url) { _ in continuation.resume() }
        }
    }

    // MARK: - UI

    fileprivate enum Status {
        case working
        case saved
        case failed(String)
    }

    private func presentStatus(_ status: Status) {
        let host = UIHostingController(rootView: ShareStatusView(status: status))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    @MainActor
    private func finish(after status: Status) async {
        presentStatus(status)
        // Long enough to read a failure, brief on success.
        let delay: Duration = {
            if case .failed = status { return .seconds(2.0) }
            return .milliseconds(350)
        }()
        try? await Task.sleep(for: delay)

        if case .failed(let message) = status {
            extensionContext?.cancelRequest(
                withError: NSError(
                    domain: "rcw.Julia.ShareExtension",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            )
        } else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    fileprivate struct ShareStatusView: View {
        let status: Status

        var body: some View {
            VStack(spacing: 14) {
                switch status {
                case .working:
                    ProgressView()
                    Text("Sending to Julia…")
                        .font(.headline)
                case .saved:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    Text("Sent to Julia")
                        .font(.headline)
                case .failed(let message):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial)
        }
    }
}
