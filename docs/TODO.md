# TODO

Development backlog, highest priority first. Started 2026-09-03 from the
findings in [AUDIT.md](AUDIT.md) and the two bug write-ups in [bugs/](bugs/).

Effort is rough: **S** under an hour, **M** a session, **L** a day or more.

---

## P0 — Users hit these

- [ ] **Give `classifyText` a fallback for when Apple Intelligence is unavailable** — S
  **Decided 2026-09-03: detect and communicate (option 3).** No new
  classifier path. Check `SystemLanguageModel.default.availability` up front
  (mirror the pattern `IngredientParser` already uses) and short-circuit
  before calling `classifyText` with a clear message distinguishing
  unsupported device / unsupported region / setting off — not the raw
  `localizedDescription`. Share messaging logic with the error-mapping item
  right below, since both need to turn model errors into something a user
  can act on.
  → [AUDIT.md §1](AUDIT.md)

- [ ] **Wire up `convertToSwiftDataModelAsync` so the AI ingredient parser actually runs** — M
  `FoundationModelsIngredientParser` has never executed in production. The
  chain is broken at the top: nothing calls `convertToSwiftDataModelAsync()`,
  so both `RecipeProcessor` sites use the synchronous heuristic parser.
  Note `saveRecipe()` is synchronous and returns `Bool`, so this is not a
  one-line swap — it needs an async save path, and `autoSave()` too.

  **Decided 2026-09-03: keep `legacyParse` as the primary parser; bolt FM on
  top as a confidence-gated upgrade rather than a full replacement.**
  `legacyParse` doesn't currently score confidence — derive it from how the
  parse resolved:
  - single word, nothing to misparse → 1.0
  - quantity **and** recognized unit found → 1.0
  - quantity found, unit not recognized (absorbed into name) → 0.6
  - `parseQuantity` failed entirely, whole string dumped into `name` → 0.3

  Threshold at 0.7. `fromString` (sync) is unchanged — all 6 sync call sites
  keep current behavior. `fromStringAsync` changes: run `legacyParse` first;
  confidence ≥ 0.7 returns immediately with no FM call; below 0.7 and FM
  available escalates to `FoundationModelsIngredientParser`; otherwise keeps
  the heuristic result. This should catch the known-bad cases like
  `1 1/2 cups flour` (space-separated mixed number) and
  `2 cups (250 g) flour`.

  The async wiring problem doesn't go away — `convertToSwiftDataModelAsync`
  still needs `saveRecipe()`/`autoSave()` to support an async path before any
  of this runs during import.
  → [bugs/ingredient-quantity-parsing.md](bugs/ingredient-quantity-parsing.md)

~~**Migrate ingredients saved with unparsed fractions**~~ — **Dropped
2026-09-03.** Not released, no production data. Checked both seed files
(`recipeData.json`, `ingredientData.json`) for the bug pattern (vulgar-fraction
characters or leading digits in `name`) — clean. They import through
`ImportExportManager.createIngredient`/`importRecipesFile` with structured
`quantity`/`unit`/`name` fields already, never touching `legacyParse`. Nothing
to migrate.

- [ ] **Map model errors to something a user can act on** — S
  `RecipeProcessor.handleError` surfaces raw `localizedDescription`, so people
  see "Exceeded model context window size". Nobody can do anything with that.
  Cover at least `.exceededContextWindowSize`, `.guardrailViolation`,
  `.rateLimited` and `.assetsUnavailable`.

  **Decided 2026-09-03:** single helper, e.g. `friendlyMessage(for error:
  Error) -> String`, switching on `LanguageModelSession.GenerationError`
  cases and falling back to `error.localizedDescription` for anything
  unhandled. Swap all three `handleError(error.localizedDescription)` call
  sites (`processImage`, `processText`, `importSharedURL`) to
  `handleError(friendlyMessage(for: error))`. This is the same helper the
  detect-and-communicate fallback above should call for the "unavailable"
  case — `FoundationModelsServiceError.unavailable` already has a good
  `errorDescription` and needs no special case, just falls through.

  Draft copy:
  - `.exceededContextWindowSize` → "This recipe is too long to process at
    once. Try splitting it into smaller sections."
  - `.guardrailViolation` → "This content couldn't be processed due to
    Apple's content safety guidelines."
  - `.rateLimited` → "Too many requests right now — wait a moment and try
    again."
  - `.assetsUnavailable` → "Apple Intelligence isn't ready on this device
    yet. Try again shortly."

