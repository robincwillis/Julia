# Design Tokens

Source of truth: Figma file `iMoHTDAGPZi6VkRgUEf9vG`, node `1242:34`
("Design Tokens — Julia (live, bound to the Julia collection)"). This is the
same `Julia` variable collection referenced in `docs/figma-build-spec.md`
§"Tokens — now a Figma variable collection" — that section's token list
(`brand/backdrop bgPrimary white offwhite200 offwhite400 primary secondary
danger textPrimary textSecondary label dot` / `ios/*` / `scrim/*`) predates
this reorganization and needs reconciling once the plan below is executed.

Transcribed 2026-09-12. Re-pull from Figma before trusting this over the file
if it's been a while — this is a snapshot, not a live mirror.

## Colors

| Token | Light | Light hex | Dark | Dark hex | Source / note |
|---|---|---|---|---|---|
| `brand/primary` | 🟧 | `#FF3900` | 🟧 | `#FF7445` | merge dot and any other red colors |
| `xcode/primary-disabled` | 🟧 | `#F9AA93` | 🟫 | `#9C6454` | |
| `brand/secondary` | 🟦 | `#007AFF` | 🟦 | `#45AAFF` | secondary color is **not** a background color, it's an alternative pop color — wait for special |
| `xcode/secondary-disabled` | 🟦 | `#D8E2E4` | 🟦 | `#5D6D70` | |
| `brand/danger` | 🟥 | `#FF3B30` | 🟧 | `#FF7445` | same as brand/primary |
| `ios/systemRed` | 🟥 | `#FF3B30` | 🟧 | `#FF7445` | same as brand/primary |
| `xcode/AccentColor` | 🟥 | `#FF3B30` | 🟧 | `#FF7445` | same as brand/primary |
| `ios/systemBlue` | 🟦 | `#007AFF` | 🟦 | `#45AAFF` | same as brand/secondary |
| `ios/systemGreen` | 🟩 | `#34C759` | 🟩 | `#30D158` | default |
| `ios/systemOrange` | 🟨 | `#FAAE00` | 🟨 | `#FAAE00` | custom orange, same color in light and dark mode |

## Grey Scale

> All rows below: **deprecated in favor of specific type and background
> tokens, but maybe useful in future.**

| Token | Light | Light hex | Dark | Dark hex |
|---|---|---|---|---|
| `brand/white` | ⬜ | `#FFFFFF` | ⬛ | `#000000` |
| `xcode/white` | ⬜ | `#FFFFFF` | ⬛ | `#000000` |
| `xcode/grey-500` | ⬛ | `#1C1C1C` | ⬜ | `#E5E5E5` |
| `xcode/grey-400` | ⬛ | `#494949` | ⬜ | `#C4C4C4` |
| `xcode/grey-300` | 🔲 | `#8D8C8B` | 🔲 | `#A7A6A5` |
| `xcode/grey-200` | 🔲 | `#C8BFB4` | 🔲 | `#7A7671` |
| `xcode/grey-100` | 🔲 | `#EBE6E1` | 🔲 | `#64625F` |
| `xcode/offwhite-400` | 🔲 | `#DDDAD1` | 🔲 | `#504F4B` |
| `xcode/offwhite-500` | 🔲 | `#CFCEC5` | 🔲 | `#5A5955` |
| `xcode/offwhite-300` | 🔲 | `#E9E9E5` | 🔲 | `#464645` |
| `xcode/offwhite-200` | 🔲 | `#EDEDED` | 🔲 | `#3C3C3C` |
| `xcode/offwhite-100` | 🔲 | `#FEFEFE` | 🔲 | `#323232` |

`brand/white`, `xcode/white`, `xcode/grey-*`, `xcode/offwhite-*` are the raw
ramp — the underlying `Assets.xcassets` colorsets. The `Type` and
`Background` sections below are semantic aliases on top of this ramp.

## Type

