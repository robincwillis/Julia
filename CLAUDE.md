# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands
- Open project: `open Julia.xcodeproj`
- Build: ⌘B | Test: ⌘U | Run: ⌘R | Clean: ⇧⌘K
- Run single test: click ▶️ in gutter next to the test method
- From the CLI: `xcodebuild -project Julia.xcodeproj -scheme Julia -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (swap `build` for `test`)

Targets: **Julia** (app, iOS 26.0), **JuliaTests**, **JuliaShareExtension**.
iOS 26 is required — the import pipeline depends on Foundation Models.

## Further documentation

- `docs/TODO.md` — open backlog, prioritised. **Start here.**
- `docs/DONE.md` — completed work, with the decisions and constraints behind it
- `docs/AUDIT.md` — known issues and open decisions. **Read before large changes.**
- `docs/bugs/context-window-overflow.md` — why the classifier chunks at 40 lines
  and retries; read before changing `FoundationModelsRecipeClassifier`
- `docs/bugs/ingredient-quantity-parsing.md` — the ingredient parser call graph
  and why the heuristic path is the one that actually runs
- `docs/TESTING.md` — how the test suite is organised and how to add fixtures
- `docs/SHARE-EXTENSION.md` — the Notes/Safari import flow
- `docs/MERGE-NOTES.md` — why the current pipeline looks the way it does
- `docs/figma-screenshot-mapping.md` — which captured app screenshot in the
  Figma file corresponds to which SwiftUI view
- `docs/figma-build-spec.md` — tokens, type ramp, geometry and naming for
  recreating screens in Figma. **Read before touching the Figma file or
  starting the design system.**

## Architecture Overview

Julia is an iOS recipe management app with an AI-driven import pipeline built on
**Foundation Models** (Apple Intelligence, on-device). The core flow:

```
User Input (image / text / URL / share sheet)
  → RecipeProcessor (@MainActor @Observable orchestrator)
      → TextRecognitionService (Vision OCR, for images)
      → RecipeLayoutAnalyzer (spatial grouping, WIP)
      → RecipeTextReconstructor (joins fragmented OCR lines)
      → FoundationModelsRecipeClassifier (line classification)
  → RecipeData (intermediate struct)
      → IngredientParser (Foundation Models, heuristic fallback)
      → Recipe (SwiftData model, persisted)
