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
  
  // Main function that returns your SwiftData Recipe model
  func extractRecipe(from urlString: String) async throws -> Recipe {
    guard let url = URL(string: urlString) else {
      throw ExtractionError.invalidURL
    }
    
    // Fetch HTML content
    let htmlContent = try await fetchHTML(from: url)
    
    // Parse the HTML
    let extractedData = try parseRecipeFromHTML(htmlContent, sourceURL: urlString)
    
    // Convert to your SwiftData Recipe model
    return convertToSwiftDataModel(extractedData)
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
  
  // Intermediate data structure to hold extracted recipe data
  private struct ExtractedRecipeData {
    let title: String
    let ingredients: [String]
    let instructions: [String]
    let description: String
    let prepTime: String
    let cookTime: String
    let totalTime: String
    let servings: String
    let sourceURL: String
    let rawText: [String]
  }
  
  // Parse recipe data from HTML
  private func parseRecipeFromHTML(_ html: String, sourceURL: String) throws -> ExtractedRecipeData {
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
  
  // Extract recipe from JSON-LD structured data
  private func extractStructuredData(from document: Document, sourceURL: String) throws -> ExtractedRecipeData? {
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
  
  // Create ExtractedRecipeData from JSON-LD data
  private func createExtractedDataFromJSON(_ json: [String: Any], sourceURL: String) -> ExtractedRecipeData {
    let title = json["name"] as? String ?? "Untitled Recipe"
    
    var ingredients: [String] = []
    if let jsonIngredients = json["recipeIngredient"] as? [String] {
      ingredients = jsonIngredients
    } else if let ingredient = json["recipeIngredient"] as? String {
      ingredients = [ingredient]
    }
    
    var instructions: [String] = []
    if let jsonInstructions = json["recipeInstructions"] as? [String] {
      instructions = jsonInstructions
    } else if let jsonInstructions = json["recipeInstructions"] as? [[String: Any]] {
      for step in jsonInstructions {
        if let text = step["text"] as? String {
          instructions.append(text)
        }
      }
    } else if let instruction = json["recipeInstructions"] as? String {
      instructions = [instruction]
    }
    
    let description = json["description"] as? String ?? ""
    let prepTime = extractTimeString(json["prepTime"])
    let cookTime = extractTimeString(json["cookTime"])
    let totalTime = extractTimeString(json["totalTime"])
    let servings = json["recipeYield"] as? String ?? ""
    
    // Collect raw text for your classifier
    var rawText: [String] = []
    rawText.append("TITLE: \(title)")
    if !description.isEmpty { rawText.append("DESCRIPTION: \(description)") }
    rawText.append("INGREDIENTS:")
    rawText.append(contentsOf: ingredients)
    rawText.append("INSTRUCTIONS:")
    rawText.append(contentsOf: instructions)
    if !prepTime.isEmpty { rawText.append("PREP TIME: \(prepTime)") }
    if !cookTime.isEmpty { rawText.append("COOK TIME: \(cookTime)") }
    if !totalTime.isEmpty { rawText.append("TOTAL TIME: \(totalTime)") }
    if !servings.isEmpty { rawText.append("SERVINGS: \(servings)") }
    rawText.append("SOURCE URL: \(sourceURL)")
    
    return ExtractedRecipeData(
      title: title,
      ingredients: ingredients,
      instructions: instructions,
      description: description,
      prepTime: prepTime,
      cookTime: cookTime,
      totalTime: totalTime,
      servings: servings,
      sourceURL: sourceURL,
      rawText: rawText
    )
  }
  
  // Helper to extract ISO8601 duration strings
  private func extractTimeString(_ timeValue: Any?) -> String {
    if let timeString = timeValue as? String {
      // You could add ISO8601 duration parsing here if needed
      return timeString
    }
    return ""
  }
  
  // Extract recipe from HTML patterns when structured data isn't available
  private func extractFromHTMLPattern(_ document: Document, sourceURL: String) throws -> ExtractedRecipeData {
    // Title extraction strategies
    var title = try document.select("h1").first()?.text() ?? ""
    if title.isEmpty {
      title = try document.select("meta[property='og:title']").attr("content")
    }
    if title.isEmpty {
      title = try document.title()
    }
    
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
    
    // Description extraction
    let description = try document.select("meta[name='description']").attr("content")
    
    // TODO Attempt to extract other metadata
    let prepTime = ""
    let cookTime = ""
    let totalTime = ""
    var servings = ""
    
    // Try to extract servings
    let servingsSelectors = ["[itemprop='recipeYield']", ".recipe-yield", ".recipe-servings"]
    for selector in servingsSelectors {
      if let element = try document.select(selector).first() {
        servings = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
        if !servings.isEmpty {
          break
        }
      }
    }
    
    // Collect raw text
    var rawText: [String] = []
    rawText.append("TITLE: \(title)")
    if !description.isEmpty { rawText.append("DESCRIPTION: \(description)") }
    rawText.append("INGREDIENTS:")
    rawText.append(contentsOf: ingredients)
    rawText.append("INSTRUCTIONS:")
    rawText.append(contentsOf: instructions)
    if !prepTime.isEmpty { rawText.append("PREP TIME: \(prepTime)") }
    if !cookTime.isEmpty { rawText.append("COOK TIME: \(cookTime)") }
    if !totalTime.isEmpty { rawText.append("TOTAL TIME: \(totalTime)") }
    if !servings.isEmpty { rawText.append("SERVINGS: \(servings)") }
    rawText.append("SOURCE URL: \(sourceURL)")
    
    return ExtractedRecipeData(
      title: title,
      ingredients: ingredients,
      instructions: instructions,
      description: description,
      prepTime: prepTime,
      cookTime: cookTime,
      totalTime: totalTime,
      servings: servings,
      sourceURL: sourceURL,
      rawText: rawText
    )
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
  
  // Convert extracted data to your SwiftData Recipe model
  private func convertToSwiftDataModel(_ extractedData: ExtractedRecipeData) -> Recipe {

    
    // Create basic Recipe object first (without the time)
    let recipe = Recipe(
      id: UUID().uuidString,
      title: extractedData.title,
      summary: extractedData.description.isEmpty ? nil : extractedData.description,
      ingredients: [], // Will populate below
      instructions: extractedData.instructions,
      sections: [],
      servings: extractedData.servings.isEmpty ? nil : Int(extractedData.servings.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()),
      timings: [],
      rawText: extractedData.rawText
    )
    
    // After creating the recipe, create and set the Timings if available
    if !extractedData.totalTime.isEmpty {
      // Parse time string to extract hours and minutes
      let (hours, minutes) = parseTimeString(extractedData.totalTime)
      let totalTime = Timing(type: "total", hours: hours, minutes: minutes)
      recipe.timings?.append(totalTime)
    } else if !extractedData.cookTime.isEmpty {
      // If no total time but cook time is available
      let (hours, minutes) = parseTimeString(extractedData.cookTime)
      let cookTime = Timing(type: "cook", hours: hours, minutes: minutes)
      recipe.timings?.append(cookTime)
    } else if !extractedData.prepTime.isEmpty {
      // If only prep time is available
      let (hours, minutes) = parseTimeString(extractedData.prepTime)
      let prepTime = Timing(type: "prep", hours: hours, minutes: minutes)
      recipe.timings?.append(prepTime)
    }
    
    // Create Ingredient objects for each ingredient string
    for ingredientText in extractedData.ingredients {
      // Parse the ingredient text to extract quantity, unit, and name
      let (quantity, unit, name, comment) = parseIngredientText(ingredientText)
      
      let ingredient = Ingredient(
        name: name,
        location: .recipe,
        quantity: quantity,
        unit: unit,
        comment: comment,
        recipe: recipe
      )
      
      recipe.ingredients.append(ingredient)
    }
    
    var timeInfo = ""
    if !extractedData.prepTime.isEmpty {
      timeInfo += "Prep Time: \(extractedData.prepTime)\n"
    }
    if !extractedData.cookTime.isEmpty {
      timeInfo += "Cook Time: \(extractedData.cookTime)\n"
    }
    if !extractedData.totalTime.isEmpty {
      timeInfo += "Total Time: \(extractedData.totalTime)"
    }
    
    if !timeInfo.isEmpty {
      if recipe.summary != nil {
        recipe.summary = recipe.summary! + "\n\n" + timeInfo
      } else {
        recipe.summary = timeInfo
      }
    }
    
    return recipe
  }
  
  // Helper method to parse time strings like "1 hour 15 minutes" or "45 min"
  private func parseTimeString(_ timeString: String) -> (Int, Int) {
    var hours = 0
    var minutes = 0
    
    // Look for hours
    let hourPattern = try! NSRegularExpression(pattern: "(\\d+)\\s*h(our)?s?", options: .caseInsensitive)
    let hourMatches = hourPattern.matches(in: timeString, options: [], range: NSRange(location: 0, length: timeString.utf16.count))
    
    if let match = hourMatches.first, let range = Range(match.range(at: 1), in: timeString) {
      hours = Int(timeString[range]) ?? 0
    }
    
    // Look for minutes
    let minutePattern = try! NSRegularExpression(pattern: "(\\d+)\\s*m(in(ute)?s?)?", options: .caseInsensitive)
    let minuteMatches = minutePattern.matches(in: timeString, options: [], range: NSRange(location: 0, length: timeString.utf16.count))
    
    if let match = minuteMatches.first, let range = Range(match.range(at: 1), in: timeString) {
      minutes = Int(timeString[range]) ?? 0
    }
    
    // If no specific pattern found but it's just a number, assume minutes
    if hours == 0 && minutes == 0 {
      let numberPattern = try! NSRegularExpression(pattern: "(\\d+)", options: [])
      let numberMatches = numberPattern.matches(in: timeString, options: [], range: NSRange(location: 0, length: timeString.utf16.count))
      
      if let match = numberMatches.first, let range = Range(match.range(at: 1), in: timeString) {
        minutes = Int(timeString[range]) ?? 0
      }
    }
    
    return (hours, minutes)
  }
  
  // Helper method to parse ingredient text into components
  private func parseIngredientText(_ text: String) -> (Double?, String?, String, String?) {
    let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Common patterns for ingredients:
    // "2 cups flour"
    // "1/2 teaspoon salt"
    // "3 large eggs, beaten"
    
    // Try to extract quantity (number)
    var quantity: Double? = nil
    var unit: String? = nil
    var name = normalizedText
    var comment: String? = nil
    
    // Look for fractions and decimals at the beginning
    let quantityPattern = try! NSRegularExpression(pattern: "^(\\d+[\\s]?[\\d\\/\\.]+|\\d+)", options: [])
    let quantityMatches = quantityPattern.matches(in: normalizedText, options: [], range: NSRange(location: 0, length: normalizedText.utf16.count))
    
    if let match = quantityMatches.first, let range = Range(match.range, in: normalizedText) {
      let quantityStr = String(normalizedText[range])
      name = normalizedText.replacingCharacters(in: range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
      
      // Convert fraction strings to decimal
      if quantityStr.contains("/") {
        let components = quantityStr.components(separatedBy: "/")
        if components.count == 2,
            let numerator = Double(components[0].trimmingCharacters(in: .whitespacesAndNewlines)),
           let denominator = Double(components[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
          quantity = numerator / denominator
        }
      } else if let doubleValue = Double(quantityStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
        quantity = doubleValue
      }
    }
    
    // Look for common units after the quantity
    let unitPattern = try! NSRegularExpression(pattern: "^\\s*(cup|tablespoon|teaspoon|tbsp|tsp|oz|ounce|pound|lb|g|kg|ml|l)s?\\b", options: .caseInsensitive)
    let unitMatches = unitPattern.matches(in: name, options: [], range: NSRange(location: 0, length: name.utf16.count))
    
    if let match = unitMatches.first, let range = Range(match.range, in: name) {
      unit = String(name[range]).trimmingCharacters(in: .whitespacesAndNewlines)
      name = name.replacingCharacters(in: range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Look for comments (often after a comma)
    if name.contains(",") {
      let parts = name.split(separator: ",", maxSplits: 1)
      if parts.count == 2 {
        name = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        comment = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
      }
    }
    
    // If name is empty after all parsing, use the original text
    if name.isEmpty {
      name = normalizedText
    }
    
    return (quantity, unit, name, comment)
  }
}

// Example usage in your app:
func importRecipeFromURL(_ urlString: String) async -> Recipe? {
  let extractor = RecipeWebExtractor()
  
  do {
    // Extract the recipe
    let recipe = try await extractor.extractRecipe(from: urlString)
    
    // Here you could run your classifier on recipe.rawText
    // let classification = myRecipeClassifier.classify(recipe.rawText)
    
    return recipe
    
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
