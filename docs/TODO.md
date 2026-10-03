# TODO

Open work only, highest priority first. Completed items live in
[DONE.md](DONE.md). Findings and their status are in [AUDIT.md](AUDIT.md).

Effort is rough: **S** under an hour, **M** a session, **L** a day or more.

> **Next up:** the 🚨 urgent data-loss item below is blocked on a real-device
> test — it can't be driven further from here. Everything else on this list
> is lower priority than that.

Headings are descriptive rather than numbered — the old P0/P1 tiers are both
complete, and numbering the rest would either imply false urgency or start the
list at "P2".

---

## 🚨 URGENT — data loss on every app close

**Needs verification on a real device — cannot be reproduced or tested in the
sandbox this was diagnosed in (Linux, no Xcode/simulator/device access).**

Reported 2026-09-27: recipes, pantry, and grocery data are lost every time the
app is closed and reopened.

**Confirmed bug, fixed blind:** `DataController.appContainer`
(`Julia/Utilities/DataController.swift`) already had a safety net — if the
on-disk SwiftData store fails to load, it silently falls back to an
**in-memory** container so the app doesn't crash. That matches the symptom
exactly (app works normally, everything vanishes on relaunch). The alert meant
to surface this to the user could never fire: it was wired through a
`NotificationCenter` observer registered in `JuliaApp.onAppear`, but
`appContainer` is force-initialized earlier — by `.modelContainer(...)`
building the scene, before the view hierarchy (and thus `onAppear`) exists —
so the notification was posted before anything listened for it. Total silent
failure, no crash, no alert.

Fixed: replaced the notification race with a synchronous flag
(`DataController.isRunningInMemoryFallback` / `.containerLoadError`) that
`JuliaApp` checks directly and deterministically in `onAppear`. If the
fallback engages, an unmissable alert now shows: *"Data Isn't Being
Saved... Recipes, ingredients, and lists will NOT be saved once you close the
app."*

**Code review confirmed (2026-09-28):** The alert wiring is correct and
race-free. `containerLoadError` is set synchronously inside the `appContainer`
lazy initializer (before the view hierarchy exists), so `onAppear`'s check is
guaranteed to see it. The alert message includes the underlying error string.

**Still open — why the on-disk container is failing (if it is).** Two scenarios:
- *Container load throws* → `isRunningInMemoryFallback = true` → alert fires.
  Console will show `"Error creating app container: ..."`.
- *SwiftData silently replaces a store it cannot migrate* (no throw, no
  fallback, fresh empty store) → no alert, data just vanishes. This would not
  be caught by the current mechanism at all and would need a different
  diagnostic approach.

Leading suspect for either scenario: the 2.2.2 → 2.2.3 schema bump adding
`InstructionSection`. The new model and its relationships should be handled by
SwiftData's automatic lightweight migration, but `@Relationship(originalName:)`
annotations on new-in-2.2.3 properties (`Step.section`, `InstructionSection.recipe`)
might confuse the migration engine — `originalName` is normally a rename hint,
so SwiftData might look for a column that doesn't exist in the old schema.

**To verify:**
1. Build to a real device, force-quit, relaunch.
2. If the "Data Isn't Being Saved" alert appears → container load is throwing.
   Check console for the error string to decide whether a `SchemaMigrationPlan`
   is needed or whether the `originalName` annotations need removing.
3. If the alert does *not* appear and data still disappears → silent store
   replacement. Add `print` after `ModelContainer(for: appSchema)` succeeds to
   confirm it's reaching that line, then check whether the store file's
   modification date changes on relaunch. Add a `SchemaMigrationPlan` with an
   explicit lightweight stage as the next step.
4. If neither happens (data persists) → the original report was a development
   environment artifact (simulator reset, Xcode reinstall). Close this item.

---

## Design consistency

Was P3. Yours, and gated on the Figma review.

- [ ] **Review designs in Figma, screen by screen** — M *(Robin, in progress)*
  Screenshots taken 2026-09-03; mapping in
  [figma-screenshot-mapping.md](figma-screenshot-mapping.md) and
  [figma-build-spec.md](figma-build-spec.md). The color token pass below is
  the first output of this review; the rest lands as Robin goes screen by
  screen. **This gates the items below.**
  → [design-tokens.md](design-tokens.md)

