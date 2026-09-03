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
