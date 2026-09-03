# Testing

`JuliaTests` uses Swift Testing (`@Test`, `#expect`, `#require`). The suite is
split by what each stage of the pipeline actually needs, so most of it runs
anywhere and nothing silently no-ops.

## Adding a test case is a file drop

Put a file in one of these and it is picked up automatically — no Xcode step,
no code edit:

```
JuliaTests/Fixtures/Images/   .jpg .jpeg .png .heic   photos of recipes → OCR, then full pipeline
JuliaTests/Fixtures/Text/     .txt                    pasted recipe text → reconstruction, then full pipeline
JuliaTests/Fixtures/Web/      .html .htm              saved recipe pages → JSON-LD extraction (offline)
```

Two things make that work:

1. `JuliaTests` is an Xcode 16 **synchronized folder group**
   (`PBXFileSystemSynchronizedRootGroup`), so Xcode adds new files to the target
   by itself.
2. `TestAssets` discovers fixtures **by extension at runtime** rather than from
   a hardcoded list.

Resources are flattened into the test bundle, so **fixture names must be unique
across all three folders**.

> This replaces the previous arrangement, where `imageNames` and `textFiles`
> were hardcoded arrays at the top of the test file. They referenced assets
> that were not in the repo, so the suite loaded zero images and its one live
> test passed vacuously in 0.012 seconds.

## Suites

| Suite | Needs | What it asserts |
|---|---|---|
| `TextReconstructionTests` | nothing | Empty input is safe, blanks are dropped, no content is silently lost, distinctive text survives |
| `IngredientParsingTests` | nothing | Heuristic parsing: decimals, `1/2`, `½`, `1½`, `2-4` ranges, multi-word names, empty rejection, `toString` round trip |
| `TextRecognitionTests` | nothing | Vision OCR reads back text rendered into an image at runtime; every image fixture yields text |
| `WebScraperTests` | nothing | JSON-LD extraction against local HTML — field mapping, `@graph` nesting, all three `author` shapes, ISO-8601 durations, `<script>`/`<style>` stripping, no-JSON-LD returns nil |
| `FullPipelineTests` | Apple Intelligence | End-to-end `processText` / `processImage`: titled recipe with ingredients, instructions, retained raw text |

### Apple Intelligence gating

Classification and AI ingredient parsing route through Foundation Models.
`FullPipelineTests` carries:

```swift
.enabled(if: TestAssets.isAppleIntelligenceAvailable, "…")
```

so it **skips** rather than fails when the model is unavailable. Everything
else still runs. `TestAssets.appleIntelligenceStatus` reports the reason, and
it is written at the top of every attached log.

Availability varies by simulator and by device settings — do not assume a green
run means those tests executed. Check the report.

### `.available` does not guarantee a request will succeed

Observed 2026-09-03: after roughly six full suite runs on one simulator, both
pipeline tests began failing in ~3.7s with

```
The operation couldn't be completed.
(FoundationModels.LanguageModelSession.GenerationError error -1.)
```

while the offline 36 kept passing. The code was byte-identical to a run that
had passed 38/38 three times the same day — no `.swift`, `.pbxproj` or
`.plist` change between them — so it was environmental, not a regression.
Rebooting the simulator did not clear it, and the simulator log had nothing.

Two things follow:

1. **The gate is insufficient.** `.enabled(if:)` checks
   `availability == .available`, which is evaluated *before* any request. The
   model can report available and still refuse to generate — assets evicted,
   a quota, or the host service degrading under repeated runs. When that
   happens the suite goes **red rather than skipping**, which looks like a code
   regression and is not one.
2. **`GenerationError error -1` carries no diagnosis.** If you hit it, first
   establish whether compiled inputs changed at all:

   ```sh
   git diff --name-only <last-green-commit>..HEAD | grep -E '\.swift$|\.pbxproj$|\.plist$'
   ```

   Empty output means look at the environment, not the code.

Hardening the gate is tracked in [TODO.md](TODO.md).

### Why no expectations-per-asset

Considered and rejected for now: a companion JSON of expected values per
fixture would be a stronger regression gate, but it means authoring
expectations for every asset you add, which works against the file-drop
workflow. The current assertions are deliberately shape-based ("a title was
produced", "ingredients are non-empty") because the classifier is a
non-deterministic language model — see below.

## Running

```sh
xcodebuild -project Julia.xcodeproj -scheme Julia \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Or ⌘U in Xcode; the gutter ▶️ runs a single test.

## Reading the detailed dumps

Assertions tell you *that* something broke. `TestLog` tells you what OCR,
reconstruction and classification actually produced — which is what you want
when tuning prompts or heuristics.

Output is recorded as a **test-report attachment** (`Testing.Attachment`), not
a file. Open it from the Report navigator in Xcode.

Two earlier approaches do not work here, so don't reach for them:

- **Writing to `FileManager.temporaryDirectory`** — tests run in throwaway
  simulator clones ("Clone 1 of iPhone 17 Pro"), whose containers are discarded
  when the run ends.
- **`print`** — swallowed by the harness; it does not reach `xcodebuild` stdout.

## Non-determinism

`FullPipelineTests` drives a language model, so runtime and output vary between
runs of the same input. On its first honest run the suite caught a real
intermittent failure — `Exceeded model context window size` on an ordinary
30-line recipe ([AUDIT.md §2](AUDIT.md)) — which is exactly what it is for.

Practical consequences:

- Every pipeline test carries a `.timeLimit` trait; a hung model fails the test
  instead of hanging the run.
- Assertions check shape, not exact strings. Asserting an exact title would be
  flaky by construction.
- If a pipeline test fails once, re-run before assuming a regression, and read
  the attached log to see what the model actually returned.

## Test seams

Four `RecipeWebScraper` methods are `internal` rather than `private` purely so
`@testable import` can reach them for offline fixture tests. They are marked as
such in the source: `extractJSONLD`, `normalizeJSONLD`, `isoToMinutes`,
`stripHTML`.
