# Codebase audit — 2026-09-03

Audit of `chore/dependency-toolchain-audit` after merging the Foundation Models
work from `main` (`61e889b`). Findings are ordered by severity. Each says
whether it was **fixed** in this pass or is **open**.

The merge that preceded this audit is documented in [MERGE-NOTES.md](MERGE-NOTES.md).
Actionable follow-up is tracked in [TODO.md](TODO.md). The two fixed bugs have
detailed write-ups in [bugs/](bugs/).

---

## 1. Import is completely broken without Apple Intelligence — **FIXED**

`RecipeProcessor.classifyText` has no fallback:

```swift
// Julia/Utilities/RecipeProcessor.swift
private func classifyText(_ reconstructedLines: [String]) async throws -> ClassificationResult {
    return try await FoundationModelsRecipeClassifier().classify(reconstructedLines)
}
```

`FoundationModelsService.generate` throws `.unavailable` whenever
`SystemLanguageModel.default.availability != .available` — an unsupported
device, a region without Apple Intelligence, or the user simply having it
switched off. Every image and text import then fails with an error alert.
There is no degraded mode.

This is the highest-impact finding, because the code that used to do this job
still exists in the repo but is no longer wired to anything (see §5). Options,
roughly in order of effort:

1. Re-wire `RecipeTextClassifier` + `RecipeClassifier.mlmodel` as the fallback
   branch of `classifyText`. The model ships in the bundle already.
2. Fall back to a heuristic classifier (the reconstructor already separates
   most ingredient-shaped lines from instruction-shaped ones).
3. Accept the limitation, but detect it at import time and tell the user
   plainly rather than surfacing a generic failure.

`IngredientParser` already does the right thing here — it checks availability
and falls back to heuristics — so the pattern exists in the codebase.

**Fixed 2026-09-04** with option 3, detect-and-communicate: no new classifier
path, but `failIfModelUnavailable()` short-circuits `processImage`/`processText`
with a reason the user can act on. URL import is untouched, since JSON-LD needs
no model. See [TODO.md](TODO.md).

## 2. Classifier could overflow its context window — **FIXED**

Found by the new test suite on its first honest run: importing an ordinary
22-line recipe intermittently failed with `Exceeded model context window size`.
The same fixture had passed minutes earlier, and took 108s on the failing run
versus 18s on the passing one.

Cause: the ~4096-token budget has to cover the instructions (~579 tokens,
measured), the input lines, **and** the structured output — which echoes every input line back
into one of the arrays. A chunk therefore costs roughly twice its own token
count on top of the fixed prompt, and `chunkSize` was 150 lines. Output length
is not fully predictable, so a rambling generation on messy text tips it over.

Fixed in `FoundationModelsRecipeClassifier`:

- `chunkSize` 150 → 40.
- Added `classifyChunkSplittingOnOverflow`, which halves the chunk and retries
  on `.exceededContextWindowSize`, down to a floor of 5 lines.

A *full* 150-line chunk needed ~4,813 tokens — **117% of the budget** — so it
could not fit at all. Chunking gave no protection; it only appeared to work
because most recipes are under 150 lines and never filled a chunk.

Full analysis, including the residual risks the fix does not remove:
**[bugs/context-window-overflow.md](bugs/context-window-overflow.md)**.

## 3. Unicode fractions and ranges never parsed — **FIXED**

`IngredientParser.parseQuantity` holds all the vulgar-fraction (`½`, `⅓`) and
hyphenated-range (`2-4 cups`) logic. It was **never called**: `legacyParse`
called `parseFraction` directly at all three of its quantity sites, and
`parseFraction` handles only `1/2`-style fractions and plain numbers.

So `½ cup butter` parsed as a *name* of `"½ cup butter"` with no quantity.

**This was initially recorded as affecting only the no-Apple-Intelligence
fallback. That understated it.** `fromString` → `legacyParse` has six
production call sites — every persisted import, both chat tools, and all manual
ingredient entry — while the AI path has one, which is itself unreachable
(§4). `legacyParse` was not a fallback; it was the only ingredient parser that
ever ran.