## P1 — Robustness of the import pipeline

- [ ] **Stop the classifier output echoing its input** — L
  The structural fix for the context window: the response restates every input
  line, so output exceeds input and a chunk costs ~2× its own tokens.

  **Decided 2026-09-03, revised same day: option 1 — minimal
  `{lineNumber, category}`, drop OCR correction from this call.** Initially
  decided option 2 (keep `correctedText` alongside `{lineNumber, category}`),
  but a numeric check against a real recipe (38-line Mille-Feuille Nabe,
  ~2,025 tokens / ~49% of budget under the *current* design) surfaced a flaw
  in that reasoning: `ClassifiedRecipe`'s existing ten-array design already
  places each line's text in exactly one array — it is not duplicated
  per-array — so the actual "echo" cost is close to input-text-once, not a
  multiplied duplication. Keeping `correctedText` in the new shape would have
  paid the same text cost as today plus new per-line `lineNumber`/`category`
  overhead, for little or no net saving. Dropping `correctedText` entirely
  (option 1) is what actually removes the echoed text from the budget — this
  is the version that gets output down to a few tokens per line.
  Consequence: OCR correction leaves this call. `RecipeTextReconstructor`
  upstream only does structural line-joining, not text correction, so if
  OCR-garbled text correction is still wanted somewhere, it needs a new home
  — not scoped yet, revisit if it turns out to matter in practice (see the
  stress-test item below).
  Side benefit retained: sort merged results by `lineNumber` to restore true
  document order across chunk boundaries, instead of `mergeResults`' current
  chunk-concatenation order.
  Touches `ClassifiedRecipe` and `toClassificationResult`.
  → [bugs/context-window-overflow.md](bugs/context-window-overflow.md)

- [ ] **Holistically rethink context-window limits: classify by recipe section, not one monolithic pass** — L
  Added 2026-09-03, alongside the echo-fix decision above. Chunking by line
  count treats a recipe as an undifferentiated list of lines, which is why
  chunk boundaries currently cut through section headings and separate them
  from their ingredients, and why a mid-chunk's opening line can be misread
  as a title. Consider instead splitting the *classification task itself* by
  recipe section — title/summary/tags as one (small, cheap) call, ingredients
  as another, instructions as another — rather than one call classifying
  every line type at once per chunk. Each call's instructions and output
  schema would only need to describe the categories relevant to that
  section, which also shrinks the ~579-token fixed instruction overhead per
  call (see the P1 prompt-shrinking item below — this may subsume or reshape
  that item once scoped). Needs real scoping: how sections are first
  identified (a cheap pre-pass? heuristic on blank lines/headings?), whether
  this composes with or replaces line-count chunking, and how it interacts
  with the halve-and-retry overflow logic.

- [ ] **Estimate tokens before calling, instead of discovering overflow** — M
  `chars / 4` is crude but enough to split proactively. Today the first
  overflow costs ~100s before it fails.

- [ ] **Shrink the instruction prompt** — M
  ~579 tokens of fixed overhead on every call, retries included — 14% of the
  window. Much of the ten-category explanation could move into `@Guide`
  descriptions on `ClassifiedRecipe`, which the framework already sends.

- [ ] **Overlap chunk boundaries** — M
  `chunkSize = 40` splits more recipes than 150 did, and each chunk is
  classified blind to the others: `mergeResults` takes the first non-empty
  title, mid-recipe chunks can misread their opening lines as a title, and
  section headings get separated from their ingredients. A few lines of overlap
  plus de-duplication on merge would fix it.

