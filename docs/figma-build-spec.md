# Julia — Figma screen recreation spec **v4** (reconciled across 10 built frames)

Everything marked ⚠️ is a correction to v1/v2 that has **already been applied to
the built frames**. Everything under "Open items" has not.

## Built frames — fileKey `iMoHTDAGPZi6VkRgUEf9vG`, page `Page 1`, page-level

| Node | Screen | Mode | Ref | Container |
|---|---|---|---|---|
| `1003:2` | Edit Recipe — `RecipeDetails.editModeContent` | Dark | `1001:27` | Form, scrolled |
| `1021:2` | Scan Instruction — `ScanInstructionView` | Light | `1001:9` | modal sheet, non-form |
| `1029:2` | Recipe Suggestion Detail — `RecipeSuggestionDetailView` | Light | `1001:6` | modal sheet + List |
| `1029:31` | Recipe Suggestions — `RecipeSuggestionsView` | Light | `1001:7` | modal sheet + List + bottom bar |
| `1074:2` | Recipe Text Import — `RecipeTextImportView` | Light | `1001:10` | modal sheet + Form |
| `1074:39` | Recipe URL Import — `RecipeURLImportView` | Light | `1001:11` | modal sheet + Form |
| `1074:92` | Ingredient Editor — `IngredientEditor` | Light | `1001:12` | **floating** bottom sheet over plain List |
| `1108:27` | Chef Chat — `ChefChatView` (empty) | Light | `1001:15` | `fullScreenCover`, no sheet chrome |
| `1114:2` | Recipe Details — `RecipeDetails.viewModeContent` | Light | `1001:13` | plain `ScrollView`, no card inset |
| `1125:2` | Settings Drawer — `SettingsDrawer` | Light | `1001:14` | **edge drawer**, pushes the presenting view |
| `1143:2` | Recipes — `RecipesView` | Light | `1001:16` | plain `.plain` List on `bgPrimary` |
| `1159:2` | Cook Mode — `CookModeView` | Dark | `1001:28` | full screen, drawer **expanded** + dim overlay |

Canvas 402 × 874 (iPhone 17 Pro). References are 603 × 1311 @ `scalingFactor 0.5`
= 1206 × 2622 @3x — **the capture is 1.5× the point size; divide by 1.5.**

## ⚠️ Corrections (applied)

1. **Section headers are 17pt Regular / 22 line**, not 15pt. Confirmed twice:
   cap height in IMG_0485 (18px @1.5× = 12.0pt cap ÷ 0.708em ⇒ 17pt, equal to
   the body cap in the same capture) and advance width in IMG_0514
   ("Substitutions" 103pt ⇒ 17pt). iOS 26 headers are body-size, not uppercased.
2. **Section headers inset to the row's content offset (abs ≈ 32) — but ONLY in
   a `List`/`Form` container.** Measured leading ink: IMG_0514 33.3pt, IMG_0485
   33.3 / 32.7pt. Implemented as a `Header` auto-layout wrapper with
   `paddingLeft 16` inside the `Section` group, so group height is unchanged.
   **⚠️ A plain `ScrollView` has no card gutter and its headers sit at abs 16**
   (all three on `1114:2`). Keep the `Header` wrapper either way so the anatomy
   matches; change only the padding.
3. **Separator leading inset = the row's content offset; trailing always 16.**
   Rows with a leading control push it out (IMG_0514: 48pt, past a 24pt
   checkbox); rows without use 16.
