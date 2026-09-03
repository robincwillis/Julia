//
//  RecipeWebExtractor.swift
//  Julia
//

import Foundation
import Observation
import FoundationModels

// MARK: - Phase & Errors

enum WebScrapePhase: Equatable {
    case idle
    case browser    // URLSession fetch
    case parsing    // JSON-LD extraction
    case ai         // Foundation Models fallback
    case done
}

enum WebScrapeError: LocalizedError {
    case invalidURL
    case noRecipeFound
    case navigationFailed(String)
    case timeout
    case aiUnavailable
    case aiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:               return "That doesn't look like a valid URL."
        case .noRecipeFound:            return "No recipe was found on this page."
        case .navigationFailed(let m):  return "Page failed to load: \(m)"
        case .timeout:                  return "Page load timed out."
        case .aiUnavailable:            return "Apple Intelligence is unavailable. Enable it in Settings → Apple Intelligence & Siri."
        case .aiError(let m):           return "AI extraction failed: \(m)"
        }
    }
}

// MARK: - Foundation Models structured output

@Generable
struct ScrapedRecipeAI {
    @Guide(description: "The recipe name")
    var name: String
    @Guide(description: "A brief description of the dish")
    var description: String
    @Guide(description: "Prep time in minutes, 0 if unknown")
    var prepTimeMinutes: Int
    @Guide(description: "Cook time in minutes, 0 if unknown")
    var cookTimeMinutes: Int
    @Guide(description: "Total time in minutes, 0 if unknown")
    var totalTimeMinutes: Int
    @Guide(description: "Servings, e.g. '4 servings' or '8 cookies', empty string if unknown")
    var servings: String
    @Guide(description: "List of ingredient strings with quantities")
    var ingredients: [String]
    @Guide(description: "List of instruction steps")
    var instructions: [String]
}

// MARK: - Scraper

/// Fetches a page via URLSession, extracts JSON-LD structured data, and falls
/// back to Foundation Models if no schema is found. No WebKit required.
@MainActor
@Observable
final class RecipeWebScraper {

    private(set) var phase: WebScrapePhase = .idle
    private(set) var statusMessage: String = ""

    private var currentTask: Task<RecipeData, Error>?

    // MARK: Public API

    func scrape(urlString: String) async throws -> RecipeData {
        currentTask?.cancel()
        guard let url = normalizeURL(urlString) else { throw WebScrapeError.invalidURL }

        let task = Task<RecipeData, Error> { [weak self] in
            guard let self else { throw CancellationError() }
            return try await self.run(url: url)
        }
        currentTask = task
        return try await task.value
    }

    func cancel() {
        currentTask?.cancel()
        phase = .idle
        statusMessage = ""
    }

    // MARK: Pipeline