| Token | Light | Light hex | Dark | Dark hex | Source / note |
|---|---|---|---|---|---|
| `brand/text-primary` | ⬛ | `#1C1C1C` | ⬜ | `#FFFFFF` | Primary Text |
| `brand/text-secondary` | 🔲 | `#494949` | 🔲 | `#C4C4C4` | Secondary Text |
| `brand/text-tertiary` | 🔲 | `#494949` | 🔲 | `#C4C4C4` | Tertiary text, believed to be used in ingredients list items |
| `brand/label-primary` | 🔲 | `#8D8C8B` | 🔲 | `#A7A6A5` | primary label color for forms |
| `brand/label-secondary` | 🔲 | `#3C3C43 @ 60%` | 🔲 | `#EBEBF5 @ 60%` | secondary label color for forms — translucent, composites over its surface (`ios/secondaryLabel`) |
| `brand/text-disabled` | 🔲 | `#494949` | 🔲 | `#C4C4C4` | anytime text or input text is disabled |
| `brand/text-placeholder` | 🔲 | `#C5C5C7` | 🔲 | `#48484A` | input placeholder text (`ios/placeholderText`) |

## Background

| Token | Light | Light hex | Dark | Dark hex | Source / note |
|---|---|---|---|---|---|
| `brand/background-primary` | 🔲 | `#EFEFEF` | ⬛ | `#242424` | main background color, used for core tab and list views |
| `brand/background-secondary` | 🔲 | `#DDE2E1` | ⬛ | `#000000` | secondary background color, used for recipe details and chat |
| `brand/background-sheet` | 🔲 | `#EFEFEF` | ⬛ | `#1C1C1E` | background color for sheets and modals |
| `brand/background-form` | 🔲 | `#EDEDED` | 🔲 | `#3C3C3C` | background color for forms |
| `brand/background-form-field` | 🔲 | `#DDDAD1` | 🔲 | `#504F4B` | background color for form fields |
| `brand/background-keyboard-toolbar` | 🔲 | `#DDE2E1` | 🔲 | `#374750` | background color for keyboard accessory toolbar |
| `brand/background-card` | 🔲 | `#DDE2E1` | 🔲 | `#374750` | used for inline cards, like timings and servings in the recipe details |

---

## Mapping to the current codebase

Today's tokens live in two places: `Julia/Assets.xcassets/*.colorset` (raw
color pairs) and `Julia/Utilities/Theme.swift` (`AppTheme.Colors`, the Swift
names views actually call). 13 colorsets exist today; the new table specifies
substantially more semantic tokens than currently exist as colorsets.

| Current colorset | Current value (L / D) | `Theme.swift` name | New Figma token | Status |
|---|---|---|---|---|
| `primary` | `#FF3900` / `#FF7445` | `.primary` | `brand/primary` | **unchanged** |
| `primary.disabled` | `#F9AA93` / `#9C6454` | `.primaryDisabled` | `xcode/primary-disabled` | **unchanged** |
| `secondary` | `#007AFF` / `#45AAFF` | `.secondary` | `brand/secondary` | **value changes** from `#B3DAD7`/`#718F8D` (see flag 2) |
| `secondary.disabled` | `#D8E2E4` / `#5D6D70` | `.secondaryDisabled` | `xcode/secondary-disabled` | **unchanged** |
| `danger` | `#800020` / `#DC143C` | `.danger` | `brand/danger` | **value changes** to `#FF3B30` / `#FF7445` (see flags) |
| `AccentColor` | `#FF3900` / `#FF7445` | (Xcode asset, no Swift alias) | `xcode/AccentColor` | **value changes** to `#FF3B30` / `#FF7445` (see flags) |
| `white` | `#FFFFFF` / `#000000` | `.white` | `brand/white` / `xcode/white` | **unchanged** |
| `grey.300` | `#8D8C8B` / `#A7A6A5` | `.textLabel` | `brand/label-primary` | **unchanged value**, rename `textLabel` → `labelPrimary` |
| `grey.400` | `#494949` / `#C4C4C4` | `.textSecondary` | `brand/text-secondary` (also aliased by `text-tertiary`, `text-disabled`) | **unchanged value**, but now backs 3 semantic names |
| `text.primary` | `#1C1C1C` / `#FFFFFF` | `.textPrimary` | `brand/text-primary` | **unchanged** |
| `background.primary` | `#EFEFEF` / `#242424` | `.backgroundPrimary` | `brand/background-primary` | **unchanged** |
| `background.secondary` | `#DDE2E1` / `#374750` | `.backgroundSecondary` | `brand/background-secondary` **or** `brand/background-keyboard-toolbar` / `brand/background-card` | **ambiguous — see flags**, the new table splits this one colorset into three tokens with two different dark values |
| `offwhite.200` | `#EDEDED` / `#3C3C3C` | `.offWhite200` | `brand/background-form` | rename only |
| `offwhite.400` | `#DDDAD1` / `#504F4B` | `.offWhite400` | `brand/background-form-field` | rename only |