4. **Light toolbar glass — two recipes, by what is behind it.**
   - **Over `sysGroupedBg` / `backdrop`:** glass is LIGHTER than its ground.
     v1's `#000000 @ 6%` was invented and wrong. IMG_0514 interior `#FBFBFF`
     over `#F2F2F6`, with a *darker* vignette outside (`#ECECF1`). Use
     `#FFFFFF @ 78%` + `#FFFFFF` 1pt stroke + `#000000 @ 6%` blur 8 y 2.
     Confirmed on IMG_0510.
   - **⚠️ Over `sysBg` (white):** that recipe is invisible. Both IMG_0500 and
     IMG_0502 sample a flat, *darker* `#F5F5F5` disc (`.regularMaterial` over
     `systemBackground`) — no stroke, shadow only. Two independent confirmations.
   - **`Glass` on a drawer row** (iOS 26 automatic `Button`): rect at row bounds,
     r = h/2, `#000000 @ 4%`, `LAYER_BLUR 8`. A third recipe again.
5. **⚠️ `systemBlue` = `#007AFF`, not `#0088FF`.** The `#0088FF` in v2 came from
   sampling a P3 capture — exactly what the P3 rule below forbids. Source is
   decisive: `ScanInstructionView.swift:39` passes `color: .blue`, and the import
   sheets' Paste is `.background(.blue)`. One agent independently back-converted
   its sample to `#007AFF`. Corrected in all frames.
6. **Group gaps are container-dependent — measure per screen.** Observed
   card-bottom → next-card-top: **Form 62** (31 + 22 header + 9), **List 58**
   (27 + 22 + 9), **headerless List ≈ 35**. One auto-layout `itemSpacing` cannot
   express both; wrap headerless groups or set spacing per group.

## ⚠️ Display-P3 — read before sampling any pixel

**⚠️ Not every fetch is P3.** `1159:2`'s reference came back from
`get_screenshot` in sRGB and every sample hit its token exactly (checkbox
`#504F4B`, comment `#A7A6A5`, badge `#CC5D37` = `#FF7445 × 0.8` dim). Earlier
frames sampled ~7% desaturated. So verify per capture — **but the rule below is
unconditional either way: read the source, never a sample.**

The reference PNGs are (often) Display-P3 tagged. Sampled values read ~7% desaturated
against sRGB tokens: `primary #FF3900` samples as `#EB4C26`; `.red #FF3B30`
samples as `#EB4B46`; `.blue #007AFF` samples as `#3478F6`/`#3880F1`.
**Never derive a token from a pixel sample — read the source.** Sampling is
valid only for *relative* judgements (lighter/darker, same/different), which is
how correction 4 was settled.

## Backgrounds — decide by source, not by habit

There is no single screen background. In order:

1. Does the view set one? `RecipeTextImportView` / `RecipeURLImportView` set
   `.background(Color.app.backgroundSecondary)` + `.scrollContentBackground(.hidden)`
   ⇒ `backdrop #DDE2E1` paints the whole form. `IngredientsView` sets
   `.background(Color.app.backgroundPrimary)` on a `.plain` list ⇒ `#EFEFEF`.
2. Otherwise a `List`/`Form(.insetGrouped)` paints iOS
   `sysGroupedBg #F2F2F6` (IMG_0514), **not** the app's `bgPrimary`.
3. **⚠️ Otherwise — a plain `ScrollView` or `fullScreenCover` — it is
   `sysBg` (`#FFFFFF` / `#000000`).** `RecipeDetails.viewModeContent` (`1114:2`)
   and `ChefChatView` (`1108:27`) both land here; neither is a List.
4. Row/card surfaces are always `card`.

## Type ramp

| Role | Size / line | Style | Tracking (target, see open item 1) |
|---|---|---|---|
| Large nav title | 34 / 41 | Bold | −0.4 |
| Scroll-fade title | **21 / 25** | Bold | −0.3 |
| Screen title | 22 / 26 | Bold | −0.3 |
| Focused field value | 32 / 40 | Medium | −0.4 |
| Measurement line | 18 / 24 | Medium | −0.4 |
| **Section header** | **17 / 22** | Regular | −0.41 |
| Body, row label, toolbar button | 17 / 22 | Regular / Semibold | −0.41 |
| Nav title (inline) | 17 / 22 | Semibold | −0.41 |
| Card title | 15 / 20 | Semibold | −0.24 |
| Tag chip | 15 / 20 | Regular | −0.24 |
| Caption, coverage label | 12 / 16 | Regular | 0 |
| Caption2 ("servings") | 11 / 13 | Regular | 0 |

