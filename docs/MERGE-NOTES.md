# Merge notes — `main` (Foundation Models) → `chore/dependency-toolchain-audit`

Merge commit `0e1d9c6`, 2026-09-02. Recorded because several resolutions
discarded working code on one side, and because two of them are worth
revisiting.

Pre-merge branch tip is tagged **`backup/pre-merge-2026-09-02`**. The
uncommitted work in progress at the time was checkpointed as `1c58916`.

## Shape of the conflict

`main` landed one large commit (64 files, +5.5k lines) replacing the Core ML
import pipeline with Foundation Models. The branch had two commits plus 21
uncommitted files, overlapping heavily. 14 files conflicted.

## Decisions

### URL import → took `main` wholesale

The branch had `RecipeProcessor.processURL` + `extractRecipeFromURL` and a
rewritten `RecipeURLImportView` that handed the URL to the shared pipeline.
This could not compile against `main`, which removed
`RecipeWebExtractor.extractRecipe(from:)` and trimmed `ExtractionError` to just
`.invalidURL` / `.noRecipeFound`.

`main`'s version scrapes in-view via `RecipeWebScraper.scrape(urlString:)` with
phase labels and returns a `RecipeData` through a binding. Import triggers now
live in `ChefChatView`, which the simplified `FloatingActionMenu` opens.

A headless path was later re-added for the share extension —
`RecipeProcessor.importSharedURL` — because a share has no view to host the
scraper. It uses `main`'s scraper, not the deleted API.

### Colours → kept `Color.app.*` tokens

Both sides migrated the same hardcoded colours, the branch to `Color.app.*`
design tokens and `main` to system semantic colours (`.primary`,
`Color(UIColor.systemBackground)`). Every conflicting hunk resolved to the
tokens.

This is **not fully settled** — see [AUDIT.md §8](AUDIT.md). `main` introduced
hardcoded colours outside the conflict regions that the merge left alone, and
the token choice looks different from `main`'s new toolbar styling.

### Auto-save → ported onto `main`'s rewrite

`main` rewrote `processData` with an `immediatePresentation:` flag and no
auto-save. The branch's auto-save (persist on import, then delete-and-replace
when the user saves the reviewed version) was ported on top: `autoSave()` in
`processData`, dedupe in `saveRecipe()`.

Note it fires only for `processData` and `importSharedURL`. Text and image
imports have never auto-saved.

### Dropped: `processRecipeTextAsync`

Commit `ca31726` added a `Task.detached` wrapper around
`RecipeTextClassifier.processRecipeText`. `main` gutted that class to a 36-line
stub with no such method, so the wrapper had nothing to wrap.

### Reverted: `ClassificationResult` field order

`ca31726` had reordered the tuple, moving `sectionTitles` from position 2 to 7.
`main`'s `FoundationModelsRecipeClassifier` constructs it with labels in the
original order.

Every field is `[String]`, so this was a live hazard — but Swift matches
labelled tuple elements by name and only *warns*
("implicit reordering of tuple elements … is deprecated; this will be an error
in a future Swift language mode"). Verified experimentally that values are not
transposed. Restored to `main`'s order, which removes the warning.

### `project.pbxproj`

Took `main`'s new file references, kept the branch's corrected
`PreviewHelpers.swift` path (`Julia/Utilities/…`, where the file actually is —
`main` still has the stale root-level path).

## Incidental fixes the merge forced

- **`RecipesView` exceeded the SwiftUI type-checker budget** once both sides'
  modifiers combined. Split into `recipesContent` / `recipesToolbar` /
  `noResultsView`, following the `@ToolbarContentBuilder` pattern
  `RecipeDetails` already used.
- **`NavigationView` kept the dead `selectedURL` state** through an automerge,
  while the code referenced `main`'s `extractedRecipeData`. Replaced at three
  sites.
- **`hidesSharedGlassBackground()` extends `ToolbarContent`, not `View`** — it
  has to sit on the toolbar *items*, not after `.toolbar { }`.
- **`JuliaTests` deployment target** was 17.6 against a 26.0 app host, which
  made the test target unbuildable on `main` too. Bumped to 26.0.
