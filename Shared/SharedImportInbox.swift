//
//  SharedImportInbox.swift
//  Julia + JuliaShareExtension
//
//  Hand-off between the share extension and the app. This file is a member of
//  BOTH targets — keep it dependency-free (Foundation only) so it stays that
//  way.
//
//  The extension cannot talk to the running app directly, so it writes each
//  shared item as a JSON file into a shared App Group container and then
//  deep-links the app. The app drains the directory on launch, on foreground,
//  and when the deep link arrives. Using one file per item means two shares in
//  quick succession cannot clobber each other, and nothing is lost if the app
//  never comes forward.
//

import Foundation

/// One thing the user shared into Julia.
enum SharedImport: Codable, Equatable {
    /// Recipe text, e.g. the body of a note.
    case text(String)
    /// A recipe page to scrape.
    case url(String)
}

enum SharedImportInbox {

    // MARK: - Configuration

    /// Must match the App Group entitlement on both the app and the extension.
    static let appGroupID = "group.rcw.Julia"

    /// Custom scheme the extension uses to bring the app forward.
    static let urlScheme = "julia"

    /// Deep link the extension opens after queueing an item.
    static var openURL: URL? {
        URL(string: "\(urlScheme)://import")
    }

    /// True when `url` is the extension's hand-off link.
    static func isImportLink(_ url: URL) -> Bool {
        url.scheme?.lowercased() == urlScheme && url.host?.lowercased() == "import"
    }

    // MARK: - Errors

    enum InboxError: LocalizedError {
        case appGroupUnavailable

        var errorDescription: String? {
            switch self {
            case .appGroupUnavailable:
                return "Julia's shared storage is unavailable. Check that the "
                     + "App Group \(SharedImportInbox.appGroupID) is enabled for "
                     + "both the app and the share extension."
            }
        }
    }

    // MARK: - Locations

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private static var inboxURL: URL? {
        containerURL?.appendingPathComponent("ImportInbox", isDirectory: true)
    }

    // MARK: - Writing (share extension side)

    /// Queues one shared item. Throws if the App Group is not configured, so
    /// the extension can tell the user rather than silently dropping a note.
    static func enqueue(_ item: SharedImport) throws {
        guard let inboxURL else { throw InboxError.appGroupUnavailable }

        try FileManager.default.createDirectory(at: inboxURL, withIntermediateDirectories: true)

        // Timestamp + UUID keeps ordering readable and collisions impossible.
        let name = "\(Date().timeIntervalSince1970)-\(UUID().uuidString).json"
        let data = try JSONEncoder().encode(item)
        try data.write(to: inboxURL.appendingPathComponent(name), options: .atomic)
    }

    // MARK: - Reading (app side)

    /// Returns everything queued and removes it. Order is oldest first.
    /// Unreadable entries are discarded rather than blocking the queue.
    @discardableResult
    static func drain() -> [SharedImport] {
        guard let inboxURL,
              let names = try? FileManager.default.contentsOfDirectory(atPath: inboxURL.path)
        else { return [] }

        var items: [SharedImport] = []
        for name in names.sorted() where name.hasSuffix(".json") {
            let fileURL = inboxURL.appendingPathComponent(name)
            defer { try? FileManager.default.removeItem(at: fileURL) }

            guard let data = try? Data(contentsOf: fileURL),
                  let item = try? JSONDecoder().decode(SharedImport.self, from: data)
            else { continue }
            items.append(item)
        }
        return items
    }

    /// Removes and returns the oldest queued item, or nil when empty.
    ///
    /// Preferred over `drain()` on the app side: importing runs through a
    /// single shared `RecipeProcessor`, so two shares processed at once would
    /// fight over its state. The app takes one, imports it, then asks again.
    static func dequeue() -> SharedImport? {
        guard let inboxURL,
              let names = try? FileManager.default.contentsOfDirectory(atPath: inboxURL.path)
        else { return nil }

        for name in names.sorted() where name.hasSuffix(".json") {
            let fileURL = inboxURL.appendingPathComponent(name)
            let data = try? Data(contentsOf: fileURL)
            try? FileManager.default.removeItem(at: fileURL)

            guard let data,
                  let item = try? JSONDecoder().decode(SharedImport.self, from: data)
            else { continue }  // discard corrupt entries and keep going
            return item
        }
        return nil
    }

    /// Whether anything is waiting, without consuming it.
    static var hasPendingItems: Bool {
        guard let inboxURL,
              let names = try? FileManager.default.contentsOfDirectory(atPath: inboxURL.path)
        else { return false }
        return names.contains { $0.hasSuffix(".json") }
    }
}
