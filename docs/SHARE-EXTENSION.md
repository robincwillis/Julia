# Share extension — importing from Notes and Safari

Lets you select text in a note, or hit Share on a recipe page, and send it
straight into Julia's import pipeline.

## Flow

```
Notes / Safari share sheet
  → JuliaShareExtension (ShareViewController)
      → extract text or URL from NSItemProvider
      → SharedImportInbox.enqueue(...)        writes JSON into the App Group container
      → extensionContext.open("julia://import")
  → Julia (NavigationView)
      → SharedImportInbox.dequeue()
      → RecipeProcessor.importSharedText / importSharedURL
      → existing pipeline → review sheet
```

The item is **queued before** the deep link is attempted, so nothing is lost if
opening the app is refused or the user dismisses. The app drains the queue on
launch, when it becomes active, and when the deep link arrives.

## Pieces

| Path | Role |
|---|---|
| `Shared/SharedImportInbox.swift` | The hand-off. Member of **both** targets — keep it Foundation-only |
| `JuliaShareExtension/ShareViewController.swift` | Extracts the payload, queues it, opens the app |
| `JuliaShareExtension/Info.plist` | `NSExtensionActivationRule` — one web URL, or text |
| `JuliaShareExtension/JuliaShareExtension.entitlements` | App Group |
| `Julia/Julia.entitlements` | Same App Group, app side |
| `Julia/Info.plist` | `CFBundleURLTypes` registering `julia://` |
| `RecipeProcessor.importSharedURL` / `importSharedText` | Headless entry points |

Identifiers, all of which must agree:

- App Group: **`group.rcw.Julia`**
- URL scheme: **`julia://import`**
- Extension bundle id: **`rcw.Julia.ShareExtension`**

## One setup step before running on a device

The simulator does not enforce entitlement provisioning; a real device does.
Enable the App Group once:

1. Xcode → target **Julia** → Signing & Capabilities → **+ Capability** →
   App Groups → check `group.rcw.Julia`.
2. Repeat for the **JuliaShareExtension** target.

With automatic signing Xcode registers the group against team `KU2HAE7AMY` and
regenerates both profiles. Until that is done, device builds fail to sign, and
`SharedImportInbox.enqueue` throws `InboxError.appGroupUnavailable` — which the
extension surfaces as a readable message rather than silently dropping a note.

## Behaviour worth knowing

**A URL beats text.** Sharing a Safari page hands over both the page URL and
its title as text. The URL is what we want to scrape, so it wins.

**A shared bare link becomes a URL import.** Notes sometimes gives a link as
plain text. `bareURL(in:)` treats the payload as a link only when the detected
link spans the *entire* string, so a note that merely mentions a URL is still
imported as text.

**One at a time.** Importing runs through a single shared `RecipeProcessor`, so
two shares in quick succession would fight over its state. The app takes the
oldest item, imports it, and picks up the next when the review sheet is
dismissed. Nothing is dropped — each share is its own file in the queue.

**Images are not accepted.** The activation rule covers text and web URLs only;
photos are already handled in-app by the camera and photo pickers.

## Verified

End-to-end on the simulator: an item queued into the App Group container was
drained within 2s of `julia://import`, classified by Apple Intelligence, and
presented in the review sheet with title, servings, all ingredients and all
instructions correctly categorised.

Not yet exercised: the real share sheet from Notes and Safari on a device,
which needs the capability step above. `extensionContext.open(_:)` is
best-effort for share extensions — if a future iOS refuses it, the queue plus
the foreground drain still deliver the item, just without the immediate jump.
