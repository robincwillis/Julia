# Ingredient quantities: Unicode fractions and ranges never parsed

**Component** `Julia/IngredientParser.swift`
**Symptom** `½ cup butter` stored with **no quantity** and the fraction glued into the name
**Severity** High — affected every ingredient in the app, silently
**Status** Fixed 2026-09-03
**Found by** Audit, while writing `IngredientParsingTests`

---

## Symptom

Any quantity that was not a plain number or a `1/2`-style fraction was not
parsed at all. The whole string fell through to the ingredient's `name`:

| Input | `quantity` | `unit` | `name` |
|---|---|---|---|
| `2 cups flour` | 2 | cup | `flour` |
| `1/2 cup butter` | 0.5 | cup | `butter` |
| `½ cup butter` | **nil** | **nil** | **`½ cup butter`** |
| `1½ cups milk` | **nil** | **nil** | **`1½ cups milk`** |
| `2-4 cups stock` | **nil** | **nil** | **`2-4 cups stock`** |

Downstream this is worse than it looks. An ingredient with no `quantity` and no
`unit` cannot be scaled, summed into a grocery list, or usefully edited — and
the name is polluted, so two entries for `½ cup butter` and `¼ cup butter`
never match each other.

Vulgar fractions are not an edge case in recipes. They are what the Unicode
characters exist for, they are what OCR produces from a printed cookbook, and
they are what `⌥`-typing or pasting from a website gives you.

## Cause

`IngredientParser` has two quantity helpers:

```swift
// Handles vulgar fractions (½, ⅓ …), mixed numbers (1½) and ranges (2-4).
private static func parseQuantity(_ input: String) -> Double? { … }

// Handles "1/2" and plain numbers. Nothing else.
private static func parseFraction(_ input: String) -> Double? {
    let components = input.split(separator: "/").map { Double(…) }
    if components.count == 2, let n = components[0], let d = components[1], d != 0 {
        return n / d
    }
    return Double(input.trimmingCharacters(in: .whitespacesAndNewlines))
}
```

`parseQuantity` is the capable one. It maps 15 vulgar-fraction characters,
sums mixed numbers, averages hyphenated ranges — and ends by delegating to
`parseFraction` for the simple cases.

**`parseQuantity` was never called.** `legacyParse` reached past it to
`parseFraction` at all three of its quantity sites:

```swift
case 2:
    if let quantity = parseFraction(components[0]) {   // ← should be parseQuantity
case 3:
    if let quantity = parseFraction(components[0]) {   // ← should be parseQuantity
default:
    if let quantity = parseFraction(components[0]) {   // ← should be parseQuantity
```

So the entire vulgar-fraction and range implementation was dead code sitting
one call away from the code that needed it. `Double("½")` returns nil,
`parseFraction` returns nil, `legacyParse` falls to
`Ingredient(name: input, location: location)` — the whole line becomes the name.

Being `private static` with no callers, it produced no "unused" warning that
would have surfaced it.

## Why it went unnoticed

Two things hid it.

**The documentation asserted it worked.** `CLAUDE.md` stated the parser
"Handles Unicode fractions and ranges" — true of the code that existed, false
of the code that ran.

**It looked like a fallback path.** The obvious reading of `IngredientParser`
is that `fromStringAsync` is the real parser and `legacyParse` is a heuristic
backstop for when Apple Intelligence is unavailable. That reading is wrong, and
it is the reason the initial audit understated the severity.

Tracing the actual call graph:

```
IngredientParser.fromString      → legacyParse                          ← 6 production call sites
IngredientParser.fromStringAsync → FoundationModelsIngredientParser      ← 1 call site
```

`fromString` (heuristic-only) is called from:

| Site | Path |
|---|---|
| `Models/RecipeData.swift:85` | `convertToSwiftDataModel()` — **every persisted import** |
| `Utilities/JuliaTools.swift:28` | `AddToGroceryListTool` — chat |
| `Utilities/JuliaTools.swift:94` | `CreateRecipeTool` — chat |
| `Components/IngredientEditor.swift:377` | manual edit |
| `Components/IngredientEditor.swift:431` | manual edit |
| `Views/AddIngredient.swift:106` | manual add |

`fromStringAsync` is called from exactly one place — `convertToSwiftDataModelAsync()`
in `RecipeData.swift:153` — and **that function has no callers at all**. Both
`RecipeProcessor` sites use the synchronous version:

```
RecipeProcessor.swift:173  →  recipeData.convertToSwiftDataModel()
RecipeProcessor.swift:284  →  data.convertToSwiftDataModel()
```

So the chain is broken at the top:

```
FoundationModelsIngredientParser ← fromStringAsync ← convertToSwiftDataModelAsync ← nothing
```

**Consequence:** `legacyParse` was not a fallback. It was the *only* ingredient
parser that ever ran, for imports and manual entry alike, with or without
Apple Intelligence. Every ingredient in the app went through the broken path.

This also means the Foundation Models ingredient parser has never run in
production — tracked separately in [`../TODO.md`](../TODO.md).

## Fix

Point the three sites at the function written for the job:

```swift
if let quantity = parseQuantity(components[0]) {
```

No change to `parseQuantity` or `parseFraction` themselves; `parseQuantity`
already delegates to `parseFraction` for plain numbers and `1/2` fractions, so
previously-working inputs are unaffected.

Covered by `IngredientParsingTests`, which pins both the previously-broken and
previously-working cases:

- `unicodeFractions` — `½`, `¼`, `¾`, `⅓` (parameterised)
- `mixedNumber` — `1½ cups milk` → 1.5
- `rangeAverages` — `2-4 cups stock` → 3.0
- `decimalWithUnit`, `slashFraction`, `bareItem`, `multiWordName`, `rejectsEmpty`, `roundTrip`

## Not fixed

**Existing data is not migrated.** Every ingredient already saved with a
fraction is still stored with `quantity == nil` and a polluted `name`. The fix
is forward-only. A one-off migration that re-parses ingredients whose `name`
still contains a vulgar-fraction character would repair them — see
[`../TODO.md`](../TODO.md).

**`legacyParse` remains positional and fragile.** It switches on
`components.count` from a naïve `split(separator: " ")`, so:

- `1 1/2 cups flour` (space-separated mixed number) → `parseQuantity("1")` = 1,
  then `MeasurementUnit(from: "1/2")` fails, so the name becomes `1/2 cups flour`.
  A real and common format, still wrong.
- `2 cups (250 g) flour` puts the parenthetical in the name.
- A quantity anywhere but position 0 is not found.

These are pre-existing and out of scope of this fix, but they are the reason
the AI parser exists. Getting `convertToSwiftDataModelAsync` wired up matters
more than hardening the heuristic further.

## Related

- [`context-window-overflow.md`](context-window-overflow.md) — the other bug found in the same pass
- [`../AUDIT.md`](../AUDIT.md) §3
- [`../TODO.md`](../TODO.md)
