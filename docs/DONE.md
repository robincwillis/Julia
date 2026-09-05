# Completed work

Finished items moved out of [TODO.md](TODO.md), newest first. Kept rather than
deleted because several carry decisions and hard-won constraints that would
otherwise be rediscovered the hard way.

Open work lives in [TODO.md](TODO.md). Findings and their status are in
[AUDIT.md](AUDIT.md).

---

## 2026-09-04 — Correctness and hygiene

Was "P2 — Dead code and hygiene". All seven items complete.

### Archive the old Core ML pipeline — S

`RecipeClassifier.mlmodel` (368 KB), `IngredientClassifier.mlmodel` (48 KB) and
the vestigial `RecipeTextClassifier` class moved to `Archive/CoreML-legacy/` and
removed from the app target's Sources phase. Verified the models no longer
appear in the built `.app`. Archived rather than deleted: they remain the
obvious starting point if a real no-AI fallback classifier is ever wanted.

⚠️ **The backlog note was wrong and nearly cost a broken build.** It recorded
`RecipeTextClassifier.swift` as "36 lines, no references" — true of the *class*,
but the file also declared **`RecipeLineType`**, which five files use. Archiving
the file wholesale would have broken the app. The enum moved to
`Julia/Models/RecipeLineType.swift`, where a model type belongs; only the dead
class and the unreferenced `RecipeTextLine` were archived.

→ [AUDIT.md §5](AUDIT.md), `Archive/README.md`

### Relabel the inert confidence UI — S

Decided: keep the mechanism, name it honestly. The classifier emits a *binary*
signal — did the model account for this line — not a graded score, so rendering
"0.30" as a confidence implied precision that does not exist.

`ProcessingResultsClassifiedText` now reads "Unclassified Only" rather than
"Skipped Only", shows a "Not classified" badge instead of a numeric column, and
replaces sort-by-confidence (meaningless across two values) with "Unclassified
first / Document order", which keeps document order within each group.
`RecipeProcessor.confidenceThreshold` is documented as the boundary it now is.

→ [AUDIT.md §6](AUDIT.md)

### Remove the crash-on-failure paths — S

`DataController.appContainer` force-tried a *second* on-disk container inside
the handler for the first one failing — so the usual outcome was a crash moments
after going to the trouble of reporting the error. Worse, the fallback used a
different schema (`Ingredient` only), which would have failed on any `Recipe`
query anyway. It now degrades to an in-memory container over the real schema,
and only `fatalError`s if even that is impossible.

The three `try! NSRegularExpression` in `RecipeData.parseTimeString` are hoisted
to `static let` — compiled once instead of on every call, and no force-try on
literals that cannot fail.

→ [AUDIT.md §8](AUDIT.md)

### Mark `parsely-swiftui/` as a spike — S

Decided: keep the code, stop it reading as live. `parsely-swiftui/README.md`
records that it is in no target, that `RecipeWebScraper` supersedes it, and
where to look instead. Confirmed zero references in `project.pbxproj`.

→ [AUDIT.md §7](AUDIT.md)

### Improve the heuristic parser — M

`legacyParse` is the only ingredient parser on a device without Apple
Intelligence, and it was strictly positional. It now peels off non-name content
*before* tokenizing:

- **Parentheticals become comments.** `2 cups (250 g) flour` → quantity 2, unit
  cup, name "flour", comment "250 g". Previously the name was "(250 g) flour".
- **Trailing notes become comments.** `2 cups flour, sifted` → comment "sifted".
  Only when the note contains no digits — `1 lb chicken, 2 breasts` is more
  likely a botched quantity than a note, so it is left for the model.
- **Space-separated mixed numbers are one quantity.** `1 1/2 cups flour` → 1.5,
  not quantity 1 with a name of "1/2 cups flour". Guarded so a whole number is
  never mistaken for a fraction, which would consume the unit token.

