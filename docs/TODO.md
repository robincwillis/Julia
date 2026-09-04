# TODO

Development backlog, highest priority first. Started 2026-09-03 from the
findings in [AUDIT.md](AUDIT.md) and the two bug write-ups in [bugs/](bugs/).

Effort is rough: **S** under an hour, **M** a session, **L** a day or more.

**Next up:** bringing the image fixtures over (P4). The classifier has never
been tested against real OCR, and that same evidence is what unblocks the
deferred section-based redesign. Note the asset-catalog gotcha recorded there.

---

## P0 — Users hit these ✅ complete

- [x] **Give `classifyText` a fallback for when Apple Intelligence is unavailable** — S
  **Done 2026-09-04.** `RecipeProcessor.failIfModelUnavailable()` checks
  `SystemLanguageModel.default.availability` at the top of `processImage` and
  `processText` and surfaces `ModelErrorMessage.message(for:)` through the
  normal error UI. Deliberately *not* applied to `importSharedURL` — the
  scraper prefers JSON-LD and only falls back to the model, so a well-marked-up
  page still imports without Apple Intelligence.

  One constraint found while implementing: the API exposes only
  `.deviceNotEligible`, `.appleIntelligenceNotEnabled` and `.modelNotReady`.
  **There is no distinct "unsupported region" case** — regional ineligibility
  arrives as `.deviceNotEligible`, so that copy covers device and region
  together rather than claiming a distinction the API cannot make.

  **Decided 2026-09-03: detect and communicate (option 3).** No new
  classifier path. Check `SystemLanguageModel.default.availability` up front
  (mirror the pattern `IngredientParser` already uses) and short-circuit
  before calling `classifyText` with a clear message distinguishing
  unsupported device / unsupported region / setting off — not the raw
  `localizedDescription`. Share messaging logic with the error-mapping item
  right below, since both need to turn model errors into something a user
  can act on.
  → [AUDIT.md §1](AUDIT.md)

- [x] **Wire up `convertToSwiftDataModelAsync` so the AI ingredient parser actually runs** — M
  **Done 2026-09-04.** `saveRecipe()` is now `async` and calls
  `convertToSwiftDataModelAsync()`, so the chain
  `FoundationModelsIngredientParser ← fromStringAsync ← convertToSwiftDataModelAsync ← saveRecipe`
  is connected for the first time. `ProcessingResults.saveRecipe` became
  `() async -> Bool`; both button call sites wrap in `Task`.

  **Divergence from the plan, on purpose:** `autoSave()` stays **synchronous
  and heuristic**. The plan called for both to support an async path, but that
  copy is a safety net `saveRecipe()` deletes and replaces, so running the
  model per ingredient there would double the AI cost of an import, stall the
  moment the review sheet appears, and race a quick save against
  `autoSavedRecipe` being set. Good parsing matters on the copy the user keeps.

  **Scoring needed one rule beyond the four decided.** `2 cups (250 g) flour`
  scored 1.0 on the strength of a recognized `cups` and so would never have
  escalated — despite being listed as a case escalation should catch. Added
  `adjust(_:forName:)`: any score above 0.6 is capped at 0.6 when the resulting
  *name* still contains digits or a parenthetical, since that means content was
  left unparsed. Covered by `IngredientParsingTests`.
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

- [x] **Map model errors to something a user can act on** — S
  **Done 2026-09-04.** `ModelErrorMessage.friendlyMessage(for:)` in
  `Julia/Utilities/ModelErrorMessage.swift`, wired into all three
  `handleError` sites (`processImage`, `processText`, `importSharedURL`).
  Covers the four decided cases with the drafted copy; everything else falls
  through to `localizedDescription`, so `FoundationModelsServiceError` and
  `WebScrapeError` pass through untouched as intended.
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

## P1 — Robustness of the import pipeline ✅ complete

Two items were downgraded to P2 and one deferred — see those sections.

- [x] **Stop the classifier output echoing its input** — L
  **Done 2026-09-04, option 1.** `ClassifiedRecipe`'s ten string arrays are
  replaced by `ClassifiedLines` — an array of `{lineNumber, category}` where
  `category` is a `@Generable` **enum** (`LineCategory`), so an invalid category
  is unrepresentable rather than something to parse and defend against.

  Measured effect: instructions 579 → **181 tokens** (68% shorter, since the
  ten-category glossary moved into `@Guide` descriptions the framework already
  sends as schema, and the OCR-correction section is gone). A 40-line chunk went
  from ~42% of budget to **~24%**; a 22-line chunk from 30% to **15%**.
  `allTextFixtures` runtime halved, 16.1s → 8.9s.

  **The omission risk is handled.** With no text in the response, a line number
  the model skips would silently drop an ingredient. `buildResult` therefore
  walks the *input* in document order and looks each line up, so a line the
  model never returned is still present, categorised `.unknown`. Hallucinated
  numbers outside the chunk are dropped. Document order comes free from walking
  the input, so no sort is needed.

  Verified end-to-end on a sectioned recipe: title, both timings, and
  ingredients from both sections all classified correctly.
  → [bugs/context-window-overflow.md](bugs/context-window-overflow.md)
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