    private func run(url: URL) async throws -> RecipeData {
        // Stage 1: Fetch raw HTML
        phase = .browser
        statusMessage = "Fetching page..."
        let html = try await fetchHTML(url: url)

        // Stage 2: JSON-LD extraction from raw HTML
        phase = .parsing
        statusMessage = "Reading recipe schema..."
        if let recipeData = extractJSONLD(from: html, sourceURL: url.absoluteString) {
            phase = .done
            return recipeData
        }

        // Stage 3: Foundation Models fallback on stripped page text
        phase = .ai
        statusMessage = "Recovering recipe with AI..."
        let pageText = String(stripHTML(html).prefix(40000))
        guard !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WebScrapeError.noRecipeFound
        }
        let recipeData = try await scrapeWithAI(url: url.absoluteString, pageText: pageText)
        phase = .done
        return recipeData
    }

    // MARK: HTML Fetch

    private func fetchHTML(url: URL) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: 30)
        // Use a browser-like User-Agent so sites return their full HTML (including JSON-LD for SEO)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue(
            "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            forHTTPHeaderField: "Accept"
        )
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                throw WebScrapeError.navigationFailed("HTTP \(http.statusCode)")
            }
            // Try UTF-8 first, fall back to latin-1 for older sites
            return String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1)
                ?? ""
        } catch let error as WebScrapeError {
            throw error
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw WebScrapeError.timeout
        } catch {
            throw WebScrapeError.navigationFailed(error.localizedDescription)
        }
    }

    // MARK: JSON-LD Extraction

    private func extractJSONLD(from html: String, sourceURL: String) -> RecipeData? {
        // Match every <script type="application/ld+json"> block
        guard let regex = try? NSRegularExpression(
            pattern: #"<script[^>]+type\s*=\s*["']application/ld\+json["'][^>]*>([\s\S]*?)<\/script>"#,
            options: .caseInsensitive
        ) else { return nil }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            let jsonString = nsHTML.substring(with: match.range(at: 1))
            guard let data = jsonString.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data)
            else { continue }

            // Handle both single object and array at the top level
            if let dict = obj as? [String: Any],
               let rd = findRecipe(in: dict, sourceURL: sourceURL) {
                return rd
            }
            if let arr = obj as? [[String: Any]] {
                for dict in arr {
                    if let rd = findRecipe(in: dict, sourceURL: sourceURL) { return rd }
                }
            }
        }
        return nil
    }

    private func findRecipe(in dict: [String: Any], sourceURL: String) -> RecipeData? {
        let types = (dict["@type"] as? [String])
            ?? ((dict["@type"] as? String).map { [$0] } ?? [])
        if types.contains(where: { $0.lowercased().contains("recipe") }) {
            return normalizeJSONLD(dict, sourceURL: sourceURL)
        }
        // Walk @graph arrays (common on large food media sites)
        if let graph = dict["@graph"] as? [[String: Any]] {
            for item in graph {
                if let rd = findRecipe(in: item, sourceURL: sourceURL) { return rd }
            }
        }
        return nil
    }

    // MARK: HTML → Plain Text

    private func stripHTML(_ html: String) -> String {
        var text = html

        // Drop <script> and <style> blocks entirely
        let blockTags = try? NSRegularExpression(
            pattern: #"<(script|style|noscript)[^>]*>[\s\S]*?<\/\1>"#,
            options: .caseInsensitive
        )
        if let re = blockTags {
            text = re.stringByReplacingMatches(
                in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " "
            )
        }

        // Strip remaining tags
        if let tagRe = try? NSRegularExpression(pattern: "<[^>]+>") {
            text = tagRe.stringByReplacingMatches(
                in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " "
            )
        }

        // Decode common HTML entities
        text = text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        // Collapse whitespace
        if let wsRe = try? NSRegularExpression(pattern: #"\s{2,}"#) {
            text = wsRe.stringByReplacingMatches(
                in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " "
            )
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Normalization → RecipeData

    private func normalizeJSONLD(_ dict: [String: Any], sourceURL: String) -> RecipeData {
        var data = RecipeData()
        data.title = (dict["name"] as? String) ?? ""

        if let desc = dict["description"] as? String, !desc.isEmpty {
            data.summary = [desc]
        }

        data.ingredients = (dict["recipeIngredient"] as? [String] ?? [])
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        data.instructions = normalizeInstructions(dict["recipeInstructions"])

        if let mins = isoToMinutes(dict["prepTime"] as? String) {
            data.timings.append("prep: \(minutesToTimeString(mins))")
        }
        if let mins = isoToMinutes(dict["cookTime"] as? String) {
            data.timings.append("cook: \(minutesToTimeString(mins))")
        }
        if let mins = isoToMinutes(dict["totalTime"] as? String) {
            data.timings.append("total: \(minutesToTimeString(mins))")
        }

        if let servings = normalizeServings(dict["recipeYield"]) {
            data.servings = [servings]
        }

        if let author = dict["author"] as? [String: Any],
           let name = author["name"] as? String {
            data.author = name
        } else if let author = dict["author"] as? String {
            data.author = author
        } else if let authors = dict["author"] as? [[String: Any]],
                  let first = authors.first,
                  let name = first["name"] as? String {
            data.author = name
        }

        if let publisher = dict["publisher"] as? [String: Any],
           let name = publisher["name"] as? String {
            data.sourceTitle = name
        }

        data.source = sourceURL
        data.website = sourceURL
        data.sourceType = "website"
        data.rawText = buildRawText(from: data)
        return data
    }

    private func normalizeServings(_ value: Any?) -> String? {
        if let s = value as? String, !s.isEmpty { return s }
        if let n = value as? Int { return "\(n)" }
        if let a = value as? [Any] { return normalizeServings(a.first) }
        return nil
    }

    private func normalizeInstructions(_ value: Any?) -> [String] {
        if let str = value as? String { return [str] }
        if let arr = value as? [Any] {
            return arr.compactMap { item -> String? in
                if let s = item as? String { return s }
                if let d = item as? [String: Any] {
                    if let t = d["text"] as? String { return t }
                    if let sub = d["itemListElement"] {
                        return normalizeInstructions(sub).joined(separator: " ")
                    }
                }
                return nil
            }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }
        return []
    }

    // MARK: AI Fallback (Foundation Models)

    private func scrapeWithAI(url: String, pageText: String) async throws -> RecipeData {
        let service = FoundationModelsService.shared
        guard await service.isAvailable else { throw WebScrapeError.aiUnavailable }

        let prompt = """
            Extract the recipe from this web page content.

            URL: \(url)

            Page content:
            \(pageText)
            """

        let instructions = """
            You are a recipe extraction assistant. Extract recipe data from web page text. \
            Return only the recipe information found on the page. \
            For time fields, return the number of minutes as an integer (0 if not found). \
            DO NOT invent data that is not present in the page content.
            """

        do {
            let scraped = try await service.generate(
                prompt, type: ScrapedRecipeAI.self, instructions: instructions
            )

            var data = RecipeData()
            data.title = scraped.name
            if !scraped.description.isEmpty { data.summary = [scraped.description] }
            data.ingredients = scraped.ingredients
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            data.instructions = scraped.instructions
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            if scraped.prepTimeMinutes > 0 {
                data.timings.append("prep: \(minutesToTimeString(scraped.prepTimeMinutes))")
            }
            if scraped.cookTimeMinutes > 0 {
                data.timings.append("cook: \(minutesToTimeString(scraped.cookTimeMinutes))")
            }
            if scraped.totalTimeMinutes > 0 {
                data.timings.append("total: \(minutesToTimeString(scraped.totalTimeMinutes))")
            }
            if !scraped.servings.isEmpty { data.servings = [scraped.servings] }

            data.source = url
            data.website = url
            data.sourceType = "website"
            data.rawText = buildRawText(from: data)

            guard !data.title.isEmpty || !data.ingredients.isEmpty else {
                throw WebScrapeError.noRecipeFound
            }
            return data
        } catch is WebScrapeError {
            throw WebScrapeError.aiError("Foundation Models extraction failed")
        }
    }

    // MARK: Helpers

    private func buildRawText(from data: RecipeData) -> [String] {
        var raw: [String] = []
        raw.append("TITLE: \(data.title)")
        for s in data.summary { raw.append("SUMMARY: \(s)") }
        if !data.ingredients.isEmpty {
            raw.append("INGREDIENTS:")
            raw.append(contentsOf: data.ingredients)
        }
        if !data.instructions.isEmpty {
            raw.append("INSTRUCTIONS:")
            raw.append(contentsOf: data.instructions)
        }
        for t in data.timings { raw.append("TIMING: \(t)") }
        for s in data.servings { raw.append("SERVINGS: \(s)") }
        if let source = data.source { raw.append("SOURCE URL: \(source)") }
        return raw
    }

    private func normalizeURL(_ raw: String) -> URL? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.hasPrefix("http://") && !s.hasPrefix("https://") { s = "https://" + s }
        guard let url = URL(string: s),
              url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }

    /// Parses ISO 8601 durations (e.g. PT1H30M) → total minutes.
    private func isoToMinutes(_ iso: String?) -> Int? {
        guard let iso, iso.uppercased().hasPrefix("PT") else { return nil }
        var mins = 0, acc = ""
        for ch in iso.uppercased().dropFirst(2) {
            if ch.isNumber { acc.append(ch) }
            else if ch == "H" { mins += (Int(acc) ?? 0) * 60; acc = "" }
            else if ch == "M" { mins += Int(acc) ?? 0; acc = "" }
        }
        return mins > 0 ? mins : nil
    }

    private func minutesToTimeString(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h) hr \(m) min" }
        if h > 0 { return "\(h) hr" }
        return "\(m) min"
    }
}