Consequence worth noting: both cases the confidence gate was built to escalate
now parse fully and score 1.0, so they **stop costing model calls**. The
escalation tests were updated to cover inputs the heuristic genuinely cannot
read — `Salt and pepper to taste`, `A handful of basil`, `3 large eggs`.

### Estimate tokens before calling — M

`estimatedTokens(for:)` costs a request before making it — instructions measured
from the real string so it cannot drift, plus input at `characters / 4` with the
numbering prefix counted, plus output at 8 tokens per line. Requests estimated
above 75% of the 4,096-token window split proactively via `splitAndClassify`
rather than discovering overflow after the model has generated its way to the
end of the window, which took ~100s the one time it happened.

The reactive `.exceededContextWindowSize` path stays as the backstop, since the
estimate is crude and generation length is not predictable. Tests pin that a
normal 40-line window fits comfortably and that the old 150-line chunk is
correctly predicted not to.

### Tidy leftovers — S

`JuliaTests/TestResult.swift` deleted — unreferenced since the harness rewrite.
`ProcessingTextResult` moved out of a *view* file to sit beside the type it
aliases in `RecipeTextReconstructor.swift`; the pipeline refers to it, so a view
was the wrong owner.

---

## 2026-09-04 — P1: import pipeline robustness

Was "P1 — Robustness of the import pipeline". All four items complete.

### Classifier returns line numbers, not echoed text — L

`ClassifiedRecipe`'s ten string arrays replaced by `ClassifiedLines`: an array
of `{lineNumber, category}` where `category` is a `@Generable` **enum**
(`LineCategory`), so an invalid category is unrepresentable rather than
something to parse and defend against.

The response no longer contains the input text at all, which removes the
"output restates the input" property that caused the overflow bug.

| | before | after |
|---|---|---|
| 22-line chunk | ~1,229 tokens (30% of budget) | ~641 (15%) |
| 40-line chunk | ~1,726 (42%) | ~1,001 (24%) |
| `allTextFixtures` | 16.1s | 8.9s |

**The omission risk that came with it is handled.** With no text in the
response, a line number the model skips would silently drop an ingredient.
`buildResult` walks the *input* in document order and looks each line up, so a
line the model never returned is still present as `.unknown`; numbers outside
the chunk are discarded; a dictionary keyed by absolute index means duplicates
cannot double-append. Document order is inherent, so the sort originally planned
turned out to be unnecessary.

Decision history: option 2 (keeping `correctedText` alongside the line number)
was chosen first, then revised to option 1. Keeping the text would have paid
today's text cost plus new per-line overhead for little net saving. Consequence
accepted: **OCR correction left this call** and has no home upstream —
`RecipeTextReconstructor` only does structural line-joining. Revisit if the OCR
stress test shows uncorrected garble is not good enough.

→ [bugs/context-window-overflow.md](bugs/context-window-overflow.md)

### Shrink the instruction prompt — M

**579 → 393 tokens**, by dropping the OCR-correction section, which no longer
applies now that the model returns no text.

⚠️ An intermediate version reached 181 tokens by also dropping the ten-category
glossary, on the mistaken belief it had moved into `@Guide` descriptions on
`LineCategory`. **It had not: `@Generable` on an enum sends only the case
*names*, and there is no per-case `@Guide`.** Accuracy fell measurably on a
46-line recipe — "Total: 3 hours including cooling" classified as summary, "Heat
the oven to 175C" as a timing, "Keeps 4 days in an airtight tin" as a timing
rather than a note. The glossary is back, plus explicit notes on those three
confusions. **Do not remove it again without a per-case mechanism.**

### Overlap chunk boundaries — M

`makeChunks` returns `ChunkWindow` values carrying their absolute start, and
every window after the first is prefixed with 5 lines of preceding context.

De-duplication is first-write-wins: a window's leading overlap lines were
primary in the previous window, where they had full context, so that verdict
wins — and a line the previous window omitted still gets a second chance.

21 tests in `ClassifierChunkingTests` pin the windowing (primary ranges tile
exactly, windows match the source slice they claim, overlap is exact, nothing
exceeds the size budget, empty and exact-multiple edges behave). Off-by-one here
loses ingredients silently rather than failing loudly.