- [x] **Settle one colour rule and apply it — reds** — M, done 2026-09-12
  Consolidated `brand/primary`/`brand/danger`/`ios/systemRed`/
  `xcode/AccentColor` to one value (`#FF3900`/`#FF7445`). `danger.colorset`
  updated; `Dot.swift:28`'s hard-coded `Color(red: 1.0, green: 0.30, blue:
  0.15)` now reads `Color.app.primary`. → [design-tokens.md](design-tokens.md)

- [ ] **Reassign `background.secondary`'s call sites** — M
  New Figma tokens split the old `background.secondary` colorset into a true
  `background-secondary` (recipe details/chat, black in dark mode — decided,
  not yet applied) and a `backdrop` role now living in the new
  `background.card` colorset (`backgroundKeyboardToolbar` /
  `backgroundCard` in `Theme.swift`). The 11 existing
  `Color.app.backgroundSecondary` call sites need auditing one by one against
  the screen review to see which they actually mean — only then can
  `background.secondary` itself move to the new black-in-dark value.
  → [design-tokens.md](design-tokens.md) flag 5

- [ ] **Move `secondary` off background duty** — S
  New token notes: `brand/secondary` (`#9FC9F6`, corrected 2026-09-13 from a
  mistranscribed teal) is "not a background color, it's an alternative pop
  color, wait for special." Currently used as a `.background()`/`.fill()`
  fill well beyond the original 3 call sites — the 2026-09-13 systemBlue
  migration added the tab bar active pill, the ingredient editor's number
  pad 0 button, the instructions step-number badge, and the Ask Julia user
  chat bubble on top of the pre-existing `IngredientEditor.swift:235`,
  `RecipeEditTagsSection.swift:34`, `RecipeRawTextSection.swift:40`. Robin
  will pick the replacement per screen during the review rather than a
  blanket swap. → [design-tokens.md](design-tokens.md) flag 3

- [x] **`ios/systemBlue` "same as brand/secondary" note** — resolved
  2026-09-13: the teal hex was a transcription error, but `brand/secondary`
  turned out not to be identical to `ios/systemBlue` either — Robin's
  reference screenshots sample to `#9FC9F6`/`#5C7A99`, a lighter, more muted
  blue. `secondary.colorset` updated to that value.
  → [design-tokens.md](design-tokens.md) flag 2

- [ ] **Resolve remaining open semantic question from the token table** — S
  `brand/background-primary` vs. `brand/background-sheet` differ only by a
  few points in dark mode (`#242424` vs `#1C1C1E`) — intentional depth cue or
  picker rounding? → [design-tokens.md](design-tokens.md) flag 6

- [ ] **Audit `backgroundSecondary` vs. `backgroundSheet` call sites, especially dark mode** — M
  Found and fixed two concrete mismatches this session: `RecipeSuggestionsView`'s
  list rows and pantry/grocery filter bar, and `RecipeSuggestionDetailView`'s
  screen background, were all set to `Color.app.backgroundSheet` (`#2C2C2E`
  dark — the lighter, elevated-card tone) when the surrounding sheet actually
  uses `Color.app.backgroundSecondary` (`#1C1C1E` dark), producing a visibly
  lighter patch. Both are now `backgroundSecondary`. Given how easy this
  mismatch is to introduce (the two tokens are close enough in light mode to
  not notice, but diverge sharply in dark mode), worth a deliberate pass over
  every `Color.app.backgroundSheet` / `Color.app.backgroundSecondary` call site
  to confirm each one matches its actual container rather than catching these
  one screen at a time as they're noticed. Related to the two token-semantics
  items above — may fold into that review.

- [ ] **Reconcile toolbar button styling** — S
  `NavigationView.swift:300` and `RecipeDetails.editingMenu` use
  `Color.app.white` at 40×40; `main`'s other toolbar buttons are 30×30
  `.regularMaterial`. Look at both in the simulator and pick one.

> Note: `ProcessingResults.swift` has been touched twice recently (async save,
> then the in-flight saving state). If the UI pass lands there too, that is the
> likely collision point.

## Deferred — waiting on evidence

Not skipped, but not worth scoping until there is data to justify the size.

- [ ] **Classify by recipe section, not one monolithic pass** — L
  Added 2026-09-03; **deferred 2026-09-04.**

  Chunking by line count treats a recipe as an undifferentiated list of lines,
  so a boundary can cut through a section heading and separate it from the
  ingredients it introduces. The alternative is splitting the *classification
  task itself* by section — title/summary as one small call, ingredients as
  another, instructions as another — instead of one call classifying every line
  type at once. Each call's instructions and schema would then describe only the
  categories relevant to that section.

  **Why deferred.** Both legs of the original rationale moved:

  - *Prompt overhead per call* — largely spent. Instructions are 393 tokens now,
    and per-section prompts would only shave part of that.
  - *Context fragmentation* — chunk overlap mitigates it. And when the three
    misclassifications on a 46-line recipe were mapped to their windows, **none
    were boundary artifacts**: two were mid-window-0, one was window-1 primary
    with proper context. They were prompt problems, fixed by restoring the
    glossary.

  So there is currently **no evidence of fragmentation harm** to justify an
  L-sized redesign. The evidence that would settle it is the real-scan stress
  test above.

  **If pursued anyway, decide the target first:** budget or accuracy? Narrower
  per-section schemas might improve accuracy independently of tokens, which is a
  legitimate reason on its own — but a different design than one aimed at the
  budget.

  Open scoping questions: how sections get identified in the first place (a
  cheap pre-pass? a heuristic on blank lines and headings?), whether it composes
  with or replaces line-count chunking, and how it interacts with halve-and-retry.

