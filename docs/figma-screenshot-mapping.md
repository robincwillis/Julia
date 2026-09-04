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
| IMG_0508 | Light | `AddIngredient.swift` (sheet over Pantry) | ingredient input field |
| IMG_0502 | Light | `RecipeDetails.swift` | Ingredients/servings |
| IMG_0501 | Light | `SettingsDrawer.swift` | "Export Recipes", "Debug" |
| IMG_0500 | Light | `ChefChatView.swift` (empty state) | "Ask me anything about cooking…" |
| IMG_0499 | Light | `RecipesView.swift` | "Search recipes", nav title |
| IMG_0498 | Light | `IngredientsView.swift` (Pantry) | populated pantry list |
| IMG_0485 | Dark | `RecipeDetails.swift` (edit: Instructions/Notes/Tags) | "Add a step", "No notes added" |
| IMG_0482 | Dark | `CookModeView.swift` | "Step 8 of 26" |
| IMG_0481 | Dark | TBD | TBD |
| IMG_0480 | Dark | TBD | TBD |
| IMG_0493 | Dark | TBD | TBD |
| IMG_0492 | Dark | TBD | TBD |
| IMG_0491 | Dark | TBD | TBD |
| IMG_0490 | Dark | TBD | TBD |
| IMG_0489 | Dark | TBD | TBD |
| IMG_0488 | Dark | TBD | TBD |
| IMG_0487 | Dark | TBD | TBD |
| IMG_0486 | Dark | TBD | TBD |
