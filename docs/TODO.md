# TODO

Open work only, highest priority first. Completed items live in
[DONE.md](DONE.md). Findings and their status are in [AUDIT.md](AUDIT.md).

Effort is rough: **S** under an hour, **M** a session, **L** a day or more.

> **Next up:** bring the image fixtures over (Test coverage, below). The
> classifier has never been tested against real OCR, and that same evidence is
> what unblocks the deferred section-based redesign. Mind the asset-catalog
> gotcha recorded there.

Headings are descriptive rather than numbered — the old P0/P1 tiers are both
complete, and numbering the rest would either imply false urgency or start the
list at "P2".

---

## Correctness and hygiene

Was P2. Nothing here is user-visible breakage; the top item is the only one
with a real decision attached.

- [ ] **Archive the old Core ML pipeline (don't delete)** — S
  **Decided 2026-09-03.** The no-AI decision went with detect-and-communicate,
  so these are wired to nothing — but keep them.
  `RecipeTextClassifier.swift` (36 lines, no references),
  `RecipeClassifier.mlmodel` (368 KB) and `IngredientClassifier.mlmodel`
  (48 KB) are unreferenced yet still in the app target's Sources phase, so
  ~416 KB ships as dead weight. Move them out of the build phase (an
  `Archive/` folder excluded from the target) so the weight stops shipping but
  the code stays available if a fallback classifier is ever revisited.
  → [AUDIT.md §5](AUDIT.md)

- [ ] **Fix or remove the inert confidence UI** — S
  `ProcessingResultsClassifiedText` colours lines and filters "skipped only" on
  `confidence < 0.65`. Partly resolved already: lines the model omitted now
  record 0.3 against 1.0 for classified ones, so the filter finally surfaces
  something real. What remains is deciding whether a genuine per-line
  confidence is wanted beyond that binary, or whether the column should go.
  → [AUDIT.md §6](AUDIT.md)

- [ ] **Remove the crash-on-failure paths** — S
  `DataController.swift:79` force-tries a second `ModelContainer` inside the
  handler for a failed one, so it crashes instead of surfacing the error it just
  posted a notification about. Plus three `try! NSRegularExpression` in
  `RecipeData.swift` (190, 198, 207) — static patterns, so hoist to `static let`.
  → [AUDIT.md §8](AUDIT.md)

- [ ] **Decide what `parsely-swiftui/` is** — S
  9 files, ~976 lines, referenced nowhere in `Julia.xcodeproj`. Reads as live
  code and duplicates the scraper concept. Move it out or note its status.
  → [AUDIT.md §7](AUDIT.md)

- [ ] **Improve the heuristic parser for devices without Apple Intelligence** — M
  **Downgraded and re-scoped 2026-09-04.** The two cases that originally
  motivated this — `1 1/2 cups flour` and `2 cups (250 g) flour` — are now
  exactly what the confidence gate escalates to the model, so the original
  reason is spent.

  What remains is a different job: `legacyParse` is the *only* ingredient parser
  on a device without Apple Intelligence, and it is positional
  (`split(separator: " ")`), so a quantity anywhere but position 0 is never
  found. That makes this part of the no-AI story rather than parser polish.
  → [AUDIT.md §1](AUDIT.md)

- [ ] **Estimate tokens before calling, instead of discovering overflow** — M
  **Downgraded 2026-09-04.** `chars / 4` is crude but enough to split
  proactively rather than discovering overflow after ~100s. Still worth having,
  but the risk it guards shrank: a 40-line chunk now sits at ~24% of budget
  rather than ~42%, so overflow needs the model to over-generate roughly 4×,
  and halve-and-retry already catches that.

- [ ] **Tidy leftovers** — S
  `JuliaTests/TestResult.swift` is unreferenced since the harness rewrite.
  `ProcessingTextResult` is a pipeline-wide typealias declared in a *view* file
  (`ProcessingResultsReconstructedText.swift:11`).

## Test coverage

Was P4. The first item is the highest-value work on this list.

- [ ] **Bring the existing test assets over from the other machine** — M
  A library of recipe images and some text files sits on another computer, in
  `JuliaTests/Test Images.xcassets/` and `JuliaTests/Test Assets/`. Both are
  excluded by `.gitignore:43-44`, which is why they exist on one machine only.

  ⚠️ **Before copying anything:** `TestAssets.images()` enumerates *loose files*
  in the test bundle. Asset-catalog images compile into `Assets.car` and cannot
  be enumerated at runtime — they are only reachable by name via
  `UIImage(named:in:)`, which is exactly why the old harness needed a hardcoded
  `imageNames` array. **Copying the `.xcassets` over as-is will discover zero
  images.**

  Two ways out:
  - *Preferred* — export the catalog contents as loose files into
    `Fixtures/Images/`. Keeps the file-drop workflow, no code change.
  - Add a catalog path to `TestAssets` alongside discovery, accepting that
    catalog fixtures need their names listed somewhere.

  Then settle the `.gitignore` question: committing fixtures is what makes the
  suite reproducible across machines and CI, and the current pain is exactly the
  cost of not doing it. Weigh against repo size — recipe-page JPEGs run a few
  hundred KB each. A middle path is committing a small curated set and leaving
  the bulk library ignored.
  → [TESTING.md](TESTING.md)

- [ ] **Stress-test with real scans, not just clean or hand-messed text** — M
  **This is the evidence the deferred redesign waits on.** A paper estimate
  against a clean 38-line blog recipe came to only ~49% of budget in a single
  call; the real risk concentrates in genuinely messy OCR — multi-column
  reading-order errors, garbled characters, higher effective line counts from
  fragmentation — which a typed fixture cannot reproduce.

  Matters doubly now that the `{lineNumber, category}` redesign dropped inline
  OCR correction: real scans are the only way to see whether
  uncorrected-but-categorised garble is good enough, or whether correction needs
  a new home in the pipeline.

  Depends on the item above.

- [ ] **Add adversarial text fixtures** — S
  Two fixtures today, one clean and one 46-line multi-chunk. The reconstructor
  exists to handle mess, so it should be tested with mess: messy OCR dumps, blog
  preamble before the recipe, multiple recipes on one page, ad-interleaved text,
  incomplete recipes, ingredient lists with `1 1/2` space-separated mixed
  numbers.

- [ ] **Add a URL test set** — S
  URL import is covered by two hand-written HTML fixtures. Keep the suite
  offline and deterministic — the reason fixtures were chosen over live requests
  — but make refreshing easy: `Fixtures/Web/urls.txt` as the list of source
  pages, plus a small script that curls each into a `.html` fixture. One command
  to re-capture when a site changes its markup, and the list doubles as
  documentation of what is covered.

  Vary the JSON-LD shape, since that is what the parser branches on: direct
  `@type: Recipe`, `@graph`-nested, `recipeInstructions` as strings vs
  `HowToStep` objects, all three `author` shapes, `recipeYield` as string vs
  array. Client-side-rendered pages have no JSON-LD and belong in a separate
  group — they exercise the AI fallback, not this path.

- [ ] **Harden the Apple Intelligence test gate** — S
  `.enabled(if: availability == .available)` is evaluated before any request,
  and the model can report available then still refuse to generate — so the
  suite goes **red instead of skipping** for environmental reasons. Seen
  2026-09-03: both pipeline tests failing in 3.7s with `GenerationError error
  -1` against code byte-identical to a 38/38 run earlier the same day.

  Options: probe with one trivial generation in a suite-level trait and skip if
  it throws; or catch `.assetsUnavailable`/`.rateLimited` in the test helper and
  record a skip rather than a failure. Either way the signal should distinguish
  "the model would not answer" from "the pipeline is broken".
  → [TESTING.md](TESTING.md)

- [ ] **Cover the share extension** — M
  `SharedImportInbox` has no unit tests. `enqueue`/`dequeue` ordering, corrupt
  JSON being skipped, and `isImportLink` are all cheap. The `bareURL(in:)`
  heuristic deserves tests too, but lives in the extension target, which has no
  test host.

- [ ] **Verify the share sheet on a real device** — S
  Needs the App Groups capability first (see Setup). Only the simulator hand-off
  has been exercised end to end; the real Notes and Safari share sheets have
  not. → [SHARE-EXTENSION.md](SHARE-EXTENSION.md)

## Design consistency

Was P3. Yours, and gated on the Figma review.

- [ ] **Review designs in Figma and come back with changes** — M *(Robin)*
  Screenshots taken 2026-09-03; mapping in
  [figma-screenshot-mapping.md](figma-screenshot-mapping.md) and
  [figma-build-spec.md](figma-build-spec.md). **This gates the two items
  below** — both are open questions about which visual direction wins, and a
  review answers them rather than guessing. Worth settling the colour rule as
  part of it.

- [ ] **Settle one colour rule and apply it everywhere** — M
  The merge resolved every conflict to `Color.app.*`, but `main` introduced
  hardcoded colours outside the conflict regions that were left untouched:
  `Dot.swift:28` `Color(red: 1.0, green: 0.30, blue: 0.15)`, plus several
  `.foregroundStyle(.white)`. Suggested rule: system semantic colours for
  neutrals, `Color.app.*` for brand. → [AUDIT.md §9](AUDIT.md)

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

- [ ] **Timer in live cooking mode** — M
  `CookModeView` has no timer of any kind today — greenfield, not an addition.

  ⚠️ **Deep-linking the native Clock app is not supportable.** Apple publishes
  no URL scheme for creating a timer. Undocumented schemes (`clock-alarm://` and
  similar) have circulated but are private API in practice — they break between
  iOS versions and are an App Review risk. Worth a check before committing
  either way, but do not plan around it.

  What actually delivers the goal — a timer that keeps running and alerts you
  while you are not looking at the app:
  - **`ActivityKit` Live Activity** — Lock Screen and Dynamic Island, which is
    the behaviour people want from a cooking timer. Needs
    `NSSupportsLiveActivities` in `Info.plist` and a widget extension (a second
    extension target, so `JuliaShareExtension` is the template for the
    project-file side).
  - **`UNUserNotificationCenter` with a time-interval trigger** — the reliable
    alert, and it fires even if the app is killed. Needed regardless: the Live
    Activity is presentation, the notification is the guarantee.

  Multiple concurrent timers are the interesting design problem, since recipes
  have overlapping steps. `Step` has no duration field, so parsing "simmer 20
  minutes" out of instruction text — or capturing a duration during import — is
  a prerequisite for a timer per step rather than one generic one.

- [ ] **Two app icons, and shipping with debug on or off** — M, approach undecided
  Captured as-is; **not resolved.** Two icon designs exist and need preparing
  and testing. Separately, the app should be archivable in two modes: debug
  features on by default, or off.

  The thought was that the two icons might *correspond* to those modes, so a
  debug build is identifiable on the Home Screen — but it could equally be a
  user preference unrelated to debug.

  Current state, which shapes the options:
  - `debugMode` is a `UserDefaults` bool registered **`true`** by default at
    `JuliaApp.swift:22`, surfaced as `\.debugMode` in the environment and
    toggled by a switch at `SettingsDrawer.swift:151`. So every build today
    ships with debug on, user-switchable at runtime.
  - One `AppIcon.appiconset`, wired via
    `ASSETCATALOG_COMPILER_APPICON_NAME`. Alternate icons need
    `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` plus
    `UIApplication.shared.setAlternateIconName(_:)`, which is unused so far.

  Roughly independent axes:
  1. *Debug default per build* — flip the registered default from the build
     configuration (`#if DEBUG`, or a custom
     `SWIFT_ACTIVE_COMPILATION_CONDITIONS` flag so a Release archive can still
     be built with debug on).
  2. *Icon follows debug mode* — call `setAlternateIconName` when the flag
     changes. Cheap, and makes a debug build obvious. Note iOS shows a system
     alert when an app changes its icon, which is intrusive if it fires off a
     settings toggle.
  3. *Icon as user preference* — a picker in `SettingsDrawer`, unrelated to
     debug. No alert problem when the user initiated it.
  4. *Two schemes / configurations* — a separate "Julia Debug" archive with its
     own bundle id, so both install side by side. Most work, but the only option
     that keeps a debug and a normal build on one device.

  Settle 1 before 2/3: whether the icon follows a build flag or a user setting
  decides where the code lives.

## Setup, not code

- [ ] **Enable the App Groups capability** — S
  Xcode → target **Julia** → Signing & Capabilities → + Capability → App Groups
  → `group.rcw.Julia`. Repeat for **JuliaShareExtension**. Device builds will
  not sign until this is done; the simulator does not enforce it.

- [ ] **Decide whether `Package.resolved` is tracked** — S
  `6b5cbe4` removed it deliberately; Xcode has regenerated it and it is
  currently untracked. `.gitignore:41` has the rule commented out. Either commit
  it for reproducible dependency resolution or uncomment the rule. Worth
  settling — SwiftSoup has already resolved to two different versions (2.13.6
  and 2.8.5) across runs.

- [ ] **Review the hand-edited project file** — S
  The `JuliaShareExtension` target was added by editing `project.pbxproj`
  directly. It builds, embeds correctly, and `xcodebuild -list` sees it, but
  worth opening in Xcode to confirm nothing looks off in the UI.