## Features — not yet scoped

New capability rather than fixes. Unranked between themselves.

- [ ] **Edit or update a recipe with Foundation Models** — L
  Let the model modify an existing recipe, not just import one: "make this
  vegetarian", "double it", "convert to metric", "swap the cream for something
  lighter".

  Hooks that already exist: `JuliaTools.swift` has `CreateRecipeTool` and
  `AddToGroceryListTool` registered with `LanguageModelSession(tools:)` at
  `ChefChatView:490`. An `UpdateRecipeTool` is the natural third and would work
  conversationally with no new UI.

  The distinction that matters: import operates on `RecipeData` (a struct of
  string arrays), but editing operates on a persisted `Recipe` (`@Model`, with
  relationships to `Ingredient`, `Step`, `Timing`, `Note`, `IngredientSection`).
  A tool that rewrites a `Recipe` must reconcile relationships rather than
  replace arrays — deleting and recreating `Ingredient` rows loses their
  `position` ordering and any grocery-list membership.

  Open questions: does an edit apply directly or land in a review sheet like
  imports do? Is it undoable? And which operations should be AI at all — scaling
  is arithmetic, and "double it" through an LLM will occasionally get it wrong.

- [ ] **Two app icons** — M, scaffolded 2026-10-03, **needs real art + device verification**
  Decided: the icon is **not** tied to the `debugMode` settings toggle at all
  (that stays a separate, user-switchable, per-session thing). Two independent
  mechanisms instead, both scaffolded with placeholder artwork — nothing here
  has been run on a device or in Xcode, since this sandbox can't do either:

  1. **Light/dark primary icon** — `AppIcon.appiconset/Contents.json` now has
     `appearances: [{appearance: luminosity, value: dark}]` entries for the
     five Home-Screen-visible sizes (120, 180, 152, 167, 1024), each pointing
     at a `<size>-dark.png` placeholder (an programmatically darkened copy of
     the light version — not real dark art). This needs iOS 18+ to render,
     which the app's iOS 26 minimum covers, and needs no code — purely an
     asset-catalog mechanism. **To verify:** build to a device, switch system
     appearance, confirm the Home Screen icon actually changes.

  2. **Dev/TestFlight icon** — a new `AppIcon-Dev.appiconset` (placeholder: the
     primary icon with an orange corner ribbon, same sizes), registered via
     `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` (both build configs) and
     `CFBundleIcons`/`CFBundleAlternateIcons` in `Info.plist`. `JuliaApp`
     switches to it automatically on launch — no user action — via a new
     `isDevOrTestFlightBuild` check (`#if DEBUG`, or for Release, whether
     `Bundle.main.appStoreReceiptURL` points at a `sandboxReceipt`, which is
     how a TestFlight install differs from an App Store one), guarded so it
     only calls `setAlternateIconName` when the icon actually needs to change
     (that call shows a system alert — confirmed by this item's own original
     research — so an unguarded call on every launch would be bad). **To
     verify:** a Debug build and a TestFlight build should both pick up the
     dev icon automatically; an App Store build should not, and the alert
     should fire once, not every launch.

  **Still needed:** real artwork for both the dark primary icon and the dev
  icon — everything currently on disk is a generated placeholder so the
  mechanism could be built and reviewed, not final art.

## Setup, not code

- [ ] **Enable the App Groups capability** — S
  Xcode → target **Julia** → Signing & Capabilities → + Capability → App Groups
  → `group.rcw.Julia`. Repeat for **JuliaShareExtension**. Device builds will
  not sign until this is done; the simulator does not enforce it.

- [x] **Decide whether `Package.resolved` is tracked** — resolved
  It's tracked: `Julia.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
  is committed, and the `.gitignore:41` rule is still commented out, consistent
  with that choice. Worth a one-time check that it currently resolves to a
  single consistent SwiftSoup version rather than the 2.13.6/2.8.5 split seen
  before, but the tracking decision itself is settled.

- [ ] **Review the hand-edited project file** — S
  The `JuliaShareExtension` target was added by editing `project.pbxproj`
  directly. It builds, embeds correctly, and `xcodebuild -list` sees it, but
  worth opening in Xcode to confirm nothing looks off in the UI.