```

URL import does not go through OCR — `RecipeWebScraper`
(`Utilities/RecipeWebExtractor.swift`) fetches the page, prefers JSON-LD
structured data, and falls back to Foundation Models on the page text.

> **There is no fallback if Apple Intelligence is unavailable**: image and text
> import fail outright. See `docs/AUDIT.md` §1 — this is the top open issue.

## Data Models

**SwiftData models** (`Julia/Models/`): `Recipe` (root), `Ingredient`, `Step`, `Timing`, `Note`, `IngredientSection`, `ImageItem`. All use `@Model final class`.

**RecipeData** (struct): intermediate container used throughout processing. Holds arrays of raw strings before conversion. Call `.convertToSwiftDataModel()` to persist as a `Recipe`.

Key enums:
- `RecipeLineType`: `title`, `ingredient`, `instruction`, `serving`, `summary`, `time`, `section_title`, `note`, `source`, `unknown`
- `IngredientLocation`: `pantry`, `grocery`, `recipe`, `unknown`
- `ProcessingStage`: `notStarted`, `processing`, `completed`, `error`

## Processing Pipeline

**RecipeTextReconstructor** — takes raw OCR `[String]` lines, removes artifacts, and joins fragmented lines using heuristics. Returns `ProcessingTextResult` with `reconstructedLines` and `artifacts`.

**FoundationModelsRecipeClassifier** — sorts lines into a `@Generable ClassifiedRecipe` with a single long instruction prompt, then converts it to the `ClassificationResult` tuple. Chunks input at 40 lines and halves-and-retries on `.exceededContextWindowSize`: the ~4096 token budget covers instructions (~900 tokens), the input, *and* the output, which echoes every input line back.

**IngredientParser** — `fromStringAsync` uses Foundation Models for rich structured output and falls back to `legacyParse` (heuristic, synchronous) when unavailable or on error. `fromString` is heuristic-only. Handles Unicode fractions (`½`, `1½`) and hyphenated ranges (`2-4`, averaged) via `parseQuantity`.

**RecipeWebScraper** — `scrape(urlString:)` fetches, extracts JSON-LD (walking `@graph`), normalizes to `RecipeData`, and falls back to Foundation Models over the stripped page text. Reports progress through `WebScrapePhase`.

## Foundation Models

`FoundationModelsService` is an actor owning access to `SystemLanguageModel.default`. It creates a **fresh `LanguageModelSession` per request** to avoid context accumulation, and throws `.unavailable` when Apple Intelligence is off. `JuliaApp` prewarms it at launch.

`ChefChatView` is the one place that uses tool calling, registering `AddToGroceryListTool` and `CreateRecipeTool` from `Utilities/JuliaTools.swift`.

> `RecipeClassifier.mlmodel`, `IngredientClassifier.mlmodel` and
> `RecipeTextClassifier.swift` are the **previous** Core ML pipeline. They are
> still in the app target but nothing references them — do not treat them as
> live code. See `docs/AUDIT.md` §4.

## View Structure

```
ContentView
  └─ NavigationView
       └─ TabView (Grocery • Pantry • Recipes)
       └─ FloatingActionMenu (single button → opens ChefChatView)
       └─ FloatingStatusSheet → RecipeProcessing (live progress)
       └─ ChefChatView (fullScreenCover — the import hub: camera,
       │                text, URL, receipt scan, tool-calling chat)
       └─ ProcessingResults sheet (preview pipeline output before saving)
            ├─ ProcessingResultsRawText
            ├─ ProcessingResultsReconstructedText
            ├─ ProcessingResultsClassifiedText
            ├─ ProcessingResultsReceipt
            └─ ProcessingResultsRecipe
```

`RecipeProcessor` is `@Observable @MainActor`, held as `@State` in
`NavigationView` (not an `ObservableObject`, and not injected via environment).
`RecipeProcessingState` tracks stage, status message, and sheet visibility.

`NavigationView` also drains the share-extension inbox — see
`docs/SHARE-EXTENSION.md`.

Toolbar note: `hidesSharedGlassBackground()` extends **`ToolbarContent`**, not
`View` — apply it to a `ToolbarItem`, never after `.toolbar { }`. Large view
bodies here can exceed the SwiftUI type-checker budget; extract
`@ToolbarContentBuilder` and `@ViewBuilder` properties as `RecipeDetails` and
`RecipesView` do.

## Code Style

- SwiftUI views with `body`; preview every view with `#Preview`
- `@State`, `@Binding`, `@Query`, `@Environment` for state — no third-party state libraries
- Import order: Foundation, SwiftUI, SwiftData, then alphabetical
- Extensions in dedicated files (e.g., `String+Extensions.swift`)

## Tests

Swift Testing (`@Test`, `#expect`, `#require`). See **`docs/TESTING.md`** for the
full picture. The essentials:

- **Add a test case by dropping a file** into `JuliaTests/Fixtures/Images`,
  `.../Text` or `.../Web`. `TestAssets` discovers fixtures by extension at
  runtime, and `JuliaTests` is a synchronized folder group — no project edit,
  no code edit. Names must be unique across the three folders.
- Suites are split by requirement: reconstruction, ingredient parsing, OCR and
  JSON-LD scraping run **offline everywhere**; `FullPipelineTests` needs Apple
  Intelligence and **skips itself** via `.enabled(if:)` when unavailable.
- Assert **shape, not exact strings** — the classifier is a non-deterministic
  language model. Give pipeline tests a `.timeLimit` trait.
- Detailed per-asset dumps go to the test report via `Testing.Attachment`.
  Do not write logs to `temporaryDirectory` (tests run in throwaway simulator
  clones) and do not rely on `print` (swallowed by the harness).
