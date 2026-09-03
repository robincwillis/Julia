# Test fixtures

Drop a file in one of these folders and it becomes a test case. No Xcode work,
no code edit: `JuliaTests` is a synchronized folder group, so Xcode adds new
files to the target automatically, and `TestAssets` discovers them by extension
at runtime.

| Folder    | Extensions              | What it exercises                                  |
|-----------|-------------------------|----------------------------------------------------|
| `Images/` | `.jpg .jpeg .png .heic` | Vision OCR, then the full pipeline                 |
| `Text/`   | `.txt`                  | Reconstruction, then the full pipeline             |
| `Web/`    | `.html .htm`            | JSON-LD extraction and normalization (no network)  |

## Naming

Resources are flattened into the test bundle, so **names must be unique across
all three folders**. Use descriptive slugs: `onion_soup.jpg`,
`messy_ocr_recipe.txt`, `nyt_cooking_graph.html`.

## Images

Photograph or screenshot a recipe and save it into `Images/`. Two suites pick
it up:

- `Vision OCR (offline)` asserts OCR returns text — runs anywhere.
- `Full import pipeline` runs classification — skipped without Apple
  Intelligence.

The repo ships no binary photos, so the image suites no-op until you add some.
`synthenticImageRoundTrip` still covers OCR everywhere by rendering text into an
image at runtime.

## Text

Plain text as a user would paste it — messy OCR dumps and blog preambles are
more valuable than clean input, since that is what the reconstructor exists to
handle.

## Web

Save a real recipe page:

```
curl -sL 'https://example.com/some-recipe' -o JuliaTests/Fixtures/Web/example_recipe.html
```

`allFixturesParse` then asserts a recipe with a title, ingredients and
instructions comes out. Add a named test in `WebScraperTests` when you want to
pin specific field values.

Pages whose recipe data is rendered client-side have no JSON-LD and will fail
`allFixturesParse` — that path needs the Apple Intelligence fallback, so keep
those out of `Web/`.

## Running

```
xcodebuild -project Julia.xcodeproj -scheme Julia \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Detailed per-asset dumps (OCR lines, classified fields) are written to
`/tmp/JuliaTests/<suite>_<timestamp>.log` as well as the Xcode test report.

## Apple Intelligence

Classification and AI ingredient parsing route through Foundation Models. When
it is unavailable — the norm on simulators — those suites **skip** rather than
fail, and the reason is printed at the top of each log. Everything else runs.