### Fix the stale token figure in the classifier comment — S

Rewritten wholesale by the echo fix; no longer quotes a figure that can drift.

---

## 2026-09-04 — P0: issues users hit

Was "P0 — Users hit these". All three live items complete, one dropped.

### Detect and communicate when Apple Intelligence is unavailable — S

Decided option 3: no new classifier path.
`RecipeProcessor.failIfModelUnavailable()` checks
`SystemLanguageModel.default.availability` at the top of `processImage` and
`processText`, surfacing `ModelErrorMessage.message(for:)` through the normal
error UI rather than running OCR first and then failing opaquely.

Deliberately **not** applied to `importSharedURL`: the scraper prefers JSON-LD
and only falls back to the model, so a well-marked-up page still imports without
Apple Intelligence. Guarding it would have removed working functionality.

⚠️ Constraint found while implementing: the API exposes only
`.deviceNotEligible`, `.appleIntelligenceNotEnabled` and `.modelNotReady`.
**There is no distinct "unsupported region" case** — regional ineligibility
arrives as `.deviceNotEligible`, so that copy covers device and region together
rather than claiming a distinction the API cannot make.

→ [AUDIT.md §1](AUDIT.md)

### Connect the AI ingredient parser, confidence-gated — M

`saveRecipe()` is now `async` and calls `convertToSwiftDataModelAsync()`, so
`FoundationModelsIngredientParser ← fromStringAsync ← convertToSwiftDataModelAsync ← saveRecipe`
is connected for the first time — the AI ingredient parser had never executed in
production. `ProcessingResults.saveRecipe` became `() async -> Bool`.

Decided approach: keep `legacyParse` primary and bolt the model on as a
confidence-gated upgrade. Scores derive from how the parse resolved — 1.0 for a
single word, or quantity plus recognized unit; 0.6 when a candidate unit token
was unrecognized and absorbed into the name; 0.3 when `parseQuantity` failed
outright. Escalation threshold 0.7. `fromString` (sync) unchanged, so all six
sync call sites keep their behaviour.

**Two deliberate departures from the plan:**

1. `autoSave()` stays **synchronous and heuristic**. The plan called for both
   save paths to go async, but that copy is a safety net `saveRecipe()` deletes
   and replaces — running the model per ingredient there would double the AI
   cost of an import, stall the moment the review sheet appears, and race a
   quick save against `autoSavedRecipe` being set.
2. The four decided scoring rules needed a fifth. `2 cups (250 g) flour` scored
   1.0 on the strength of a recognized `cups` and so would never have escalated,
   despite being named as a case escalation should catch. `adjust(_:forName:)`
   caps any score above 0.6 at 0.6 when the resulting *name* still contains
   digits or a parenthetical. Found by a test written against the plan's stated
   intent.

Also read "quantity found, unit not recognized → 0.6" as *there was a unit token
and we failed to recognize it* (the "absorbed into name" parenthetical), so
`2 eggs` scores 1.0 rather than paying for a model call it does not need. Both
readings are documented in the source.

→ [bugs/ingredient-quantity-parsing.md](bugs/ingredient-quantity-parsing.md)

### Map model errors to something a user can act on — S

`ModelErrorMessage.friendlyMessage(for:)` in
`Julia/Utilities/ModelErrorMessage.swift`, wired into all three `handleError`
sites (`processImage`, `processText`, `importSharedURL`). Covers
`.exceededContextWindowSize`, `.guardrailViolation`, `.rateLimited` and
`.assetsUnavailable`; everything else falls through to `localizedDescription`,
so `FoundationModelsServiceError` and `WebScrapeError` pass through untouched.

### ~~Migrate ingredients saved with unparsed fractions~~ — dropped 2026-09-03