- [ ] **Harden `legacyParse` for real-world formats** — M
  Positional `split(separator: " ")` means `1 1/2 cups flour` (space-separated
  mixed number — very common) parses as quantity 1, name `1/2 cups flour`.
  Also `2 cups (250 g) flour` keeps the parenthetical in the name. Lower value
  if the AI parser gets wired up, but it stays the fallback.

- [ ] **Fix the stale comment in `FoundationModelsRecipeClassifier`** — S
  Says the instructions cost ~900 tokens; measured ~579.

## P2 — Dead code and hygiene

- [ ] **Archive the old Core ML pipeline (don't delete)** — S
  **Decided 2026-09-03:** P0 fallback went with detect-and-communicate, so
  these aren't wired to anything — but keep them, don't delete.
  `RecipeTextClassifier.swift` (36 lines, no references),
  `RecipeClassifier.mlmodel` (368 KB) and `IngredientClassifier.mlmodel`
  (48 KB) are unreferenced but still in the app target's Sources phase, so
  ~416 KB ships as dead weight. Move out of the Sources build phase (e.g. into
  an `Archive/` folder excluded from the target) so the ~416 KB stops shipping
  but the code stays available if a fallback classifier is revisited later.
  → [AUDIT.md §5](AUDIT.md)

- [ ] **Fix or remove the inert confidence UI** — S
  `ProcessingResultsClassifiedText` colours lines and filters "skipped only"
  on `confidence < 0.65`, but the classifier hardcodes `1.0` for every line.
  The colouring never varies and the filter can never match.
  → [AUDIT.md §6](AUDIT.md)

- [ ] **Decide what `parsely-swiftui/` is** — S
  9 files, ~976 lines, referenced nowhere in `Julia.xcodeproj`. Reads as live
  code and duplicates the scraper concept. Move it out or note its status.

- [ ] **Remove the crash-on-failure paths** — S
  `DataController.swift:79` force-tries a second `ModelContainer` inside the
  handler for a failed one, so it crashes instead of surfacing the error it
  just posted a notification about. Plus three `try! NSRegularExpression` in
  `RecipeData.swift` (190, 198, 207) — static patterns, so hoist to
  `static let`.

- [ ] **Tidy leftovers** — S
  `JuliaTests/TestResult.swift` is unreferenced since the harness rewrite.
  `ProcessingTextResult` is a pipeline-wide typealias declared in a *view*
  file (`ProcessingResultsReconstructedText.swift:11`).

## P3 — Design consistency

- [ ] **Review designs in Figma and come back with changes** — M *(Robin)*
  Screenshots taken 2026-09-03. **This gates the two items below** — both are
  open questions about which visual direction wins, and a design review answers
  them rather than guessing. Worth deciding the colour rule as part of it.
  The Figma MCP is connected, so design context can be pulled into a session
  once there is a file to work from.

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

## P4 — Test coverage

- [ ] **Bring the existing test assets over from the other machine** — M
  There is a library of recipe images and some text files on another computer,
  in `JuliaTests/Test Images.xcassets/` and `JuliaTests/Test Assets/`. Both are
  excluded by `.gitignore:43-44`, which is why they exist on one machine only.

  **Gotcha worth knowing before you copy anything:** `TestAssets.images()`
  enumerates *loose files* in the test bundle. Asset-catalog images compile
  into `Assets.car` and cannot be enumerated at runtime — they are only
  reachable by name via `UIImage(named:in:)`, which is exactly why the old
  harness needed the hardcoded `imageNames` array. **Copying the `.xcassets`
  over as-is will discover zero images.**

  Two ways out:
  - *Preferred* — export the catalog contents as loose files into
    `Fixtures/Images/`. Keeps the file-drop workflow and needs no code change.
  - Add a catalog path to `TestAssets` alongside discovery, accepting that
    catalog fixtures need their names listed somewhere.

  Then decide the `.gitignore` question: **committing fixtures is what makes
  the suite reproducible across machines and CI** — the current pain is exactly
  the cost of not doing it. Weigh against repo size; JPEGs of recipe pages are
  usually a few hundred KB each. A middle path is committing a small curated
  set and leaving the bulk library ignored.
  → [TESTING.md](TESTING.md)

- [ ] **Add a URL test set** — S
  Recipe URLs are currently covered by two hand-written HTML fixtures. Keep the
  suite offline and deterministic (the reason fixtures were chosen over live
  requests), but make refreshing easy: keep `Fixtures/Web/urls.txt` as the list
  of source pages plus a small script that curls each into a `.html` fixture.
  One command to re-capture when a site changes its markup, and the list
  doubles as documentation of which sites are covered.

  Aim for variety in JSON-LD shape, since that is what the parser branches on:
  direct `@type: Recipe`, `@graph`-nested, `recipeInstructions` as strings vs
  `HowToStep` objects, all three `author` shapes, `recipeYield` as string vs
  array. Sites that render recipes client-side have no JSON-LD and belong in a
  separate group — they exercise the AI fallback, not this path.

- [ ] **Add adversarial text fixtures** — S
  One clean fixture today. The reconstructor exists to handle mess, so it
  should be tested with mess: messy OCR dumps, blog preamble before the recipe,
  multiple recipes on one page, ad-interleaved text, incomplete recipes,
  ingredient lists with `1 1/2` space-separated mixed numbers (see the
  `legacyParse` item in P1).

  **Added 2026-09-03: also stress-test with actual scanned/photographed
  recipe images, not just clean or hand-messed text.** A paper estimate
  against a clean 38-line blog recipe came out to only ~49% of the 4,096
  token budget in a single call — real risk concentrates in genuinely messy
  OCR output (multi-column reading-order errors, garbled characters, longer
  effective line counts from fragmentation), which a typed fixture doesn't
  reproduce. This matters doubly now that the classifier's `{lineNumber,
  category}` redesign above drops inline OCR correction — need real scans to
  see whether uncorrected-but-categorized OCR garble is good enough for
  usable output, or whether correction needs a new home in the pipeline.

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
  JSON being skipped, and `isImportLink` are all cheap to test. The
  `bareURL(in:)` heuristic in `ShareViewController` deserves tests too but
  currently lives in the extension target, which has no test host.

- [ ] **Verify the share sheet on a real device** — S
  Needs the App Groups capability first (below). Only the simulator hand-off
  has been exercised end to end; the actual Notes and Safari share sheets have
  not. → [SHARE-EXTENSION.md](SHARE-EXTENSION.md)

## Features — not yet scoped

New capability rather than fixes. Unranked between themselves.

- [ ] **Edit or update a recipe with Foundation Models** — L
  Let the model modify an existing recipe, not just import a new one: "make
  this vegetarian", "double it", "convert to metric", "swap the cream for
  something lighter".

  Concrete hooks that already exist:
  - `JuliaTools.swift` has `CreateRecipeTool` and `AddToGroceryListTool`
    registered with `LanguageModelSession(tools:)` in `ChefChatView:490`. An
    `UpdateRecipeTool` is the natural third and would make this work
    conversationally with no new UI.
  - The distinction that matters: import operates on `RecipeData` (a struct of
    string arrays), but editing operates on a persisted `Recipe` (`@Model`,
    with relationships to `Ingredient`, `Step`, `Timing`, `Note`,
    `IngredientSection`). A tool that rewrites a `Recipe` has to reconcile
    relationships rather than replace arrays — deleting and recreating
    `Ingredient` rows loses their `position` ordering and any grocery-list
    membership.

  Open questions: does the edit apply directly or land in a review sheet like
  imports do (`ProcessingResults`)? Is it undoable? A scaling change is
  arithmetic and does not need a model at all — worth deciding which
  operations are AI and which are deterministic, since "double it" done by an
  LLM will occasionally get arithmetic wrong.

- [ ] **Timer in live cooking mode** — M
  `CookModeView` currently has no timer of any kind — this is greenfield, not
  an addition to something existing.

  **On deep-linking the native Clock app: there is no supported way to do
  this.** Apple publishes no URL scheme for creating a timer in Clock.
  Undocumented schemes (`clock-alarm://` and similar) have circulated, but they
  are private API in practice — they break between iOS versions and are an App
  Review risk. Worth a check before committing either way, but do not plan
  around it.

  What actually delivers the goal — a timer that keeps running and alerts you
  while you are not looking at the app:
  - **`ActivityKit` Live Activity** — timer on the Lock Screen and in the
    Dynamic Island, which is the behaviour people want from a cooking timer.
    Requires `NSSupportsLiveActivities` in `Info.plist` and a widget extension
    (a second extension target, so the `JuliaShareExtension` work is a template
    for the project-file side).
  - **`UNUserNotificationCenter` with a time-interval trigger** — the reliable
    alert, and it fires even if the app is killed. Needed regardless; the Live
    Activity is presentation, the notification is the guarantee.
  - Multiple concurrent timers are the interesting design problem, since
    recipes have several overlapping steps. `Step` has no duration field today,
    so parsing "simmer 20 minutes" out of instruction text — or adding a
    duration to `Step` during import — is a prerequisite for offering a timer
    per step rather than a generic one.

