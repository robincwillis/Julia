# parsely-swiftui — spike, not in the build

**Status: superseded. This code is not part of the Julia app and is not
compiled by anything.**

A standalone SwiftPM package exploring recipe scraping — `RecipeScraper` plus a
small set of views. It is referenced **nowhere** in `Julia.xcodeproj`: no file
reference, no target membership, no package dependency. Nothing here runs.

## What replaced it

The shipping scraper is `RecipeWebScraper` in
`Julia/Utilities/RecipeWebExtractor.swift`. It takes the same approach — fetch
the page, prefer JSON-LD structured data, fall back to Foundation Models over
the page text — and is the one wired into the import pipeline and covered by
`JuliaTests/WebScraperTests.swift`.

## Why it is still here

Kept deliberately rather than deleted, in case anything in the scraping or view
code is worth lifting later. Recoverable from git history either way.

**Do not treat this directory as live code.** If you are changing how recipe
URLs are scraped, the file you want is `RecipeWebExtractor.swift`.

See `docs/AUDIT.md` §7.
