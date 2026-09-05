# Figma Screenshot → Swift View Mapping

Source: [Julia Figma file, "3. User Interface" section](https://www.figma.com/design/Jo15MfandslMxy6Tabplxf/Julia?node-id=2078-120)

Maps each captured app screenshot (Light Mode and Dark Mode grids, plus two
standalone Groceries screenshots) to the SwiftUI view that renders it, for
tagging back into Figma as text labels.

| Image | Mode | Swift View | Evidence |
|---|---|---|---|
| IMG_0473 | Dark | `EmptyIngredientsView.swift` | "Grocery basket empty" |
| IMG_0497 | Light | `IngredientsView.swift` (Groceries) | populated grocery list |
| IMG_0514 | Light | `RecipeSuggestionDetailView.swift` | "Missing (4)", "Suggest Substitutions" |
| IMG_0513 | Light | `RecipeSuggestionsView.swift` | "What can I cook?" |
| IMG_0512 | Light | `RecipeSuggestionsView.swift` | same view, more items |
| IMG_0511 | Light | `ScanInstructionView.swift` | "Scan a Recipe or Receipt" |
| IMG_0510 | Light | `RecipeTextImportView.swift` | Section "Recipe Text" |
| IMG_0509 | Light | `RecipeURLImportView.swift` | Section "Recipe URL" |
| IMG_0508 | Light | `IngredientEditor.swift` (bottom sheet over Pantry) | "4 ½ ounces / oil-packed sardines", collapse chevron + save check; light-mode twin of IMG_0491 |
| IMG_0502 | Light | `RecipeDetails.swift` | Ingredients/servings |
| IMG_0501 | Light | `SettingsDrawer.swift` | "Export Recipes", "Debug" |
| IMG_0500 | Light | `ChefChatView.swift` (empty state) | "Ask me anything about cooking…" |
| IMG_0499 | Light | `RecipesView.swift` | "Search recipes", nav title |
| IMG_0498 | Light | `IngredientsView.swift` (Pantry) | populated pantry list |
| IMG_0485 | Dark | **Edit Recipe** — `RecipeDetails.swift` `editModeContent` + `RecipeSections/RecipeEdit*Section.swift` | "Add a step" (`RecipeEditInstructionsSection.swift:45`), "No notes added" (`RecipeEditNotesSection.swift:35`) |
| IMG_0482 | Dark | `CookModeView.swift` (**drawer expanded**) | "Step 8 of 26", six ingredient rows, no progress dots, dim overlay — `CookModeView.swift:73` draws that overlay only `if isDrawerExpanded` |
| IMG_0481 | Dark | `CookModeView.swift` (**drawer collapsed**) | "Step 8 of 26", progress dots visible, "Ingredients" drawer handle peeking (`CookModeView.swift:84`), no dim overlay |
| IMG_0480 | Dark | `RecipeSuggestionDetailView.swift` | "4/8 ingredients — 50%", "Missing (4)", "View Full Recipe" (`RecipeSuggestionDetailView.swift:120`) |
| IMG_0493 | Dark | `ChefChatView.swift` (populated conversation) | chat bubbles, "Message Julia…", Camera/Photos/Website FAB row (`ChefChatView.swift:285`) |
| IMG_0492 | Dark | `IngredientEditor.swift` (controls expanded, over Pantry) | unit grid + fraction/number keypad + "Delete" (`IngredientEditor.swift:327`), comment field "ends trimmed (115g)" |
| IMG_0491 | Dark | `IngredientEditor.swift` (name field focused, over Pantry) | "4 ounces / haricots verts" over system keyboard; presented from `IngredientsView.swift:72` |
| IMG_0490 | Dark | `RecipesView.swift` (tag filter bar) | tag chips "main course / onion / salad / sardines", `tagFilterBar` (`RecipesView.swift:144`) |
| IMG_0489 | Dark | `RecipeDetails.swift` | "Shrimp Scampi with Pasta", summary, "3 of 6" servings, 40 min total / 20 min cook, Ingredients |
| IMG_0488 | Dark | `ProcessingResults.swift` → `ProcessingResultsRecipe.swift` (Recipe tab) | Cancel/Save toolbar (`ProcessingResults.swift:74`), Instructions rows + Section "Source" with raw allrecipes URLs (`ProcessingResultsRecipe.swift:129`) |
| IMG_0487 | Dark | `ProcessingResults.swift` → `ProcessingResultsReconstructedText.swift` (Reconstructed tab) | "Reconstructed Text (0 lines)" (`ProcessingResultsReconstructedText.swift:26`), Recipe/Raw/Reconstructed/Classified tab bar |
| IMG_0486 | Dark | `RecipeDetails.swift` (⋯ menu open) | "Edit Recipe", "Ask Julia", "Add to Grocery List", "Complete Recipe" (`RecipeDetails.swift:275-286`) |

## Figma recreations

Thirteen of these screens have been rebuilt as native Figma frames, gathered in a
`Design Mocks` frame. They live in a **copy** of the Julia file inside the
Addition org — `iMoHTDAGPZi6VkRgUEf9vG` — because the original sits in a
Starter-plan team, where the Figma MCP allowance is 20 calls per month. See
[`figma-build-spec.md`](figma-build-spec.md) for the tokens, type ramp, geometry
and naming those frames follow, and for the open items still to settle.

| Screenshot | Figma node | Presentation |
|---|---|---|
| IMG_0485 | `1003:2` | full screen, `Form`, scrolled mid-content |
| IMG_0511 | `1021:2` | `.sheet` from `ChefChatView`, non-form layout |
| IMG_0514 | `1029:2` | `.sheet` from `RecipesView` + inset-grouped `List` |
| IMG_0513 | `1029:31` | `.sheet` + `List` + bottom filter bar |
| IMG_0510 | `1074:2` | `.sheet` + `Form` |
| IMG_0509 | `1074:39` | `.sheet`, drag indicator **hidden** |
| IMG_0508 | `1074:92` | `FloatingBottomSheet` over a `.plain` List |
| IMG_0500 | `1108:27` | `fullScreenCover`, no sheet chrome |
| IMG_0502 | `1114:2` | plain `ScrollView`, no card inset |
| IMG_0501 | `1125:2` | **edge drawer**, pushes the presenting view |
| IMG_0499 | `1143:2` | `.plain` List on `bgPrimary` |
| IMG_0482 | `1159:2` | full screen, drawer expanded + dim overlay |
| IMG_0498 | `1173:14` | `.plain` List on `bgPrimary`, Pantry tab |

Presentation context turned out to matter more than the view name. Four distinct
species so far: modal detent sheet, `FloatingBottomSheet` (bottom-anchored card,
all corners rounded, 5% scrim), edge drawer (pushes rather than covers, no scrim
at all), and plain full-screen. IMG_0508's and IMG_0501's differ from the modal
sheets in surface geometry, scrim and layer order alike.

Still to build: **IMG_0487/0488** ProcessingResults and **IMG_0473**
EmptyIngredientsView. Everything else in the grid
is a variant of a built screen — a dark twin, a different state, or the same list
in its other tab — and belongs to the component pass, not a fresh build.

## Notes

- IMG_0508 was previously labelled `AddIngredient.swift`. It is the same sheet as
  IMG_0491/IMG_0492 in light mode, i.e. `IngredientEditor.swift` presented by
  `IngredientsView` in a `FloatingBottomSheet`. `AddIngredient.swift` is a
  different, plainer "paste an ingredient line" sheet and does not appear in
  this capture set.
- IMG_0487 and IMG_0488 are the same `ProcessingResults` sheet on two different
  tabs, captured a few seconds apart (5:02). The tab bar is hidden in IMG_0488
  because the keyboard is up.
- IMG_0481/IMG_0482 and IMG_0489/IMG_0486 are pairs of the same view with a
  drawer or menu opened, not distinct screens.
- IMG_0485 is the **Edit Recipe** screen, not recipe detail. There is no
  `EditRecipe.swift`: edit mode is the `editModeContent` branch of
  `RecipeDetails.swift` (a `Form` of the six `RecipeEdit*Section` views), gated
  on `@Environment(\.editMode)`. The Figma layer name and caption for IMG_0485
  still say `RecipeDetails.swift` and should be updated to say Edit Recipe.
