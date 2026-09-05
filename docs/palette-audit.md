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
- `AccentColor` `#FF3900` → **no dark variant**, so it stays `#FF3900` while
  `primary` shifts. Anything on the system tint diverges from anything on the
  app token, in dark mode only.
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