- [ ] **Two app icons, and shipping with debug on or off** — M, approach undecided
  Captured as-is; not resolved. Two icon designs exist and need preparing and
  testing. Separately, the app should be archivable in two modes: debug
  features on by default, or off.

  The thought was that the two icons might *correspond* to those two modes, so
  a debug build is identifiable on the Home Screen — but it could equally be a
  user preference with no relation to debug at all. **Not decided.**

  Current state, which shapes the options:
  - `debugMode` is a `UserDefaults` bool, registered **`true`** by default in
    `JuliaApp.swift:22`, surfaced as `\.debugMode` in the environment and
    toggled by a switch in `SettingsDrawer.swift:151`. So today every build
    ships with debug on and it is user-switchable at runtime.
  - One `AppIcon.appiconset`, wired via
    `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`. Alternate icons need
    `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` plus
    `UIApplication.shared.setAlternateIconName(_:)` at runtime;
    `setAlternateIconName` is not used anywhere yet.

  The axes to pick from, roughly independent:
  1. *Debug default per build* — flip the registered default from the build
     configuration (`#if DEBUG`, or a custom `SWIFT_ACTIVE_COMPILATION_CONDITIONS`
     flag so a Release archive can still be built with debug on).
  2. *Icon follows debug mode* — call `setAlternateIconName` when the flag
     changes. Cheap, and makes a debug build obvious at a glance. Note iOS
     shows a system alert when an app changes its icon, which is intrusive if
     it fires on a settings toggle.
  3. *Icon as user preference* — a picker in `SettingsDrawer`, unrelated to
     debug. No alert problem if the user initiated it.
  4. *Two schemes / configurations* — a separate "Julia Debug" archive with its
     own bundle id, so both can be installed side by side. Most work, but the
     only option that lets you keep a debug build and a normal one on the same
     device.

  Worth settling 1 before 2/3, since whether the icon is tied to a build flag
  or a user setting decides where the code lives.

## Setup, not code

- [ ] **Enable the App Groups capability** — S
  Xcode → target **Julia** → Signing & Capabilities → + Capability → App
  Groups → `group.rcw.Julia`. Repeat for **JuliaShareExtension**. Device
  builds will not sign until this is done; the simulator does not enforce it.

- [ ] **Decide whether `Package.resolved` is tracked** — S
  `6b5cbe4` removed it deliberately; Xcode has regenerated it and it is
  currently untracked. `.gitignore:41` has the rule commented out. Either
  commit it for reproducible dependency resolution or uncomment the rule.

- [ ] **Review the hand-edited project file** — S
  The `JuliaShareExtension` target was added by editing `project.pbxproj`
  directly. It builds, embeds correctly, and `xcodebuild -list` sees it, but
  it is worth opening in Xcode to confirm nothing looks off in the UI.