**⚠️ The scroll-fade title size is content-dependent, not a fixed style.**
`ScrollFadeTitle.calculateTitleFontSize` scales with title length and clamps at
`minSize 21`; `1114:2`'s 69-char title hits the clamp. Componentising it needs a
size range, not one value.

Family `SF Pro`. **Five legitimate styles: Regular, Medium, Semibold, Bold**
(+ Italic unused). `Medium` and `Bold` are source-driven (`.fontWeight(.medium)`,
`.title2.bold()`); Semibold reads too light where the source says Bold.

## Tokens — now a Figma variable collection

**⚠️ The tokens live in the `Julia` variable collection in the Figma file**
(28 COLOR variables, modes `Light` / `Dark`, groups `brand/` `ios/` `scrim/`).
Read them from the file rather than retyping hex. Every variable carries a
`description` and explicit `scopes`.

```
brand/  backdrop bgPrimary white offwhite200 offwhite400
        primary secondary danger textPrimary textSecondary label dot
ios/    sysBg sysGroupedBg card sep divider chevron placeholderText grabber
        systemBlue systemRed systemOrange systemGreen
        secondaryLabel* fillSecondary*
scrim/  modal floatingCard
```

`brand/*` mirrors `Julia/Assets.xcassets` and is authoritative over any pixel
sample. `ios/*` is inherited from SwiftUI and must never be conflated with brand
colour. `scrim/*` is ours, measured.

