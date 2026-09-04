# Foundation Models context window overflow

**Component** `Julia/Utilities/FoundationModelsRecipeClassifier.swift`
**Symptom** Recipe import fails with `Exceeded model context window size`
**Severity** High — intermittent hard failure of the primary import path
**Status** Mitigated 2026-09-03; structurally fixed 2026-09-04, see [Structural fix](#structural-fix-2026-09-04).
**Found by** `FullPipelineTests/textImport()` on its first run with assertions enabled

---

## Symptom

Importing an ordinary 22-line recipe failed:

```
RecipeProcessingTests.swift:235: Caught error:
Pipeline reported: Exceeded model context window size
```

The tell was the timing. The same fixture, same simulator, minutes apart:

| Run | Result | Duration |
|-----|--------|----------|
| 1 | passed | 18.0s |
| 2 | **failed** | 107.9s |
| 3 | passed | 24.6s |

A 6× duration on the failing run says the model kept generating until it ran
out of window, rather than hitting a hard input-size limit. That distinction
matters, and it is why there are two separate causes below.

## Background: what consumes the budget

`SystemLanguageModel.default` has a context window of roughly **4,096 tokens**,
and that budget covers the prompt *and the generated response together*.

The classifier asks for a `@Generable ClassifiedRecipe` — a struct of ten
string arrays. Every input line must appear in exactly one array, so **the
output restates the entire input**, plus JSON scaffolding (keys, quotes,
brackets, commas). Output is therefore not a small fraction of input; it is
larger than it.

Measured overhead per call (`chars / 4` as the token estimate):

| Component | Tokens |
|---|---|
| `instructions` (the classification prompt) | ~579 |
| Per-call prompt wrapper | ~43 |
| **Fixed overhead** | **~622** |

A recipe line in our fixture averages 36.6 characters, plus the `"12. "`
numbering prefix the classifier adds — about **12 tokens per line**.

## Cause 1: `chunkSize` was above the point where a chunk can fit

`chunkSize` was **150 lines**, described in the source as "conservative to stay
under the ~4000 token budget". Working it through:

| `chunkSize` | Input | Output (~1.3×) | + fixed | Total | % of 4,096 |
|---|---|---|---|---|---|
| **150** | ~1,822 | ~2,369 | 622 | **~4,813** | **117%** |
| 40 | ~486 | ~632 | 622 | ~1,740 | 42% |
| 5 | ~61 | ~79 | 622 | ~762 | 19% |

A *full* 150-line chunk could not fit. It was not a tight budget — it was over
the limit before the model generated a single token.

So the chunking provided no protection whatsoever. It appeared to work only
because `makeChunks` returns a single chunk for anything under 150 lines, and
most recipes are well under that. The guard rail was set beyond the cliff.

## Cause 2: the model over-generates regardless of size

Our failing fixture was 22 lines — about **1,234 tokens, 30% of budget**. It
should have been nowhere near the limit, and twice it wasn't.

Structured generation output length is not predictable. On OCR-ish or ambiguous
text the model can repeat itself, re-emit lines, or pad arrays, and keep going
until the window is gone. The 108s runtime is that happening.

This is the more important of the two causes, because it means **no static
chunk size makes the failure impossible**. Sizing changes the probability, not
the outcome.

## Fix

Two changes, one per cause.

**1. A chunk size with real headroom** — 150 → 40, ~42% of budget:

```swift
/// The ~4096 token budget covers the instructions (~900 tokens), the input
/// lines, AND the structured output — which echoes every input line back
/// into one of the arrays. So a chunk costs roughly twice its own token
/// count on top of the fixed prompt, and 150 lines routinely overflowed.
private let chunkSize = 40
private let minimumChunkSize = 5
```

**2. Halve-and-retry on overflow** — treat overflow as a sizing hint rather
than a fatal error:

```swift
private func classifyChunkSplittingOnOverflow(_ lines: [String]) async throws -> ClassifiedRecipe {
    do {
        return try await classifyChunk(lines)
    } catch let error as LanguageModelSession.GenerationError {
        guard case .exceededContextWindowSize = error,
              lines.count > minimumChunkSize else { throw error }

        let middle = lines.count / 2
        let first  = try await classifyChunkSplittingOnOverflow(Array(lines[..<middle]))
        let second = try await classifyChunkSplittingOnOverflow(Array(lines[middle...]))
        return mergeResults(first, second)
    }
}
```

Recursive, so a chunk that overflows twice keeps halving down to the 5-line
floor. Below that, overflow is not a sizing problem and the error propagates
rather than being retried forever.

Note the comment in the shipped code says ~900 tokens for the instructions;
the measured figure is ~579. The argument is unchanged but the number is wrong
— worth correcting next time that file is touched.

## Residual risk

**Splitting is a heuristic, not a guarantee.** It rests on the assumption that
a smaller input makes the model ramble less. Usually true, not always. A single
pathological line under the 5-line floor will still fail the import.

**Smaller chunks fragment context.** This is the real cost of the fix, and it
is a correctness trade-off rather than a free win. Each chunk is classified
with no knowledge of the others, so with `chunkSize = 40` a recipe that
previously went in one call may now be split — and:

- `mergeResults` keeps the **first non-empty title**, so a chunk boundary
  falling before the real title means a later chunk's guess wins.
- A mid-recipe chunk has no preamble. Its opening lines can be misread as a
  title or summary because nothing establishes that instructions are already
  under way.
- Section headings lose the ingredient list they belong to.

Recipes under 40 lines — most of them — are unaffected, since they are still a
single chunk.

**Latency multiplies on retry.** Each split doubles the number of calls for
that subtree. A chunk that halves twice costs up to 7 model round trips
instead of 1.

**No pre-flight check.** Nothing estimates token cost before calling. The
overflow is discovered by attempting it, which is why the first failure is
always slow.

## Detecting a recurrence

`FullPipelineTests` is the tripwire, but it is probabilistic — a single green
run does not prove much. When investigating a suspected recurrence:

1. Check the duration. A pipeline test taking 5–10× its usual time is
   over-generating, whether or not it failed.
2. Read the attached `pipeline-*.log` in the test report for what the model
   actually returned — padded or repeated arrays are the signature.
3. `Exceeded model context window size` surfaces to users through
   `RecipeProcessor.handleError` as a raw `localizedDescription`. It is worth
   mapping to something actionable, since a user cannot do anything about a
   token budget.

## Structural fix (2026-09-04)

Option 3 from the list below was implemented, which removes the mechanism rather
than reducing its probability.

`ClassifiedRecipe`'s ten string arrays are gone. The model now returns
`ClassifiedLines` — `{lineNumber, category}` per line, where `category` is a
`@Generable` enum. **The response no longer contains the input text at all**, so
the "output restates the input" property that drove this bug is eliminated:

| | before | after |
|---|---|---|
| instructions | ~579 tokens | **~181 tokens** |
| 22-line chunk, total | ~1,229 (30% of budget) | **~641 (15%)** |
| 40-line chunk, total | ~1,726 (42%) | **~1,001 (24%)** |
| `allTextFixtures` runtime | 16.1s | **8.9s** |

The instructions shrank because the ten-category glossary moved into `@Guide`
descriptions on `LineCategory`, which the framework already sends as part of the
schema, and the OCR-correction section became meaningless once no text comes
back.

### The new failure mode, and how it is handled

Returning no text introduces a risk the old shape did not have: a line number
the model **omits** would silently drop an ingredient, and one it **invents**
would index the wrong line.

`buildResult` walks the *input* in document order and looks up each line's
category, rather than walking the model's response:

- a line the model never returned is still present, categorised `.unknown`
- line numbers outside the chunk are discarded rather than trusted
- a dictionary keyed by absolute index means duplicate numbers cannot append the
  same line twice
- document order is inherent, so the sort this doc previously called for is
  unnecessary

Omitted lines are also recorded with confidence **0.3** against 1.0 for
classified ones, which gives the review sheet's "skipped only" filter a real
signal for the first time (see [../AUDIT.md](../AUDIT.md) §6).

### What this does not fix

`chunkSize` stays at 40 rather than rising with the extra headroom: chunking
also bounds the blast radius of one bad generation. The context-fragmentation
cost described under [Residual risk](#residual-risk) is therefore unchanged —
chunk boundaries still cut through sections, and that is what the section-based
classification idea in [../TODO.md](../TODO.md) addresses.

Overflow is now unlikely rather than impossible: the model can still
over-generate, so the halve-and-retry path remains.

## Better fixes, if this recurs

Ordered by effort:

1. **Estimate before calling.** `chars/4` is crude but enough to split
   proactively instead of discovering overflow after 100s.
2. **Shrink the instructions.** ~579 tokens of fixed overhead is 14% of the
   window spent on every call, including retries. The prompt has ten labelled
   categories with examples; much of it could move into `@Guide` descriptions
   on `ClassifiedRecipe`, which the framework already sends as schema.
3. ~~**Stop echoing the input.**~~ **Done 2026-09-04 — see above.** The expensive property is that output restates
   input. Asking for `[lineNumber: category]` instead of ten arrays of full
   strings would cut output to a few tokens per line and roughly halve total
   cost. This is the structural fix — it makes the failure mode go away rather
   than making it rarer, at the cost of reworking `ClassifiedRecipe` and
   `toClassificationResult`.
4. **Overlap chunk boundaries.** A few lines of overlap plus dropping
   duplicates on merge would address the context fragmentation above.

## Related

- [`ingredient-quantity-parsing.md`](ingredient-quantity-parsing.md) — the other bug found in the same pass
- [`../AUDIT.md`](../AUDIT.md) §1 — there is no fallback when Apple Intelligence is unavailable, so a classifier failure has nothing to fall back to
- [`../TODO.md`](../TODO.md)
