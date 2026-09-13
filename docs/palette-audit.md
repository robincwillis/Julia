# Palette audit — evidence for a simplified token set

Purpose: the Figma mockups (see `figma-build-spec.md`) reproduce the app as it is
today, conflicts included. This file is the inventory of those conflicts, so a
simplified palette can be designed against evidence rather than memory. Once the
new palette is locked, the views get refactored and this file becomes history.

Two independent usage counts are cross-referenced:
- **Swift** — `Color.app.*` references across `Julia/Views`, `Components`, `Utilities`
- **Mockup** — bound paints across the 13 built Figma screens (869 bindings)

## What the app actually uses

| Colorset | Swift | Mockup | Note |
|---|---|---|---|
| `primary` | 72 | 173 | the accent, by far the most used |
| `text.primary` | 35 | 245 | |
| `white` | 16 | 9 | **inverts** to `#000000` in dark |
| `grey.300` | 15 | 29 | via `textLabel` (12) + `grey300` (3); `textTitle` is a third alias |
| `danger` | 11 | 0 | destructive actions; absent from these captures |
| `background.secondary` | 11 | 5 | |
| `grey.400` | 6 | 16 | via `textSecondary` |
| `offwhite.200` | 5 | 1 | |
| `secondary` | 3 | 0 | tag chips |
| `background.primary` | 3 | 9 | |
| `offwhite.400` | 2 | 64 | checkboxes — heavy in mockups, barely referenced in code |
| `primary.disabled` | 1 | 0 | |

**Dead in the catalogue — never referenced by any view:**
`grey.100`, `grey.200`, `grey.500`, `offwhite.100`, `offwhite.300`,
`offwhite.500`, `secondary.disabled`. Seven of twenty colorsets.

**Dead code in `Theme.swift`:** `primaryColor` and `secondaryColor` reference
`Color("PrimaryColor")` / `Color("SecondaryColor")`, and **no such colorsets
exist**. They resolve to nothing at runtime.

## The conflicts

### 1. Three oranges
- `primary` `#FF3900` → `#FF7445` dark
- `AccentColor` `#FF3900` → `#FF7445` dark — **identical to `primary` in both
  modes.** (An earlier reading of this file said AccentColor had no dark variant;
  that was wrong, and the catalogue has one. Corrected.) It is therefore a pure
  duplicate of `primary` and a candidate for deletion — except that iOS uses it
  as the app-wide tint, so it must keep existing; it should simply *be* primary.
- `Dot.swift:28` hard-codes `Color(red: 1.0, green: 0.30, blue: 0.15)` =
  `#FF4D26`, four levels off `primary`, and never adapts. Both render together
  on the Chef Chat and Recipes screens.

### 2. Four light whites that diverge in dark
| token | light | dark |
|---|---|---|
| `white` (asset) | `#FFFFFF` | `#000000` |
| iOS `card` | `#FFFFFF` | `#1C1C1E` |
| iOS `systemBackground` | `#FFFFFF` | `#000000` |
| `offwhite.100` | `#FEFEFE` | `#323232` |

Indistinguishable in light, wildly different in dark. This is the single biggest
source of binding ambiguity — a `#FFFFFF` fill in a mockup could correctly be any
of the four, and only layer semantics disambiguate it.

**Already burned us:** a tab-bar label bound to `white` turned **black on blue**
in the dark twin. `Theme.swift` already has the right idea with
`textOnPrimary = Color.white` — a literal that never inverts — but it is used
exactly once.