**\* Translucent — a flat hex is wrong.** `ios/secondaryLabel` is
`#3C3C43 @ 60%` light / `#EBEBF5 @ 60%` dark (Apple's own definition), so it
composites correctly per surface — it measured `#85858A` over `sysGroupedBg`,
`#7A7B7F` over `backdrop`, and the same token covers both. `ios/fillSecondary`
is `#787880 @ 16%` light / `@ 36%` dark; it predicted IMG_0500's measured
`#E9E9EA` over white exactly. Never freeze either to a composite.

**Coverage bands are not tokens.** `RecipeSuggestionsView.swift:128` and
`RecipeSuggestionDetailView.swift:132` both switch on `coveragePercent`:
`>= 0.8` → `ios/systemGreen`, `0.5..<0.8` → `ios/systemOrange`, else
`ios/systemRed`. The mapping is band logic; don't invent `coverage.*`.

**⚠️ `brand/dot` is an app inconsistency, not a design decision.** `Dot.swift`
hard-codes `Color(red:1.0,green:0.30,blue:0.15)` = `#FF4D26` instead of
`brand/primary #FF3900`. Both render on IMG_0500 at once. Consolidate in Swift.

Tinted fills are an accent at opacity, not flat hex: `Icon tile · accent`
`accent @ 12%` (`color.opacity(0.12)`), `Filter chip` `primary @ 20%`,
`Tag filter` `primary @ 10%`.

**Binding:** frames are built with **raw hex**, then rebound to variables in one
scripted pass. Do not bind during a build — the pass is scripted either way, so
binding per-frame adds risk without saving work.

## Sheets — three distinct species

**Modal detent sheet** (`.sheet`) — 5 of 7 frames:
- Surface y 62–72 by detent, full width, **top** corners r 40, `clipsContent`.
- `Grabber` 36 × 5 in `grabber`, only when `presentationDragIndicator(.visible)`
  (the URL import hides it — check the source).
- Toolbar items are children of the sheet, sheet-local y ≈ 17–18.
- Scroll-edge bands re-derive inside a sheet: 112/64 → **66/28**.
- `Sheet scrim · modal` = `#000000 @ 22%` over the presenting view's real
  background.

**Floating bottom sheet** (`FloatingBottomSheet`) — `1074:92`:
- Bottom-anchored card, x 12 / w 378, **all four** corners r 24, fill `white`,
  `DROP_SHADOW #000000 10%`, blur 24, y 4.
- `Sheet scrim · floating card` = **`#000000 @ 5%`** — hard-coded as
  `Color.black.opacity(0.05)` in the source. 22% is visibly wrong here.
- **Layer order matters:** the scrim sits inside the `NavigationStack` content,
  so nav bar and status bar render *above* it. Order: list → scrim → nav bar →
  status bar → sheet.

**⚠️ Edge drawer** (`SettingsDrawer`, presented by `NavigationView`) — `1125:2`:
- **The presenting view is pushed, not covered.** `NavigationView` applies
  `.offset(x: 280)` to the TabView and bottom chrome. Model as a transparent
  402 × 874 wrapper named `Screen content · offset x 280` inside the screen
  frame, children in their own 0-based coordinates, clipped by the frame.
- `Drawer` surface: x 0, y 0, **280 × 874** (full height —
  `.ignoresSafeArea(.container, edges: .vertical)`), fill `brand/white`,
  **radius 0 on all corners**, clipped. Content inset 24 L/R, 72 top, 48 bottom;
  group spacing 24, row spacing 16.
- **No scrim at all** — the tap-out catcher is `Color.clear`
  (`SettingsDrawer.swift:35`). Sampling confirms plain `bgPrimary` right of
  x 280. Neither 22% nor 5% applies.
- Shadow `#000000 @ 20%`, blur 20, offset (5, 0), cast rightwards. The source's
  second shadow (`@ 10%`, x −5) falls off-frame; don't draw it.
- Layer order: pushed content → drawer → **status bar** (above the drawer). No
  nav chrome above it — the pushed view's nav bar travels with its content.

**Dim overlay** (not a sheet, but a fourth scrim value): `CookModeView.swift:74`
draws `#000000 @ 20%` over the content whenever `isDrawerExpanded`. Distinct
from `scrim/modal` 22% and `scrim/floatingCard` 5%; needs its own token.

**⚠️ Header and separator insets inside a drawer are 20**, from the drawer's own
`.padding(.horizontal, 20)` — a third value beside List/Form 32 and plain
`ScrollView` 16. The drawer separator belongs to the header, not the list, so it
does NOT take the row content offset.

## System chrome we do NOT draw

**The iOS keyboard is never drawn.** One empty placeholder the user drops a
screenshot into: name exactly `Placeholder · System keyboard`, x 0, width 402,
`y` = measured keyboard top edge, height = frame bottom − that edge (the height
is the point — everything above must stay put), flat `#E5E5EA` / `#2C2C2E`, 1pt
dashed `label` stroke, one centred 12pt `label` caption `System keyboard`, no
other children. Same for share sheets, photo pickers, camera preview.
Status bars **are** drawn — small, and they carry app state.

## Layer naming (componentisation reads these)

`<Screen> — <SwiftFile>.swift (Light|Dark)` · `Sheet` · `Sheet scrim` ·
`Sheet surface` · `Grabber` · `Drawer` · `Screen content · offset x <n>` ·
`Nav bar · <title>` · `Nav title · <title>` · `Scroll fade title` ·
`Section · <Header>` · `Header` · `Card` · `Card · <name>` · `Row · <label>` ·
`Separator` · `Checkbox` · `Labels` · `Value · <x>` · `Caption · <x>` ·
`Actions` · `Button · <label>` · `Glass` · `Input bar` ·
`Field · <placeholder>` · `Capsule` · `Placeholder · <prompt>` · `Tab bar` ·
`Tab item · <title>` · `Toggle · <label>` (+ `Track`, `Knob`) · `List · <name>` ·
`Button · Dot` (the `FloatingActionMenu` FAB — no textual label, so `Button ·
<label>` does not fit) ·
`Keyboard accessory bar` · `Filter bar` · `Placeholder · <surface>`

Nested sub-sections use `Section · <sub-header>` so every header can stay a
plain `Header`.

**⚠️ `Icon tile` was doing double duty — it is now two names:**
- `Icon tile · accent` — rounded tile, `accent @ 12%` (Scan Instruction)
- `Icon tile · fill` — disc, `ios/fillSecondary` (Chef Chat quick actions)

**⚠️ Three chip types, three names.** They collided twice under one name:
| name | where | metrics |
|---|---|---|
| `Tag chip · <text>` | Edit Recipe, removable tag | `brand/secondary` fill, 15pt, xmark, h 29 |
| `Tag filter · <text>` | RecipesView tag bar | `primary @ 10%`, 13pt Medium, h 27, pad 12×6 |
| `Filter chip · <text>` | RecipeSuggestions scope toggle | `primary @ 20%`, 17pt, h 34 |

At componentising time this is one component with a variant axis, not three.
A precise predicate matters: `findAll("Chip")` also matches `"Chip row"`.

Toolbar button label colour comes from the **source**: Edit Recipe's `Done` is
`brand/primary`; Suggestions' and the import sheets' are `.secondary` ⇒
`ios/secondaryLabel`.

## Plugin API gotchas (all hit for real)

- `node.query()` cannot parse `·` — throws `unexpected character (0xc2)`. Use
  `findAll` with a precise predicate.
- **Wrapping TEXT collapses to 0pt on a naive `FILL`.** Order: `characters` →
  `textAutoResize='NONE'` → `resize(w, lineHeight)` → `textAutoResize='HEIGHT'`
  → `layoutSizingHorizontal='FILL'`. Short single-line text can just HUG.
- `createNodeFromSvg` may return an id that doesn't match what the same script
  reports — re-find SVG icons by name.
- `resize()` before sizing modes. `FILL` only after `appendChild`. `HUG` only on
  an auto-layout frame or a TEXT child.
- Colours 0–1. Paint `color` is `{r,g,b}` with `opacity` alongside; gradient
  stops *do* take `a`.
- No `figma.notify`, `loadAllPagesAsync`, `setPluginData`, `createImageAsync`.
  `console.log` is invisible — `return` everything, ids included.
- Seat scrolled content by landmark: `content.y = target - landmark.y`.
- **`clone()` sub-components from a sibling frame wherever one exists** — status
  bars, nav bars, list rows, tab bars, SF-Symbol vectors. `1143:2` was built in
  5 Figma calls this way, and shared parts come out byte-identical instead of
  independently measured.
- **⚠️ But cloning propagates errors as faithfully as it propagates style.**
  Always re-measure a cloned sub-component against *your own* reference and
  report any deviation you keep for consistency's sake. Two such deviations are
  already live — see open item 9.
- **SwiftUI `shadow(radius: R)` → Figma `DROP_SHADOW` blur `2R`** (same x/y).
- **iOS 26 switch metrics are not the classic 51 × 31 UISwitch.** Measured:
  track 62.5 × 28.5 r 14.25, knob 37 × 23.7 r 11.85, inset 2.4 top/bottom,
  1.7 trailing. Measure, don't assume.
- **`Divider()` is a 0.33pt hairline at `#3C3C43 @ 29%`.** Render it as the
  house 1pt `Separator` bound to `ios/divider` (15%) so density matches.
- **⚠️ `ios/divider` DARK is wrong at 1pt.** The published `#545458 @ 60%` is
  right for the real 0.33pt hairline (measured: one pixel row at `#19191A`,
  α ≈ 0.595 after backing out 0.5px coverage) but at the house's 1pt it lays
  down ~3× the reference's ink. Equal ink is **≈ 20%**. Fix at the token, not
  per frame.
- **`Separator` is the WRAPPER frame; the hairline is its child rectangle.**
  The wrapper correctly has empty `fills` — an inspection that reads only the
  node named `Separator` will wrongly conclude the separators are invisible.
  Check the child.
- **Scroll-edge band tint polarity follows the ground, not the screen fill.**
  Tinting with the screen background is invisible over a light ground like
  `bgPrimary #EFEFEF`; over light grounds tint with white
  (`#FFFFFF @ 31%` + gradient `@ 50% → 0%`), keeping the 112/64 geometry.
- **Don't punch out an icon with a plate filled in the tile colour** — it
  couples the glyph to its background and breaks on recolour
  (`photo.on.rectangle` does this). Use an even-odd compound path, as
  `camera.fill` does.

## Open items — NOT yet applied

1. **Tracking is applied on `1021:2` only; the other nine are at 0.** Interim
   rule for new frames: **leave `letterSpacing` at 0** and honour the
   reference's text-box width. Evidence that the SF table is right is now
   quantitative and from four independent frames: drift equals 0.41pt ×
   character count (`tablespoon` 10 chars → 4.1pt; "Yukon Gold potatoess" 24
   chars → 9.8pt), strings run 3–6% wide, and "Export Recipes" overshoots by
   exactly 6pt. Author it once with the type styles, then re-validate all ten.
2. **Toolbar item diameter: three references measure 44pt; the frames use 40.**
   Deprioritised by the user with glass polarity. Fix at componentising.
3. **`Row · <label>` wrap width is unresolved and three frames carry inferred
   values.** `1074:92` uses 152 on row 2; `1114:2` uses 240 and 284.5 per-row;
   bracketing `1114:2`'s own wraps puts a single `Name` width at 233.8–245.8pt,
   yet at tracking 0 no single value reproduces every break. Probably the
   flexible `Toggle` in `SelectableModifier` absorbing width. **Resolve
   alongside item 1, and before componentising `Row` — these two are the same
   problem.**

   **⚠️ Now effectively proven unsolvable by a fixed width.** On `1173:14` the
   per-row brackets are *mutually exclusive*: row 2 needs a right limit < 330.5
   while row 5 needs >= 365.3. No single `Name` width, and no fixed right edge,
   can reproduce every wrap. The row must hug a flexible trailing element, or
   tracking must be authored first — a per-row constant is a dead end.
4. **Hand-drawn SF Symbols** across all frames match silhouette and bbox to
   ~1pt, not interior curves. `clone()` from a sibling frame where one already
   exists rather than redrawing. Replace with real assets if components must be
   pixel-true.
5. **Glass is ground-relative and now has FIVE recipes** — over
   `sysGroupedBg` (lighter than ground), over `sysBg`/white (flat `#F5F5F5`),
   on a drawer row (`#000000 @ 4%` + blur), over dark `backdrop`
   (`#314048`, *darker* than ground, + `#4B708B` rim), and over dark
   `bgPrimary` (`#000000 @ 19%` + `#FFFFFF @ 10%` rim). There is no single
   glass token; it is a function of what sits behind it. Deprioritised by the
   user, but this is why.
6. **Dark-token verification so far** (from `1159:2`, the only dark screen built
   since the collection existed): `ios/secondaryLabel` `#EBEBF5 @ 60%` **holds**;
   `ios/sysBg` `#000000` **holds**; `ios/card` `#1C1C1E` **holds**;
   `ios/divider` dark needs the fix above. `systemBlue`, `systemRed` and
   `chevron` dark values are **still unverified** — no dark capture has shown
   them yet. Note `CookModeView`'s grabber is app-drawn
   `Color.secondary.opacity(0.3)` = `#EBEBF5 @ 18%`, not `ios/grabber`, so that
   token also remains unexercised in dark.
7. **Rebind pass owed:** all ten frames are raw hex; the `Julia` collection
   exists but nothing is bound to it yet.
8. **Inferred, not observed** — carry these forward, they are not measurements:
   `1029:31`'s clipped top row reads "3/10"; `1074:92` row 2's 152pt width;
   `1125:2`'s recipe titles past the clip (five recovered from `1029:31`'s row
   names, two from `Julia/Resources/recipeData.json`, the rest are the readable
   substring verbatim) and its chip 2 text `baking` from "bak".
