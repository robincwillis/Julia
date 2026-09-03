# TODO

Development backlog, highest priority first. Started 2026-09-03 from the
findings in [AUDIT.md](AUDIT.md) and the two bug write-ups in [bugs/](bugs/).

Effort is rough: **S** under an hour, **M** a session, **L** a day or more.

---

## P0 — Users hit these

- [ ] **Give `classifyText` a fallback for when Apple Intelligence is unavailable** — L
  Image and text import fail outright on an unsupported device, an unsupported
  region, or with the setting simply off. There is no degraded mode.
  Decide between: re-wiring `RecipeTextClassifier` + `RecipeClassifier.mlmodel`
  (still in the bundle, §5); a heuristic classifier off the reconstructor; or
  accepting the limit but detecting it up front and saying so clearly.
  **This blocks the dead-code decision below — settle it first.**
  → [AUDIT.md §1](AUDIT.md)

- [ ] **Wire up `convertToSwiftDataModelAsync` so the AI ingredient parser actually runs** — M
  `FoundationModelsIngredientParser` has never executed in production. The
  chain is broken at the top: nothing calls `convertToSwiftDataModelAsync()`,
  so both `RecipeProcessor` sites use the synchronous heuristic parser.
  Note `saveRecipe()` is synchronous and returns `Bool`, so this is not a
  one-line swap — it needs an async save path, and `autoSave()` too.
  → [bugs/ingredient-quantity-parsing.md](bugs/ingredient-quantity-parsing.md)

- [ ] **Migrate ingredients saved with unparsed fractions** — M
  The quantity fix is forward-only. Everything already saved from `½ cup
  butter` still has `quantity == nil` and the fraction stuck in `name`.
  Re-parse ingredients whose `name` still contains a vulgar-fraction character
  or a leading digit. Needs a schema version bump or a one-shot flag in
  `UserDefaults`.

- [ ] **Map model errors to something a user can act on** — S
  `RecipeProcessor.handleError` surfaces raw `localizedDescription`, so people
  see "Exceeded model context window size". Nobody can do anything with that.
  Cover at least `.exceededContextWindowSize`, `.guardrailViolation`,
  `.rateLimited` and `.assetsUnavailable`.

## P1 — Robustness of the import pipeline

- [ ] **Stop the classifier output echoing its input** — L
  The structural fix for the context window: the response restates every input
  line, so output exceeds input and a chunk costs ~2× its own tokens. Asking
  for `[lineNumber: category]` instead of ten arrays of full strings would cut
  output to a few tokens per line and roughly halve total cost — turning the
  overflow from "rarer" into "structurally impossible" for normal input.
  Touches `ClassifiedRecipe` and `toClassificationResult`.
  → [bugs/context-window-overflow.md](bugs/context-window-overflow.md)

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

- [ ] **Resolve the old Core ML pipeline** — S once P0 is decided
  `RecipeTextClassifier.swift` (36 lines, no references),
  `RecipeClassifier.mlmodel` (368 KB) and `IngredientClassifier.mlmodel`
  (48 KB) are unreferenced but still in the app target's Sources phase, so
  ~416 KB ships. Either becomes the P0 fallback or gets deleted. Don't delete
  before P0 is settled. → [AUDIT.md §5](AUDIT.md)

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

- [ ] **Add image fixtures** — S
  `JuliaTests/Fixtures/Images/` is empty, so the OCR and image-pipeline suites
  no-op. Drop in photos of real recipes — printed cookbook pages and phone
  screenshots both. → [TESTING.md](TESTING.md)

- [ ] **Add adversarial text and web fixtures** — S
  Currently one clean text fixture and two hand-written HTML pages. The
  reconstructor exists to handle mess, so it should be tested with mess: messy
  OCR dumps, blog preamble before the recipe, multiple recipes in one page,
  ad-interleaved text, incomplete recipes. For `Web/`, save real pages with
  `curl`.

- [ ] **Cover the share extension** — M
  `SharedImportInbox` has no unit tests. `enqueue`/`dequeue` ordering, corrupt
  JSON being skipped, and `isImportLink` are all cheap to test. The
  `bareURL(in:)` heuristic in `ShareViewController` deserves tests too but
  currently lives in the extension target, which has no test host.

- [ ] **Verify the share sheet on a real device** — S
  Needs the App Groups capability first (below). Only the simulator hand-off
  has been exercised end to end; the actual Notes and Safari share sheets have
  not. → [SHARE-EXTENSION.md](SHARE-EXTENSION.md)

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
