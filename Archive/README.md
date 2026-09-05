# Archive — not in the build

Code kept for reference, deliberately excluded from every target. Nothing here
compiles, and nothing in the app references it.

## `CoreML-legacy/`

The pre-Foundation-Models import pipeline.

| File | Was |
|---|---|
| `RecipeClassifier.mlmodel` (368 KB) | document-level line classification |
| `IngredientClassifier.mlmodel` (48 KB) | token-level ingredient parsing |
| `RecipeTextClassifier.swift` | the Swift wrapper around the first model |

Superseded by `FoundationModelsRecipeClassifier` and
`FoundationModelsIngredientParser`.

**Why archived rather than deleted.** These were the most plausible fallback for
devices without Apple Intelligence. That question was settled in
`docs/AUDIT.md` §1 with detect-and-communicate instead — so they are wired to
nothing, but remain the obvious starting point if a real fallback classifier is
ever wanted.

They were still in the app target's Sources phase until 2026-09-04, shipping
~416 KB of model weights for code nothing called.

⚠️ `RecipeLineType` used to live in `RecipeTextClassifier.swift` and is still
live app code — it moved to `Julia/Models/RecipeLineType.swift`. Archiving that
file was not a straight move.