9. **⚠️ Two measurable errors are now in two frames each, inherited by cloning.**
   Fix at the single point where the sub-component is created, not per frame:
   - `Tab bar`: **SETTLED — there was no error.** The `775.3–834.7 / h 59.4`
     read off IMG_0499 was a mis-attributed landmark: those are the **blue pill
     and FAB band**, not the white capsule. Three captures now agree the capsule
     is **770–839.3 (h ~69.3)** with the pill inset ~5.33. The built frames were
     right; nothing to fix.
   - `Field · Search recipes`: h 43 at y 117, where IMG_0499 measures h 38.7 at
     y 120. Cloned into `1143:2`.
   - `1125:2`'s tab-bar capsule also has no shadow; both references show a soft one.
10. **The selected tab item is a different box from its siblings** — unselected
   60 × 60 r 30 unfilled, selected filled `ios/systemBlue` with a glyph plus a
   label. **⚠️ Its metrics differ between captures:** IMG_0499 gives
   136 × 50 r 25 with a 22px glyph and a 17pt label; IMG_0498 gives
   143.3–146 × 58.7–59.3 r ~29.5 with a 20px glyph and a ~14pt label.
   **Source settles it: `.system(size: 14, weight: .medium)`** — so the ramp
   needs **14 / 18 Medium**, and the house's 13 Semibold (used in the built
   frames for clone consistency) is ~2pt narrow. Fix at componentising.