Fixed by pointing those three sites at `parseQuantity`; covered by new tests in
`IngredientParsingTests`. **Not** fixed: already-saved ingredients keep the bad
values, since the fix is forward-only.

Full analysis: **[bugs/ingredient-quantity-parsing.md](bugs/ingredient-quantity-parsing.md)**.

## 4. The Foundation Models ingredient parser has never run — **FIXED**

Discovered while tracing §3. The AI ingredient parser is unreachable:

```
FoundationModelsIngredientParser ← fromStringAsync ← convertToSwiftDataModelAsync ← nothing
```

`RecipeData` has two conversions. `convertToSwiftDataModelAsync()` uses
`IngredientParser.fromStringAsync` (Foundation Models, structured output);
`convertToSwiftDataModel()` uses `fromString` (heuristic). Both
`RecipeProcessor` call sites use the **synchronous** one:

```
RecipeProcessor.swift:173  →  recipeData.convertToSwiftDataModel()
RecipeProcessor.swift:284  →  data.convertToSwiftDataModel()
```

and `convertToSwiftDataModelAsync()` has no callers anywhere in the repo.

So structured ingredient parsing — quantity, unit, name and comment split
properly by the model — has never executed in production. Every ingredient goes
through positional `split(separator: " ")` heuristics, which is also why §3 hit
everything rather than just a fallback.

**Fixed 2026-09-04.** `saveRecipe()` is now async and calls
`convertToSwiftDataModelAsync()`. `autoSave()` stays synchronous and heuristic
on purpose — it is a safety net that `saveRecipe()` replaces, so paying for
model calls there would double the AI cost per import and race the dedupe.

`fromStringAsync` now escalates to the model only for parses the heuristic
scored below 0.7, so a clean "2 cups flour" costs no model call. See
[TODO.md](TODO.md).

## 5. Dead Core ML pipeline still shipping — **FIXED**

The Foundation Models migration left the old pipeline in place but unreferenced:

| Item | Size | References |
|------|------|-----------|
| `Julia/Utilities/RecipeTextClassifier.swift` | 36 lines | none |
| `Julia/RecipeClassifier.mlmodel` | 368 KB | none in Swift |
| `Julia/IngredientClassifier.mlmodel` | 48 KB | none in Swift |

Both `.mlmodel` files are still in the app target's **Sources** phase, so they
are compiled and shipped — ~416 KB of bundle for code that nothing calls.

**Fixed 2026-09-04.** Moved to `Archive/CoreML-legacy/` and out of the app
target's Sources phase, so the ~416 KB no longer ships. Archived rather than
deleted — still the obvious starting point for a real no-AI fallback.

⚠️ `RecipeTextClassifier.swift` also declared `RecipeLineType`, used by five
files, so this was not a straight move: the enum now lives in
`Julia/Models/RecipeLineType.swift`. See [DONE.md](DONE.md).

## 6. Confidence UI is now inert — **FIXED**

`ProcessingResultsClassifiedText` colours lines and offers a "skipped only"
filter based on `confidence < RecipeProcessor.confidenceThreshold` (0.65). But
`FoundationModelsRecipeClassifier.toClassificationResult` hardcodes `1.0` for
every line:

```swift
classified.append((line, type, 1.0))
let skipped = r.unknown.map { ($0, .unknown, 1.0) }
```

So every line reads as maximum confidence, the colouring never varies, and the
"skipped only" filter can never match anything.

**Partially resolved 2026-09-04.** The line-number redesign gave the classifier
a real signal to emit: a line the model *did* classify records 1.0, while a line
it omitted — defaulted to `.unknown` by `buildResult` — records **0.3**, below
the 0.65 threshold. So the colouring and the "skipped only" filter now surface
something meaningful: the lines the model failed to account for.