- [x] **Shrink the instruction prompt** — M
  **Done 2026-09-04: 579 → 393 tokens**, by dropping the OCR-correction
  section, which no longer applies now that the model returns no text.

  An intermediate version got to 181 tokens by also dropping the ten-category
  glossary, on the mistaken belief it had moved into `@Guide` descriptions on
  `LineCategory`. It had not — `@Generable` on an enum sends only the case
  *names*, and there is no per-case `@Guide`. Accuracy fell measurably, so the
  glossary is back. Do not remove it again without a per-case mechanism.

- [x] **Overlap chunk boundaries** — M
  **Done 2026-09-04.** `makeChunks` returns `ChunkWindow` values carrying their
  absolute start, and every window after the first is prefixed with 5 lines of
  preceding context. De-duplication is first-write-wins: a window's leading
  overlap lines were primary in the previous window, where they had full
  context, so that verdict wins — and a line the previous window omitted still
  gets a second chance. 21 tests in `ClassifierChunkingTests` pin the
  windowing, since an off-by-one here loses ingredients silently.

- [x] **Fix the stale comment in `FoundationModelsRecipeClassifier`** — S
  **Done 2026-09-04.** The comment was rewritten wholesale by the echo fix and
  no longer quotes a token figure that can drift.

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

- [ ] **Estimate tokens before calling, instead of discovering overflow** — M
  **Downgraded from P1 2026-09-04.** `chars / 4` is crude but enough to split
  proactively rather than discovering overflow after ~100s. Still worth having,
  but the risk it guards shrank a lot: a 40-line chunk now sits at ~24% of
  budget instead of ~42%, so overflow needs the model to over-generate roughly
  4×, and halve-and-retry already catches that.

- [ ] **Improve the heuristic parser for devices without Apple Intelligence** — M
  **Downgraded and re-scoped from "Harden `legacyParse`" 2026-09-04.** The two
  cases that motivated it — `1 1/2 cups flour` (space-separated mixed number)
  and `2 cups (250 g) flour` — are now exactly what the confidence gate
  escalates to the model, so the original reason is spent.

  What remains is a different job: `legacyParse` is the *only* ingredient
  parser on a device without Apple Intelligence, and it is positional
  (`split(separator: " ")`), so quantities away from position 0 are never
  found. That makes this part of the no-AI story rather than parser polish —
  see [AUDIT.md §1](AUDIT.md), which chose detect-and-communicate for
  classification but left ingredient parsing on the heuristic.

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

## Deferred — waiting on evidence

Not skipped, but not worth scoping until there is data to justify the size.

- [ ] **Classify by recipe section, not one monolithic pass** — L
  Added 2026-09-03; **deferred 2026-09-04.**

  Chunking by line count treats a recipe as an undifferentiated list of lines,
  so boundaries can cut through a section heading and separate it from the
  ingredients it introduces. The alternative is to split the *classification
  task itself* by recipe section — title/summary as one small call, ingredients
  as another, instructions as another — instead of one call classifying every
  line type at once. Each call's instructions and output schema would then
  describe only the categories relevant to that section.

  Open scoping questions, if it goes ahead: how sections get identified in the
  first place (a cheap pre-pass? a heuristic on blank lines and headings?),
  whether it composes with or replaces line-count chunking, and how it
  interacts with the halve-and-retry overflow logic.

  **Why deferred.** Both legs of the original rationale moved:

  - *Prompt overhead per call* — largely spent. Instructions are 393 tokens
    now, and per-section prompts would only shave part of that.
  - *Context fragmentation* — chunk overlap (P1, done) mitigates it. And when
    the three misclassifications on a 46-line recipe were mapped to their
    windows, **none were boundary artifacts** — two were mid-window-0, one was
    window-1 primary with proper context. They were prompt problems, fixed by
    restoring the glossary.

  So there is currently **no evidence of fragmentation harm** to justify an
  L-sized redesign. The evidence that would settle it is already on the list:
  the OCR stress test with real scans in P4. Messy multi-column OCR — fragmented
  lines, higher effective line counts, no clean headings — is where boundaries
  should actually hurt. Run that first: either boundary-shaped errors appear and
  this is justified, or they do not and it is speculative.

  **If pursued anyway, decide the target first:** budget or accuracy? Narrower
  per-section schemas might improve accuracy independently of tokens, which is a
  legitimate reason on its own — but it is a different design than one aimed at
  the token budget.

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