**Net new tokens with no current colorset**, needed to fully adopt the table:

- `brand/background-sheet` (`#EFEFEF` / `#1C1C1E`) — distinct from
  `background-primary` only in dark mode (`1C1C1E` vs `242424`)
- `brand/label-secondary` (`ios/secondaryLabel`, translucent — needs an
  opacity-based Color, not a colorset)
- `brand/text-placeholder` (`ios/placeholderText`)
- `xcode/grey-500` / `grey-200` / `grey-100`, `xcode/offwhite-500` / `-300` /
  `-100` — currently only `grey.300`, `grey.400`, `offwhite.200`, `offwhite.400`
  exist as colorsets; the rest of the ramp isn't in the asset catalog yet
  (may not need to be, given the deprecation note)

## Flags — resolved 2026-09-12

1. **`brand/primary` (`#FF3900`) vs. `brand/danger` / `ios/systemRed` /
   `xcode/AccentColor` (`#FF3B30`).** ~~The note on all three says "same as
   brand/primary," but the hex is not actually identical.~~ **Resolved:
   consolidate to `#FF3900`/`#FF7445` everywhere.** Applied: `danger.colorset`
   now matches `primary.colorset` exactly; `AccentColor.colorset` already
   matched (`#FF3900`/`#FF7445` — no change needed); `Dot.swift`'s hard-coded
   third variant (`#FF4D26`) now reads `Color.app.primary`.

2. **`ios/systemBlue` "same as brand/secondary."** ~~`systemBlue` is
   `#007AFF`/`#45AAFF` (blue); `brand/secondary` is `#B3DAD7`/`#718F8D`
   (teal) — not the same color by any reading.~~ **Resolved 2026-09-13:**
   the teal value was a transcription error in this table — confirmed with
   Robin that `brand/secondary` is `#007AFF`/`#45AAFF`, identical to
   `ios/systemBlue`, exactly as the note originally said. Applied:
   `secondary.colorset` now carries `#007AFF`/`#45AAFF` (was
   `#B3DAD7`/`#718F8D`). This also retroactively corrects the 2026-09-13
   migration that had replaced hard-coded `.blue`/`systemBlue` literals with
   `Color.app.secondary` across the tab bar active pill, the ingredient
   editor's number pad 0 button, the instructions step-number badge, the Ask
   Julia user chat bubble, the receipt scanner's nav bar tint, and
   `prominentKeyboardAccessoryStyle`'s default fill — those call sites now
   render the correct blue without further changes.

