//
//  SharedImportInboxTests.swift
//  JuliaTests
//
//  The hand-off between the share extension and the app. Untested until now,
//  and the failure mode is silent: a note shared from Notes that never arrives
//  looks like nothing happened.
//
//  These run against the real App Group container, which the simulator
//  provisions without entitlement enforcement. Every test drains first so it
//  starts from a known state, and drains after so it leaves one.
//

import Testing
import Foundation
@testable import Julia

// .serialized because the inbox is a single shared directory — parallel tests
// would consume each other's items.
@Suite("Share extension inbox", .serialized)
struct SharedImportInboxTests {

    /// Empties the inbox so a test neither inherits nor leaves state.
    private func clear() {
        SharedImportInbox.drain()
    }

    // MARK: - Round trip

    @Test("An enqueued text item comes back unchanged")
    func textRoundTrip() throws {
        clear()
        defer { clear() }

        let body = "Roast Chicken\n\n1 whole chicken\nSalt\n\nRoast at 425F."
        try SharedImportInbox.enqueue(.text(body))

        let item = try #require(SharedImportInbox.dequeue())
        #expect(item == .text(body), "multi-line text must survive the JSON round trip")
    }

    @Test("An enqueued URL item comes back unchanged")
    func urlRoundTrip() throws {
        clear()
        defer { clear() }

        let url = "https://example.test/recipes/roast-chicken?utm_source=share"
        try SharedImportInbox.enqueue(.url(url))

        let item = try #require(SharedImportInbox.dequeue())
        #expect(item == .url(url), "query strings must not be mangled")
    }

    // MARK: - Queue behaviour

    @Test("Items are dequeued oldest first")
    func dequeueIsFIFO() throws {
        clear()
        defer { clear() }

        // The app imports one at a time, so ordering is what stops a later
        // share jumping ahead of an earlier one.
        for index in 1...3 {
            try SharedImportInbox.enqueue(.text("item \(index)"))
        }

        #expect(SharedImportInbox.dequeue() == .text("item 1"))
        #expect(SharedImportInbox.dequeue() == .text("item 2"))
        #expect(SharedImportInbox.dequeue() == .text("item 3"))
        #expect(SharedImportInbox.dequeue() == nil)
    }

    @Test("Dequeuing removes the item, so it cannot be imported twice")
    func dequeueConsumes() throws {
        clear()
        defer { clear() }

        try SharedImportInbox.enqueue(.text("once"))
        #expect(SharedImportInbox.dequeue() != nil)
        #expect(SharedImportInbox.dequeue() == nil, "the same share must not import twice")
    }

    @Test("An empty inbox dequeues to nil rather than throwing")
    func emptyDequeue() {
        clear()
        #expect(SharedImportInbox.dequeue() == nil)
        #expect(!SharedImportInbox.hasPendingItems)
    }

    @Test("hasPendingItems reflects the queue without consuming it")
    func pendingDoesNotConsume() throws {
        clear()
        defer { clear() }

        #expect(!SharedImportInbox.hasPendingItems)
        try SharedImportInbox.enqueue(.text("waiting"))
        #expect(SharedImportInbox.hasPendingItems)
        #expect(SharedImportInbox.hasPendingItems, "checking twice must not drain it")
        #expect(SharedImportInbox.dequeue() != nil)
    }

    @Test("Drain returns everything at once, oldest first")
    func drainReturnsAll() throws {
        clear()
        defer { clear() }

        try SharedImportInbox.enqueue(.text("a"))
        try SharedImportInbox.enqueue(.url("https://example.test/b"))

        let items = SharedImportInbox.drain()
        #expect(items == [.text("a"), .url("https://example.test/b")])
        #expect(SharedImportInbox.dequeue() == nil, "drain should have emptied it")
    }

    // MARK: - Robustness

    @Test("A corrupt entry is discarded and does not block the queue")
    func corruptEntryIsSkipped() throws {
        clear()
        defer { clear() }

        // A truncated write, or a payload from a future version. The queue must
        // keep moving rather than wedging on it — one unreadable file should not
        // strand every share behind it.
        try SharedImportInbox.enqueue(.text("good"))
        try writeRawEntry("{ this is not valid json", named: "0000000000.0-corrupt.json")

        let items = SharedImportInbox.drain()
        #expect(items == [.text("good")])
        #expect(!SharedImportInbox.hasPendingItems, "the corrupt file should have been removed too")
    }

    @Test("Non-JSON files in the directory are ignored")
    func nonJSONIgnored() throws {
        clear()
        defer { clear() }

        try writeRawEntry("not an item", named: "README.txt")
        #expect(!SharedImportInbox.hasPendingItems)
        #expect(SharedImportInbox.dequeue() == nil)
    }

    // MARK: - Deep link recognition

    @Test("The extension's hand-off link is recognised", arguments: [
        "julia://import",
        "JULIA://IMPORT",
        "julia://import?ignored=1"
    ])
    func recognisesImportLink(raw: String) throws {
        let url = try #require(URL(string: raw))
        #expect(SharedImportInbox.isImportLink(url), "\(raw) should trigger a drain")
    }

    @Test("Unrelated links are not treated as a hand-off", arguments: [
        "julia://settings",
        "https://example.test/import",
        "shortcuts://run-shortcut?name=julia"
    ])
    func rejectsOtherLinks(raw: String) throws {
        let url = try #require(URL(string: raw))
        #expect(!SharedImportInbox.isImportLink(url))
    }

    @Test("The link the extension opens is the one the app recognises")
    func openURLMatchesRecogniser() throws {
        // Both sides derive from the same constants, so this guards against one
        // being changed without the other.
        let url = try #require(SharedImportInbox.openURL)
        #expect(SharedImportInbox.isImportLink(url))
    }

    // MARK: - Helpers

    /// Writes a file directly into the inbox, bypassing `enqueue`, to simulate
    /// something the app did not write.
    private func writeRawEntry(_ contents: String, named name: String) throws {
        let container = try #require(
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: SharedImportInbox.appGroupID
            ),
            "App Group \(SharedImportInbox.appGroupID) is not available — check the entitlement"
        )
        let inbox = container.appendingPathComponent("ImportInbox", isDirectory: true)
        try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        try contents.write(to: inbox.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
}