**Closed 2026-09-04.** Decided against inventing a graded score. The UI now
names the binary signal honestly — "Unclassified Only", a "Not classified"
badge, and "Unclassified first" ordering — with the misleading numeric column
removed. See [DONE.md](DONE.md).

## 7. `parsely-swiftui/` is not in the build — **FIXED**

A 9-file, ~976-line SwiftPM package (`Package.swift`, `RecipeScraper`, a full
set of views) sits at the repo root and is referenced **nowhere** in
`Julia.xcodeproj`. The app's actual scraper is `RecipeWebScraper` in
`Julia/Utilities/RecipeWebExtractor.swift`.

**Fixed 2026-09-04.** `parsely-swiftui/README.md` marks it a spike, records
that it is in no target, and points at `RecipeWebScraper` instead. Code kept.

## 8. Crash-on-failure paths — **FIXED**

```swift
// Julia/Utilities/DataController.swift:79 — inside the error handler for a failed container
return try! ModelContainer(for: Ingredient.self)
```

This runs *after* container creation has already failed, and force-tries a
second one; when that fails the app crashes instead of surfacing the error it
just went to the trouble of posting a notification about.

Also three `try! NSRegularExpression` in `Julia/Models/RecipeData.swift`.

**Fixed 2026-09-04.** The container now degrades to an in-memory store over the
real schema instead of force-trying a second on-disk one with a different
schema; the regexes are `static let`, compiled once. See [DONE.md](DONE.md).

## 9. Colour strategy is split — **OPEN**

The merge resolved every colour conflict toward `Color.app.*` design tokens, as
chosen. Two things remain inconsistent, both flagged at merge time:

- Main introduced hardcoded colours **outside** the conflicts, which the merge
  left untouched: `Dot.swift:28` `private let buttonColor = Color(red: 1.0, green: 0.30, blue: 0.15)`,
  plus several `.foregroundStyle(.white)` calls.
- The token choice diverges visually from main's new toolbar styling.
  `NavigationView.swift:300` and `RecipeDetails.editingMenu` use
  `Color.app.white` at 40×40, while main's other toolbar buttons are 30×30
  `.regularMaterial`. Worth eyeballing in the simulator before deciding.

Deciding this properly means picking one rule — e.g. *system semantic colours
for neutrals, `Color.app.*` for brand* — and applying it everywhere, including
main's new code.

## 10. Smaller items — **MIXED**

| Finding | Status |
|---|---|
| Test suite had **every `#expect` commented out** — it logged, asserted nothing | fixed, see [TESTING.md](TESTING.md) |
| `TestState.init` built a processor with a model context then immediately overwrote it with `RecipeProcessor()`, discarding the context | fixed (harness rewritten) |
| Test assets referenced names (`trout_with_haricots_verts_capers_and_lemons`) that do not exist on disk, so the one live test passed vacuously in 0.012s | fixed (auto-discovery) |
| `JuliaTests` deployment target was 17.6 against a 26.0 host, so the test target could not build **on `main` either** | fixed (→ 26.0) |
| `ProcessingTextResult` is a typealias declared in a *view* file (`ProcessingResultsReconstructedText.swift:11`) for a type used throughout the pipeline | open |
| Project-level baseline is 17.6 while both real targets are 26.0 | open, harmless |
| `JuliaTests/TestResult.swift` is unreferenced after the harness rewrite | open, left in place deliberately |
| `Julia/Info.plist` was an empty `<dict/>` alongside `GENERATE_INFOPLIST_FILE = YES` | now holds `CFBundleURLTypes` |

---

## Not findings

Checked and healthy:

- **Build is warning-clean.** The only output is a benign "No AppIntents.framework
  dependency found" metadata note.
- `JuliaTools` (`AddToGroceryListTool`, `CreateRecipeTool`) *is* wired up —
  `ChefChatView.swift:490` registers both with `LanguageModelSession(tools:)`.
- `DataController.appSchema` correctly registers all seven `@Model` types at
  version 2.2.2.
- Foundation Models sessions are created fresh per request, which correctly
  avoids context accumulation between independent classifications.