Not released, no production data. Verified both seed files (`recipeData.json`,
`ingredientData.json`) for the bug pattern — vulgar-fraction characters or
leading digits in `name` — and both are clean: 32 and 46 name fields, zero
suspicious. They load via `SampleDataLoader` →
`ImportExportManager.createIngredient`, which builds `Ingredient` from
structured `quantity`/`unit`/`name` fields and never touches `legacyParse`
(zero references to `IngredientParser` in that file). Nothing to migrate.

---

## Fixed along the way

Not planned items — found while doing the above, written up in [bugs/](bugs/).

- **Foundation Models context window overflow.** `chunkSize` was 150, above the
  point where a chunk can fit: a full one needed ~4,813 tokens against ~4,096
  (117%). Chunking gave no protection; it only looked fine because most recipes
  never filled a chunk. Compounded by the model over-generating regardless of
  size — the failing fixture was 22 lines at ~30% of budget. Now 40 lines with
  halve-and-retry on `.exceededContextWindowSize`.
  → [bugs/context-window-overflow.md](bugs/context-window-overflow.md)

- **`parseQuantity` was never called.** All the Unicode-fraction and range logic
  was dead: `legacyParse` called `parseFraction` at all three quantity sites, so
  `½ cup butter` parsed as a *name* with no quantity. Affected every ingredient
  in the app — imports, chat tools and manual entry — not just a fallback path.
  → [bugs/ingredient-quantity-parsing.md](bugs/ingredient-quantity-parsing.md)

- **The Save button looked inert.** Reported symptom after `saveRecipe` went
  async: it can take seconds while ingredients are escalated to the model one at
  a time, with no feedback. The button now reads "Saving…" and disables while in
  flight. `saveRecipe` itself was never broken — `SaveRecipeTests` proves it
  persists, dedupes the auto-saved copy, survives an escalated ingredient, and
  fails loudly without a context.

---

## Investigated and dropped

Ideas taken off the backlog. Recorded so the same ground is not covered twice.

### Timer in live cooking mode — dropped 2026-09-04

Dropped at Robin's call after establishing the native-Clock route is not
available.

**What was asked:** in live cooking mode, reach the iOS Clock/Timer app through
a deep link.

**Finding: there is no supported way to do this.** Apple publishes no URL scheme
for creating a timer in Clock. Undocumented schemes (`clock-alarm://` and
similar) have circulated, but they are private API in practice — they break
between iOS versions and are an App Review risk. Do not re-investigate these.

**What remains possible, if a timer is ever wanted again.** The finding rules out
*that route*, not the feature. `CookModeView` has no timer of any kind today, so
it would be greenfield either way:

- **`ActivityKit` Live Activity** — timer on the Lock Screen and in the Dynamic
  Island, which is the behaviour people actually want from a cooking timer.
  Needs `NSSupportsLiveActivities` in `Info.plist` and a widget extension — a
  second extension target, for which `JuliaShareExtension` is the template on
  the project-file side.
- **`UNUserNotificationCenter` with a time-interval trigger** — the reliable
  alert, and it fires even if the app is killed. Needed regardless: the Live
  Activity is presentation, the notification is the guarantee.

Prerequisite either way: `Step` has no duration field, so a timer *per step*
needs "simmer 20 minutes" parsed out of instruction text, or a duration captured
during import. Multiple concurrent timers are the interesting design problem,
since recipes have overlapping steps.

## Lessons worth not relearning

- **A `ModelContext` does not retain its `ModelContainer`.** A test helper that
  returned only the context let the container deallocate on return; the process
  then crashed at first use with no assertion failure to explain it. Every test
  also passed in isolation, which made it look like a parallelism problem —
  `.serialized` was a wrong turn. Hold the container for the test's lifetime.

- **`-only-testing` with a Swift Testing function name needs the parens.**
  Without them the filter matches nothing and the run reports success, so a
  bisect can "pass" vacuously.

- **`@Generable` on an enum sends only case names.** No per-case `@Guide`, so
  category definitions must live in the instructions.

- **Apple Intelligence reporting `.available` does not mean a request will
  succeed.** See the test-gate item in [TODO.md](TODO.md) and
  [TESTING.md](TESTING.md).
