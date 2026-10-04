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

**2026-10-04 analysis:** this hypothesis holds up under static review and looks
like the most likely fix, not just a suspect. `originalName` exists specifically
to tell SwiftData "this property used to be called X in an earlier schema
version" — but `Step.section` and `InstructionSection.recipe` are *brand new* in
2.2.3, so there is no earlier name for them to have had. Inverse-relationship
pairing between `Step`/`Recipe`/`InstructionSection` doesn't need `originalName`
either: each type has exactly one `[Step]`-typed property on the other side
(`Recipe.instructions`, `InstructionSection.steps`), so SwiftData's automatic
type-based inverse inference should pair them correctly without any hint.

**Fix applied 2026-10-04, confidence tempered:** removed `originalName: "steps"`
from `Step.section` and `originalName: "instructionSections"` from
`InstructionSection.recipe` — both new in 2.2.3, neither ever had a prior name.
Bumped the schema to `Schema.Version(2, 2, 4)`. Left every other `recipe`
back-reference alone (`Ingredient`, `IngredientSection`, `Note`, `Timing`,
`Step.recipe` itself) — all four use the identical `originalName:` pattern and
all predate 2.2.3, which is itself evidence *against* this being the bug: if
the pattern reliably broke migration, `IngredientSection`'s own introduction
(an earlier schema bump) should have shown the same symptom and apparently
didn't. So this fix is safe and worth keeping regardless, but may not be the
actual cause — still completely unverified on a device, since this sandbox
cannot run SwiftData migration at all.

**To verify:**
1. Build to a real device, force-quit, relaunch.
2. If data now persists → fix confirmed, close this item.
3. If the "Data Isn't Being Saved" alert still appears → container load is
   still throwing. Check console for the error string — the `originalName` fix
   wasn't the (whole) cause, and a `SchemaMigrationPlan` is likely needed next.
4. If the alert does *not* appear and data still disappears → silent store
   replacement, a different failure mode than the alert catches. Add `print`
   after `ModelContainer(for: appSchema)` succeeds to confirm it's reaching
   that line, then check whether the store file's modification date changes on
   relaunch. Add a `SchemaMigrationPlan` with an explicit lightweight stage as
   the next step.
5. If none of the above and data still disappears even after a clean reinstall
   → the original report may have been a development environment artifact
   (simulator reset, Xcode reinstall) rather than a code bug. Close this item.

---

## Scoped, ready to build

- [ ] **Classify by recipe section, not one monolithic pass** — L, un-deferred 2026-10-04, goal: accuracy
  Added 2026-09-03; deferred 2026-09-04 for lack of evidence; **Robin decided
  2026-10-04 to pursue it anyway**, without waiting for the real-scan stress
  test (that evidence item was in the "Test coverage" section removed as
  stale, and isn't coming back as a prerequisite). Goal is explicitly
  **accuracy**, not token budget — narrower per-section schemas should reduce
  misclassification even though prompt overhead is already fairly spent
  (393 tokens today).

  **Scoped design:**
  1. **Boundary identification** — a cheap heuristic pre-pass over
     `RecipeTextReconstructor`'s output, not a second model call: blank-line
     gaps plus heading-like lines (short, title-case, ends with `:` — the
     same shape `looksLikeSectionHeading` in `RecipeDetails.swift` already
     uses for a related purpose) to carve the line list into title/summary,
     ingredients, and instructions chunks before classification.
  2. **Per-section schemas** — `FoundationModelsRecipeClassifier`'s one long
     instruction set and `ClassifiedRecipe` schema split into narrower
     per-section instructions/schemas that only describe the line types
     relevant to that section (an ingredients-only call doesn't need to know
     about instruction or title line types).
  3. **Composes with, doesn't replace, existing chunking** — section-splitting
     happens first (coarse, free); the existing 40-line halve-and-retry
     chunking still applies *within* a section if that section alone is long
     (e.g. a 60-line ingredient list), unchanged from today.

  **Cannot be tested from this sandbox at all** — Foundation Models requires
  on-device Apple Intelligence, and this environment is Linux with no
  device/simulator access. This is a scoped plan ready to implement, not
  implemented code; building it here would mean writing classifier prompt
  changes with zero ability to run or iterate on them. Needs a session with
  real device access to build and tune.

## Features — not yet scoped

New capability rather than fixes. Unranked between themselves.

- [x] **Edit or update a recipe with Foundation Models** — confirmed merged 2026-10-04, two of three gaps closed same day
  Built, via two separate mechanisms rather than the single `UpdateRecipeTool`
  originally sketched here:

  1. **Conversational** — `UpdateRecipeTool` (`JuliaTools.swift`), registered
     with `LanguageModelSession(tools:)` in `ChefChatView.setupSession()`
     alongside `CreateRecipeTool`/`AddToGroceryListTool`. Applies directly, no
     review step — confirmed as the intended flow, not just a stopgap. Takes
     title/description/servings/full-ingredient-replace/full-instruction-replace;
     "replace" fields delete-and-rebuild rather than reconcile in place.
  2. **Menu-driven** — `RecipeDetails`' "Edit with AI" (`editingMenu` →
     `runAIEdit`/`applyAIEdit`), a larger pipeline that also detects and
     restructures ingredient/instruction *sections*, with an optional custom
     instruction field.

  **Closed 2026-10-04:**
  - **Section blindness in `UpdateRecipeTool`** — added `replaceIngredientSections`/
    `replaceInstructionSections` (plus `IngredientSectionUpdate`/
    `InstructionSectionUpdate` generable structs) alongside the existing
    unsectioned-only fields, same delete-and-rebuild pattern. Also fixed
    `ChefChatView.buildRecipeContext` — it only ever read the unsectioned
    `recipe.ingredients`/`.instructions` arrays, so the model never saw a
    recipe's sections existed at all; the new tool fields would have been
    unreachable without this. Untested on a device — can't run Foundation
    Models from this sandbox.
  - **No undo** — `ModelContext.undoManager` set once at launch
    (`JuliaApp.onAppear`, shared via `.modelContainer(...)`'s environment
    injection). `UpdateRecipeTool.call` and `RecipeDetails.applyAIEdit` now
    wrap their mutations in `beginUndoGrouping()`/`endUndoGrouping()` so one
    AI edit = one undo step, exposed as "Undo Last Edit" in `editingMenu`
    (disabled when `canUndo` is false). SwiftData registers undo actions for
    context mutations automatically once `undoManager` is set — the grouping
    is just to make multi-change edits revert as one unit. Untested on a
    device.

  **Still open:**
  - **No arithmetic-vs-AI split** — scaling ("double it"), unit conversion, and
    substitutions all go through the LLM's free-text generation rather than a
    deterministic path for the parts of this that are just math. Not yet a
    reported problem, but the known failure mode is still live.

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

  **Concrete instance found and fixed 2026-10-04:** a direct commit reorganizing
  file groupings in `project.pbxproj` moved `ImportExportManager.swift`'s
  `PBXFileReference` into the `Views` group but dropped its `PBXBuildFile`
  "in Sources" entry entirely — the file was still in the Xcode navigator and
  still had content edits applied, but was no longer compiled into the app
  target at all. Re-added the missing build-file entry and its Sources-phase
  listing. This is exactly the failure mode this item warns about — worth
  having Robin open the project in Xcode once to sanity-check the rest, since
  this kind of drop is invisible outside Xcode's UI and this sandbox can't
  build the project to catch it mechanically either.
