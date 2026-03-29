# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands
- Open project: `open Julia.xcodeproj`
- Build: ⌘B | Test: ⌘U | Run: ⌘R | Clean: ⇧⌘K
- Run single test: click ▶️ in gutter next to the test method

## Architecture Overview

Julia is an iOS recipe management app with an ML-driven import pipeline. The core flow:

```
User Input (image / text / URL)
  → RecipeProcessor (orchestrator)
      → TextRecognitionService (Vision OCR, for images)
      → RecipeLayoutAnalyzer (spatial grouping, WIP)
      → RecipeTextReconstructor (joins fragmented OCR lines)
      → RecipeTextClassifier (Core ML line classification)
  → RecipeData (intermediate struct)
      → IngredientParser (token-level ML parsing)
      → Recipe (SwiftData model, persisted)
```

## Data Models

**SwiftData models** (`Julia/Models/`): `Recipe` (root), `Ingredient`, `Step`, `Timing`, `Note`, `IngredientSection`, `ImageItem`. All use `@Model final class`.

**RecipeData** (struct): intermediate container used throughout processing. Holds arrays of raw strings before conversion. Call `.convertToSwiftDataModel()` to persist as a `Recipe`.

Key enums:
- `RecipeLineType`: `title`, `ingredient`, `instruction`, `serving`, `summary`, `time`, `section_title`, `note`, `source`, `unknown`
- `IngredientLocation`: `pantry`, `grocery`, `recipe`, `unknown`
- `ProcessingStage`: `notStarted`, `processing`, `completed`, `error`

## Processing Pipeline

**RecipeTextReconstructor** — takes raw OCR `[String]` lines, removes artifacts, and joins fragmented lines using heuristics. Returns `ProcessingTextResult` with `reconstructedLines` and `artifacts`.

**RecipeTextClassifier** — runs each line through `RecipeClassifier.mlmodel` (Core ML). Confidence threshold is 0.65; lines below threshold are tracked as `skipped` rather than discarded. Returns a `ClassificationResult` tuple.

**IngredientParser** — tokenizes ingredient strings and classifies each token (name, quantity, measurement, comment, marker) using `IngredientClassifier.mlmodel`. Falls back to regex parsing if the ML model is unavailable. Handles Unicode fractions and ranges.

## Core ML Models

- **RecipeClassifier.mlmodel** — document-level: classifies each text line into a `RecipeLineType`
- **IngredientClassifier.mlmodel** — token-level: classifies individual words/numbers within an ingredient string

## View Structure

```
ContentView
  └─ TabView (Grocery • Pantry • Recipes)
  └─ FloatingActionMenu (camera / text / URL import triggers)
  └─ FloatingStatusSheet → RecipeProcessing (live progress)
  └─ ProcessingResults sheet (preview pipeline output before saving)
       ├─ ProcessingResultsRawText
       ├─ ProcessingResultsReconstructedText
       ├─ ProcessingResultsClassifiedText
       └─ ProcessingResultsRecipe
```

`RecipeProcessor` is an `ObservableObject` injected at the top level. `RecipeProcessingState` tracks stage, status message, and sheet visibility.

## Code Style

- SwiftUI views with `body`; preview every view with `#Preview`
- `@State`, `@Binding`, `@Query`, `@Environment` for state — no third-party state libraries
- Import order: Foundation, SwiftUI, SwiftData, then alphabetical
- Extensions in dedicated files (e.g., `String+Extensions.swift`)

## Tests

`JuliaTests/RecipeProcessingTests.swift` uses Swift Testing (`@Test` macro). Tests load image and text assets, run the full processing pipeline, and log detailed classification results. When adding tests, follow this pattern and validate title accuracy, ingredient count, and confidence scores.