3. **`brand/secondary` is declared not a background color** ("wait for
   special"), but it's currently used as a `.background()` fill in three
   places: `IngredientEditor.swift:235`, `RecipeEditTagsSection.swift:34`,
   `RecipeRawTextSection.swift:40`. **Deferred to the screen-by-screen
   review** — Robin will decide the replacement per screen rather than a
   blanket swap now. Left untouched; tracked in `docs/TODO.md` → Design
   consistency.

4. **`brand/text-secondary`, `brand/text-tertiary`, and `brand/text-disabled`
   are all identical values** (`#494949`/`#C4C4C4`). Still open whether
   that's intentional or a placeholder pending differentiation — disabled
   text usually reads lower-contrast than secondary/tertiary, not identical.
   Added as three distinct `Color.app.*` names sharing one asset for now
   (`textSecondary`, `textTertiary`, `textDisabled` on `grey.400`), so call
   sites can read semantically today and the values can diverge later
   without another rename.

5. **`brand/background-secondary` dark value conflicts with itself** against
   the current `background.secondary` colorset (`#374750`, the value the
   table separately assigns to `brand/background-keyboard-toolbar` and
   `brand/background-card`). **Resolved: pure black (`#000000`) in dark mode
   is intentional** for the true "recipe details and chat" token. **Not yet
   applied to the existing `background.secondary` asset** — today's 11
   `Color.app.backgroundSecondary` call sites are, per
   `figma-build-spec.md`, mostly acting as the *backdrop* role (sheet/form
   backgrounds), and only `RecipeDetails.swift` is genuinely "recipe
   details." Flipping the shared asset to black now would silently go dark
   on ~9 unrelated screens before they've been reviewed. Instead, added a new
   `background.card` colorset carrying today's `#DDE2E1`/`#374750` value,
   with `backgroundKeyboardToolbar` / `backgroundCard` pointing to it — so
   the backdrop role has its own home. `backgroundSecondary` itself keeps its
   current value and call sites until the screen-by-screen pass reassigns
   each one to either the (still-to-come) true black `background-secondary`
   or `backgroundCard`/`backgroundKeyboardToolbar`.

6. **`brand/background-primary` vs. `brand/background-sheet`** share the same
   light value (`#EFEFEF`) but differ only in dark mode (`#242424` vs
   `#1C1C1E`). Still open — not yet acted on either way; `background-sheet`
   has no colorset yet.

## Applied 2026-09-12

- `danger.colorset` → `#FF3900`/`#FF7445` (was `#800020`/`#DC143C`)
- `Dot.swift:28` hard-coded red → `Color.app.primary`
- `Theme.swift`: `textLabel` (and its duplicate alias `grey300`) renamed to
  `labelPrimary` everywhere (12 call sites + `IngredientRow.swift` +
  `SettingsDrawer.swift`)
- `Theme.swift`: added `textTertiary`, `textDisabled` (alias `grey.400`,
  unused so far), `textPlaceholder` (new `text.placeholder` colorset,
  `#C5C5C7`/`#48484A`), `labelSecondary` (`Color(uiColor: .secondaryLabel)`,
  dynamic — matches `ios/secondaryLabel`'s translucent definition exactly
  rather than freezing a flat hex), `backgroundKeyboardToolbar` /
  `backgroundCard` (new `background.card` colorset, `#DDE2E1`/`#374750`)
- New colorsets: `background.card`, `text.placeholder`

## Applied 2026-09-13

- `secondary.colorset` → `#007AFF`/`#45AAFF` (was `#B3DAD7`/`#718F8D`) — see
  flag 2. Every `Color.app.secondary` call site, including the systemBlue
  literals migrated to it earlier the same day, now renders the corrected
  blue automatically.

## Still open / deferred

- Flag 6 (background-primary vs. -sheet): unresolved, no code impact yet.
- Flag 3: `secondary`'s 3 background call sites — deferred to the
  screen-by-screen review, tracked in `docs/TODO.md`.
- Flag 5's second half: reassigning the 11 existing `backgroundSecondary`
  call sites (which are backdrop vs. which are truly recipe-details/chat),
  and only then flipping `background.secondary`'s own dark value to
  `#000000` — also deferred to the screen-by-screen review.
- `figma-build-spec.md`'s "Tokens — now a Figma variable collection" section
  still describes the pre-reorg 28-variable collection and should be
  re-pulled once the deferred items above land.