### 3. Three screen backgrounds, chosen by accident of implementation
`background.primary` `#EFEFEF` (plain lists), `background.secondary` `#DDE2E1`
(views that override), iOS `systemGroupedBackground` `#F2F2F6` (views that
don't). Which one a screen gets depends on whether its view happens to set
`.background(...)`, not on any intent. Three different greys read as "the
background" across the app.

### 4. Duplicate and near-duplicate neutrals
- `grey.500` `#1C1C1C` is **byte-identical** to `text.primary` `#1C1C1C`.
- `grey.300` `#8D8C8B` vs iOS `secondaryLabel` `#85858A` — both in use for
  secondary text, 8 levels apart, indistinguishable on screen.
- `text.primary` `#1C1C1C` vs SwiftUI's `.primary` label (**true black**), both
  present. Nav titles and summaries render true black; body text renders
  `#1C1C1C`.
- The neutral ramp has **ten** entries (`grey.100`–`500`, `offwhite.100`–`500`)
  of which **four** are used.

### 5. Separators
`#E7E7E8` (correct), `#D5D5D8` (a wrong value that reached two frames before it
was caught), and SwiftUI `Divider()` at `#3C3C43 @ 29%` on a 0.33pt hairline —
three treatments for one line.

### 6. The app renders the same token two ways in one screenshot

In the dark Groceries capture, `Color.app.white` paints the **tab-bar capsule
white** and the **CTA button and toolbar disc black** — simultaneously. The tab
bar appears to be rendering in light appearance while the rest of the screen is
dark. Its `.blue` samples `#007AFF` (light) rather than `#0A84FF` (dark), which
corroborates it.

Related runtime inconsistencies found while mocking up:
- The **FAB samples `primary` `#FF7445`**, not `Dot.swift`'s hard-coded
  `#FF4D26`, in that capture — so the second orange is applied inconsistently,
  or the captures span two builds of the app.
- **Card surfaces measure `#2C2C2D` on Processing Results** but `#1C1C1E`
  elsewhere in dark.
- **Processing Results paints `background.secondary` across both tabs**, even
  the tab whose `Form` sets no background — something above it is propagating a
  sibling's `.background(...)`.

These are not palette-design problems, but they are reasons the current palette
*looks* inconsistent on device, and they should be fixed in the refactor
regardless of which tokens survive.

### 7. Dark mode exposes binding errors that light mode cannot

Building the dark screens from scratch (rather than deriving them) found **four
places where a `#FFFFFF` fill was bound to the wrong token**. All four are
invisible in light — where `white`, `card` and `systemBackground` are all
`#FFFFFF` — and all four break in dark:

| element | was bound | source says | dark result |
|---|---|---|---|
| `FloatingBottomSheet` surface | `ios/card` `#1C1C1E` | `Color.app.white` (`FloatingBottomSheet.swift:76`) | should be `#000000` |
| toolbar add-ingredient disc | `ios/card` | `Color.app.white` | should be `#000000` |
| checkmark knockout | `ios/card` | shows the sheet through | should be `#000000` |
| collapse arrow | `brand/primary` `#FF7445` | no `foregroundColor` set ⇒ **`AccentColor`** | rendered `#FF3900` in the capture |

The fourth is subtler than it first looked. The button inherits `AccentColor`
and the capture shows `#FF3900` — the *light* orange on a dark screen — while
`primary` renders `#FF7445` alongside it. Since the catalogue's AccentColor
*does* carry a dark variant, either the capture predates that variant being
added, or the control is not picking up the dark appearance. **The screenshots
record a build at a moment in time and the catalogue has moved since** — worth
remembering before treating any capture as current.

This is the strongest argument in this document for collapsing the four whites
and the three oranges. The ambiguity is not theoretical — it produced four real
defects in a careful, source-checked pass.

### 8. Two measured values that disagree with their published constants

- **`ios/systemBlue` dark.** Source is `Color(.systemBlue)`
  (`IngredientEditor.swift:267,293`), so the token is named correctly. Apple
  publishes `#0A84FF`; the capture measures **`#0091FF`** across ten flat
  number keys. The same capture reproduces five other tokens byte-exactly, so
  it is not a colour-space artefact. **Left at the published value** — a single
  sample should not overwrite a documented constant, especially when another
  capture showed the tab bar rendering in *light* appearance on a dark screen.
  Needs a check on device.
- **`ios/keyboardBg` dark** measured `#161617` against the `#2C2C2E` I entered.
  Corrected — it is a placeholder plate with no competing source of truth.

Still unverified in dark after eight dark screens: **`ios/systemRed`**,
**`ios/chevron`**, **`ios/grabber`**. Each has now been looked for and found
absent, with source corroboration — `FloatingBottomSheet` draws no grabber, and
the Delete key that was expected to be red is `Color.app.primary`.

### 9. Two dark captures disagree about the same component

IMG_0490 shows the tab-bar capsule **black** (`Color.app.white` resolving dark,
token-correct) with a dark-ish `.blue`. The Groceries dark capture shows the same
capsule **white** with `.blue` reading `#007AFF`, the light value. Same token,
same component, opposite appearance. Combined with §6 this is a genuine runtime
bug — part of the UI is not receiving the dark appearance — not a measurement
error, and it will survive any palette simplification unless it is fixed in the
views.

### 10. `chevron` was a frozen composite, and is now translucent

Measured `#5F5F62` over `#242424`, which back-solves exactly to Apple's
`tertiaryLabel` `#EBEBF5 @ 30%`; the light value `#C7C7CC` is `#3C3C43 @ 30%`
over white. The flat `#48484A` originally entered was 23 levels off. It now
joins `secondaryLabel` and `fillSecondary` as a translucent token. **Three of
the iOS greys turned out to be alpha values wearing a hex costume** — a useful
pattern to carry into the new palette: system greys are translucent by design so
they composite over any surface.

### 11. iOS has TWO grouped card surfaces and we modelled one

A card inside a `.sheet` gets the **elevated** grouped palette — measured
`#2C2C2E` on two independent dark captures (Suggestion Detail, Processing
Results) — while a card on a plain screen gets `#1C1C1E`. In light both are
`#FFFFFF`, so the distinction is invisible until dark. Added as
`ios/cardElevated`. Any simplified palette needs either both surfaces or a
deliberate decision to flatten them.

### 12. The mirror of the white trap: black-family scrims

`#FFFFFF` was ambiguous across four tokens; `#000000` is ambiguous across three
— `ios/label` and `brand/textPrimary` are both `#000000` light → `#FFFFFF`
dark. A scrim bound to either paints the **entire frame white** in dark. Two
were found and fixed (`Scrim · presenting view dimmed`, `Sheet dim`), both in
*light* frames where nothing looked wrong. Scrims now bind to the `scrim/*`
family exclusively.

### 13. Two more iOS greys were alpha values, and two published constants disagree

- `ios/placeholderText` joins `chevron` as translucent `tertiaryLabel`
  (`#3C3C43` / `#EBEBF5 @ 30%`); the flat value was 25 levels off.
- `ios/fillSecondary` dark was **36%**, which is `systemFill`. The correct
  `secondarySystemFill` is **32%** — measured `#262629` over black, exact.
  The light 16% was right all along, which is why it never surfaced.

**A pattern worth investigating before adopting any iOS system colour:** every
system *hue* measured in a dark capture differs from Apple's published dark
value — `systemBlue` `#0091FF` vs `#0A84FF` (twice), `systemOrange` `#FF9230`
vs `#FF9F0A`. The greys composite exactly; only the hues drift, and they drift
toward their light values. Combined with §6 and §9 — a tab bar rendering in
light appearance on a dark screen — the likeliest explanation is that parts of
this app are not receiving the dark appearance at all. **No system-colour token
has been changed on the strength of these samples.**

### 14. On the age of the screenshots

`AccentColor` *does* carry a dark appearance in the catalogue today
(`#FF7445`), yet accent-driven controls render `#FF3900` in the dark captures.
Two independent agents concluded from their captures that the dark variant does
not exist. It does. **The screenshots record a build from a moment in time, and
the asset catalogue has moved since.** Treat captures as evidence of what
shipped, not of what the catalogue currently says — and re-verify any conflict
against the source before designing around it.

### 15. `.regularMaterial` was bound to a flat surface token, 37+ times over

Nav discs use `.background(.regularMaterial)` (`RecipeDetails.swift:255,289`)
and were bound to `ios/card`. In dark the same material measures **#1E1E1E**
alone, **#181818** for the shared toolbar glass, and **#282828** where material
stacks on that glass — three values for one binding, because material is a
*function of what is behind it*, not a colour.

The same authoring error put phantom `ios/card` fills on **37 status-bar icon
containers across 17 frames** — `Wi-Fi`, `Cellular`, `Battery`, `Silent mode`.
White-on-white in light, `#1C1C1E` boxes in dark. Swept.

**Material is the strongest argument against flat surface tokens.** There are now
**seven** measured glass recipes across light and dark, all ground-dependent. A
simplified palette should either commit to opaque surfaces with real values, or
accept that material is a blend and cannot be tokenised as a hex at all.

### 16. `ios/systemRed` finally exercised — and deliberately not adopted

`RecipeDetails.swift:286` marks "Complete Recipe" `role: .destructive`, so it is
SwiftUI `systemRed` (dark `#FF453A`). The capture samples **`#EC5A55`**
uniformly. Menu vibrancy does not explain it: the white labels lose only ×0.965,
and 0.965 × `#FF453A` = `#F64338` — nowhere near. The blend **desaturates as
well as dims**.

Token left at `#FF453A`. This is now the third system hue measured below its
published dark value (§13), and the pattern is consistent enough to be a
property of how this app renders dark, not of the constants.

**Menus need their own treatment either way:** the surface measures `#121212`
(no token), labels render `#F6F6F6` rather than reaching white, and the divider
is a **one-level step** ≈ `#FFFFFF @ 4%` — a fourth separator treatment beside
the three in §5.

## A starting point for the simplified set

Not a recommendation to adopt as-is — a demonstration that ~11 tokens cover
everything the 13 screens actually do:

```
accent            primary + its dark variant; absorb Dot and AccentColor
accent/on         literal white, never inverts (today's textOnPrimary)
surface/screen    one screen background per mode
surface/raised    cards, rows, sheets
text/primary      one, not two — pick #1C1C1C or true black
text/secondary    one, not three
text/tertiary     placeholders, disabled
line              one separator
danger            destructive
status/low·mid·high   coverage bands (systemRed/Orange/Green)
```

Everything else in the catalogue is either unused, a duplicate, or an
implementation accident.

## Open questions for the palette design

1. Should `text.primary` be `#1C1C1C` or true black? Both ship today.
2. Is `background.secondary`'s blue-grey `#DDE2E1` / `#374750` intentional
   brand, or an artefact? It is the most distinctive neutral in the app.
3. Do the tag chips (`secondary` `#B3DAD7`, a teal) belong to the palette, or
   should they use an accent tint like the filter chips do?
4. Should the app keep using iOS system colours (`systemBlue` for the tab bar,
   `.red/.orange/.green` for coverage) or bring them into the brand palette?
5. Dark mode currently comes free from the catalogue's dark appearances. Any new
   token needs one — `AccentColor` is the cautionary example of forgetting.
