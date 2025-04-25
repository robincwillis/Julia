//
//  RecipeWebExtractor.swift
//  Julia
//
//  Created by Robin Willis on 3/11/25.
//

import Foundation
import SwiftSoup
import SwiftData

class RecipeWebExtractor {
  
  enum ExtractionError: Error {
    case networkError(Error)
    case invalidURL
    case parsingFailed(String)
    case noRecipeFound
  }
  
  // Main function that returns RecipeData
  func extractRecipe(from urlString: String) async throws -> RecipeData {
    guard let url = URL(string: urlString) else {
      throw ExtractionError.invalidURL
    }
    
    // Fetch HTML content
    let htmlContent = try await fetchHTML(from: url)
    
    // Parse the HTML
    return try parseRecipeFromHTML(htmlContent, sourceURL: urlString)
  }
  
  // Fetch HTML content from URL
  private func fetchHTML(from url: URL) async throws -> String {
    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      
      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        throw ExtractionError.parsingFailed("Invalid HTTP response")
      }
      
      guard let htmlString = String(data: data, encoding: .utf8) else {
        throw ExtractionError.parsingFailed("Unable to convert data to string")
      }
      
      return htmlString
    } catch {
      throw ExtractionError.networkError(error)
    }
  }
  
  // Parse recipe data from HTML
  private func parseRecipeFromHTML(_ html: String, sourceURL: String) throws -> RecipeData {
    do {
      let document = try SwiftSoup.parse(html)
      
      // First try to find structured data (JSON-LD)
      if let recipeData = try extractStructuredData(from: document, sourceURL: sourceURL) {
        return recipeData
      }
      
      // If no structured data, try to extract from HTML using common patterns
      return try extractFromHTMLPattern(document, sourceURL: sourceURL)
    } catch {
      throw ExtractionError.parsingFailed(error.localizedDescription)
    }
  }
  
  // Helper to extract ISO8601 duration strings
  private func extractTimeString(_ timeValue: Any?) -> String {
    if let timeString = timeValue as? String {
      // You could add ISO8601 duration parsing here if needed
      return timeString
    }
    return ""
  }
  
  // Extract recipe from JSON-LD structured data
  private func extractStructuredData(from document: Document, sourceURL: String) throws -> RecipeData? {
    let scriptElements = try document.select("script[type='application/ld+json']")
    
    for element in scriptElements {
      let jsonString = try element.html()
      
      if let jsonData = jsonString.data(using: .utf8),
         let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
        
        // Handle both direct Recipe and Graph with Recipe
        if let context = json["@context"] as? String,
           context.contains("schema.org") {
          
          // Direct Recipe object
          if let type = json["@type"] as? String,
             type == "Recipe" || type == "schema:Recipe" {
            return createExtractedDataFromJSON(json, sourceURL: sourceURL)
          }
          
          // Graph with Recipe object
          if let graph = json["@graph"] as? [[String: Any]] {
            for item in graph {
              if let type = item["@type"] as? String,
                 type == "Recipe" || type == "schema:Recipe" {
                return createExtractedDataFromJSON(item, sourceURL: sourceURL)
              }
            }
          }
        }
      }
    }
    
    return nil
  }
  
  // Create RecipeData from JSON-LD data
  private func createExtractedDataFromJSON(_ json: [String: Any], sourceURL: String) -> RecipeData {
    var recipeData = RecipeData()
    
    // Basic fields
    recipeData.title = json["name"] as? String ?? "Untitled Recipe"
    
    // Description/Summary
    if let description = json["description"] as? String, !description.isEmpty {
      recipeData.summary = [description]
    }
    
    // Ingredients
    if let jsonIngredients = json["recipeIngredient"] as? [String] {
      recipeData.ingredients = jsonIngredients
    } else if let ingredient = json["recipeIngredient"] as? String {
      recipeData.ingredients = [ingredient]
    }
    
    // Instructions
    if let jsonInstructions = json["recipeInstructions"] as? [String] {
      recipeData.instructions = jsonInstructions
    } else if let jsonInstructions = json["recipeInstructions"] as? [[String: Any]] {
      for step in jsonInstructions {
        if let text = step["text"] as? String {
          recipeData.instructions.append(text)
        }
      }
    } else if let instruction = json["recipeInstructions"] as? String {
      recipeData.instructions = [instruction]
    }
    
    // Time related fields
    let prepTime = extractTimeString(json["prepTime"])
    let cookTime = extractTimeString(json["cookTime"])
    let totalTime = extractTimeString(json["totalTime"])
    
    if !prepTime.isEmpty {
      recipeData.timings.append("prep: \(prepTime)")
    }
    
    if !cookTime.isEmpty {
      recipeData.timings.append("cook: \(cookTime)")
    }
    
    if !totalTime.isEmpty {
      recipeData.timings.append("total: \(totalTime)")
    }
    
    // Servings
    if let servings = json["recipeYield"] as? String, !servings.isEmpty {
      recipeData.servings = [servings]
    }
    
    // Source information
    recipeData.source = sourceURL
    recipeData.website = sourceURL
    
    if let author = json["author"] as? [String: Any], let authorName = author["name"] as? String {
      recipeData.author = authorName
    } else if let author = json["author"] as? String {
      recipeData.author = author
    }
    
    // Source type
    recipeData.sourceType = "website"
    
    // Add source title (could be publication name)
    if let publisher = json["publisher"] as? [String: Any], let publisherName = publisher["name"] as? String {
      recipeData.sourceTitle = publisherName
    }
    
    // Collect raw text for safe keeping
    var rawText: [String] = []
    rawText.append("TITLE: \(recipeData.title)")
    for summary in recipeData.summary {
      rawText.append("SUMMARY: \(summary)")
    }
    rawText.append("INGREDIENTS:")
    rawText.append(contentsOf: recipeData.ingredients)
    rawText.append("INSTRUCTIONS:")
    rawText.append(contentsOf: recipeData.instructions)
    for timing in recipeData.timings {
      rawText.append("TIMING: \(timing)")
    }
    for serving in recipeData.servings {
      rawText.append("SERVINGS: \(serving)")
    }
    rawText.append("SOURCE URL: \(sourceURL)")
    
    recipeData.rawText = rawText
    
    return recipeData
  }
  
  // Extract recipe from HTML patterns when structured data isn't available
  private func extractFromHTMLPattern(_ document: Document, sourceURL: String) throws -> RecipeData {
    var recipeData = RecipeData()
    
    // Title extraction strategies
    var title = try document.select("h1").first()?.text() ?? ""
    if title.isEmpty {
      title = try document.select("meta[property='og:title']").attr("content")
    }
    if title.isEmpty {
      title = try document.title()
    }
    recipeData.title = title
    
    // Ingredients extraction strategies
    var ingredients: [String] = []
    
    // Common ingredient containers
    let ingredientSelectors = [
      "ul.ingredients li",
      "div.ingredients li",
      ".recipe-ingredients li",
      "[itemprop='recipeIngredient']",
      ".ingredient-list li"
    ]
    
    for selector in ingredientSelectors {
      let elements = try document.select(selector)
      if !elements.isEmpty() {
        for element in elements {
          let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
          if !text.isEmpty {
            ingredients.append(text)
          }
        }
        if !ingredients.isEmpty {
          break
        }
      }
    }
    
    // Instructions extraction strategies
    var instructions: [String] = []
    
    // Common instruction containers
    let instructionSelectors = [
      "ol.instructions li",
      "div.instructions li",
      ".recipe-directions li",
      "[itemprop='recipeInstructions']",
      ".preparation-steps li",
      ".recipe-method li"
    ]
    
    for selector in instructionSelectors {
      let elements = try document.select(selector)
      if !elements.isEmpty() {
        for element in elements {
          let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
          if !text.isEmpty {
            instructions.append(text)
          }
        }
        if !instructions.isEmpty {
          break
        }
      }
    }
    
    // If we couldn't extract structured ingredients/instructions, fall back to smart text extraction
    if ingredients.isEmpty || instructions.isEmpty {
      let textBlocks = try smartTextExtraction(document)
      
      if ingredients.isEmpty {
        ingredients = identifyIngredients(from: textBlocks)
      }
      
      if instructions.isEmpty {
        instructions = identifyInstructions(from: textBlocks)
      }
    }
    
    // If still no success, throw error
    if ingredients.isEmpty && instructions.isEmpty {
      throw ExtractionError.noRecipeFound
    }
    
    recipeData.ingredients = ingredients
    recipeData.instructions = instructions
    
    // Description extraction
    let description = try document.select("meta[name='description']").attr("content")
    if !description.isEmpty {
      recipeData.summary = [description]
    }
    
    // Try to extract servings
    let servingsSelectors = ["[itemprop='recipeYield']", ".recipe-yield", ".recipe-servings"]
    for selector in servingsSelectors {
      if let element = try document.select(selector).first() {
        let servings = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
        if !servings.isEmpty {
          recipeData.servings = [servings]
          break
        }
      }
    }
    
    // Source information
    recipeData.source = sourceURL
    recipeData.website = sourceURL
    recipeData.sourceType = "website"
    
    // Try to extract author
    let authorSelectors = ["[itemprop='author']", ".recipe-author", ".byline"]
    for selector in authorSelectors {
      if let element = try document.select(selector).first() {
        let author = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
        if !author.isEmpty {
          recipeData.author = author
          break
        }
      }
    }
    
    // Try to extract website/publication name
    if let siteName = try document.select("meta[property='og:site_name']").first()?.attr("content") {
      recipeData.sourceTitle = siteName
    }
    
    // Collect raw text for classification
    var rawText: [String] = []
    rawText.append("TITLE: \(recipeData.title)")
    for summary in recipeData.summary {
      rawText.append("DESCRIPTION: \(summary)")
    }
    rawText.append("INGREDIENTS:")
    rawText.append(contentsOf: recipeData.ingredients)
    rawText.append("INSTRUCTIONS:")
    rawText.append(contentsOf: recipeData.instructions)
    for timing in recipeData.timings {
      rawText.append("TIMING: \(timing)")
    }
    for serving in recipeData.servings {
      rawText.append("SERVINGS: \(serving)")
    }
    rawText.append("SOURCE URL: \(sourceURL)")
    
    recipeData.rawText = rawText
    
    return recipeData
  }
  
  // Smart text extraction for unstructured content
  private func smartTextExtraction(_ document: Document) throws -> [String] {
    // Remove unhelpful elements
    try document.select("header, footer, nav, aside, .sidebar, .comments, script, style").remove()
    
    // Get main content areas
    let mainContent = try document.select("main, article, .content, .post, .recipe, .entry, .post-content").first() ?? document
    
    // Extract text blocks from paragraphs, list items, divs with text
    var textBlocks: [String] = []
    
    for element in try mainContent.select("p, li, div:not(:has(*))") {
      let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
      if !text.isEmpty && text.count > 10 {
        textBlocks.append(text)
      }
    }
    
    return textBlocks
  }
  
  // Identify ingredients from text blocks using natural language patterns
  private func identifyIngredients(from textBlocks: [String]) -> [String] {
    var ingredients: [String] = []
    
    // Patterns that suggest ingredients
    let patterns: [NSRegularExpression] = [
      try! NSRegularExpression(pattern: "\\d+\\s*(cup|tablespoon|teaspoon|tbsp|tsp|oz|ounce|pound|lb|g|kg)s?\\b", options: .caseInsensitive),
      try! NSRegularExpression(pattern: "\\b(salt|pepper|oil|butter|sugar|flour)\\b", options: .caseInsensitive)
    ]
    
    for block in textBlocks {
      var isIngredient = false
      
      // Check if this block matches ingredient patterns
      for pattern in patterns {
        let matches = pattern.matches(in: block, options: [], range: NSRange(location: 0, length: block.utf16.count))
        if !matches.isEmpty {
          isIngredient = true
          break
        }
      }
      
      // Check for bullet points or dashes which often indicate ingredients
      if block.hasPrefix("•") || block.hasPrefix("-") || block.hasPrefix("*") {
        isIngredient = true
      }
      
      if isIngredient && block.count < 200 { // Ingredients are usually short
        ingredients.append(block)
      }
    }
    
    return ingredients
  }
  
  // Identify instructions from text blocks
  private func identifyInstructions(from textBlocks: [String]) -> [String] {
    var instructions: [String] = []
    
    // Look for numbered steps or cooking verbs
    let stepPattern = try! NSRegularExpression(pattern: "^\\s*\\d+\\.?\\s+", options: .caseInsensitive)
    let verbPattern = try! NSRegularExpression(pattern: "\\b(mix|stir|add|place|bake|cook|heat|pour|beat|whisk|combine)\\b", options: .caseInsensitive)
    
    for block in textBlocks {
      var isInstruction = false
      
      // Check for numbered steps
      let stepMatches = stepPattern.matches(in: block, options: [], range: NSRange(location: 0, length: block.utf16.count))
      if !stepMatches.isEmpty {
        isInstruction = true
      }
      
      // Check for cooking verbs
      let verbMatches = verbPattern.matches(in: block, options: [], range: NSRange(location: 0, length: block.utf16.count))
      if !verbMatches.isEmpty {
        isInstruction = true
      }
      
      if isInstruction && block.count > 20 { // Instructions are usually longer
        instructions.append(block)
      }
    }
    
    return instructions
  }
}

// Example usage in your app:
func importRecipeFromURL(_ urlString: String) async -> RecipeData? {
  let extractor = RecipeWebExtractor()
  
  do {
    // Extract the recipe data
    let recipeData = try await extractor.extractRecipe(from: urlString)
    return recipeData
    
  } catch let error as RecipeWebExtractor.ExtractionError {
    switch error {
    case .invalidURL:
      print("Error: The URL provided is invalid")
    case .networkError(let underlyingError):
      print("Network error: \(underlyingError.localizedDescription)")
    case .parsingFailed(let reason):
      print("Parsing failed: \(reason)")
    case .noRecipeFound:
      print("No recipe could be found on this page")
    }
    return nil
  } catch {
    print("Unexpected error: \(error.localizedDescription)")
    return nil
  }
}