11. **`brand/dot` vs `brand/primary` now collide on two frames** (IMG_0500 and
   IMG_0499): chips and labels use `primary`, the FAB and its glow use `dot`.
   The FAB glow is also the library's only brand-coloured shadow
   (`dot @ 50%` blur 16 y 3 + `@ 20%` blur 32 y 5). Consolidate in Swift.
12. **Status bars are not comparable across references** — IMG_0485's capture has
   a two-row TestFlight banner. Keep each frame faithful to its own reference.

## Working inside `Design Mocks`

The built frames now live in a **clipping FRAME** named `Design Mocks`
(`1001:60`), not on the page. Two consequences:
- **Its right edge is abs 10857.** A 402-wide frame placed beyond ~10455 is
  wholly outside the clip: it builds fine, but `absoluteRenderBounds` comes back
  `null` and every screenshot returns 1×1 blank. One agent burned six calls on
  that dead end. Collision-check *and* clip-check before choosing a slot, and
  start a new row rather than running off the right edge.
- Do not resize or reparent the container to make room — that is the user's
  arrangement.

**Name frames by the SCREEN, and search for orphans by node id, not by name.**
After two agents were killed mid-build, a search for frames named
`Ingredients —` missed a completed frame named `Pantry — IngredientsView.swift`
and a duplicate got built. `1155:2` is that duplicate, now labelled
`DUPLICATE?` in the file; `1173:14` is the verified one.

## Remaining screens

Built: 10. The mapping doc (`figma-screenshot-mapping.md`) lists all 26 captures.
Still to hand-build as new layouts: **RecipesView** (IMG_0499 `1001:16`),
**IngredientsView** (IMG_0498 `1001:17`), **CookModeView** (IMG_0482 `1001:28`),
**ProcessingResults** (IMG_0487/0488 `1001:25`/`1001:24`), and
**EmptyIngredientsView** (IMG_0473 `1001:3`).

Everything else in the grid is a **variant** of a built screen — a dark twin
(IMG_0480, 0489, 0491, 0492), a different state (IMG_0481 drawer, IMG_0486 menu,
IMG_0493 populated chat, IMG_0512 scrolled) or the same list in its other tab
(IMG_0497). Those are component variants and mode swaps once the collection is
bound, not fresh builds.
