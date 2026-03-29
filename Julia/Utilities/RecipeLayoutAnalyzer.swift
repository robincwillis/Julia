//
//  RecipeLayoutAnalyzer.swift
//  Julia
//
//  Created by Robin Willis on 5/10/25.
//

import Vision
import UIKit
import NaturalLanguage

// Error types for recipe processing
enum RecipeProcessingError: Error {
    case invalidImage
    case noTextFound
    case layoutAnalysisFailed
    case titleDetectionFailed
    case boundaryDetectionFailed
}

class RecipeLayoutAnalyzer {
    
    struct TextBlock {
        let text: String
        let boundingBox: CGRect
        let confidence: Float
    }
    
    struct TextGroup {
        var blocks: [TextBlock]
        var boundingBox: CGRect
        
        // Update the bounding box when blocks are added
        mutating func addBlock(_ block: TextBlock) {
            blocks.append(block)
            boundingBox = boundingBox.union(block.boundingBox)
        }
    }
    
    /// Analyze OCR results and identify logical text groups
    func analyzeTextGroups(from image: UIImage) async throws -> [[String]] {
        // First, get OCR results with layout information
        let blocks = try await extractTextBlocksWithLayout(from: image)
        
        // Identify logical groups based on spatial relationships
        let groups = identifyTextGroups(blocks)
        
        // Convert each group to a string array
        let textGroups: [[String]] = groups.map { group in
            // Sort blocks top-to-bottom within each group
            return group.blocks.sorted { $0.boundingBox.minY < $1.boundingBox.minY }
                .map { $0.text }
        }
        
        return textGroups
    }
    
    /// Extract text blocks with layout information using Vision
    private func extractTextBlocksWithLayout(from image: UIImage) async throws -> [TextBlock] {
        guard let cgImage = image.cgImage else {
            throw RecipeProcessingError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            let request = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: RecipeProcessingError.noTextFound)
                    return
                }
                
                var blocks: [TextBlock] = []
                
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    
                    let block = TextBlock(
                        text: candidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence
                    )
                    blocks.append(block)
                }
                
                continuation.resume(returning: blocks)
            }
            
            // Configure for accurate layout detection
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.revision = VNRecognizeTextRequestRevision3
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Identify logical groups of text based on spatial proximity and visual formatting
    private func identifyTextGroups(_ blocks: [TextBlock]) -> [TextGroup] {
        var groups: [TextGroup] = []
        
        // Sort blocks by Y position first for better grouping
        let sortedBlocks = blocks.sorted { $0.boundingBox.minY < $1.boundingBox.minY }
        var remainingBlocks = sortedBlocks
        
        // Constants for grouping heuristics
        let verticalGapThreshold: CGFloat = 0.003  // Relative to image height
        let horizontalOverlapThreshold: CGFloat = 0.3  // Minimum horizontal overlap ratio
        
        while !remainingBlocks.isEmpty {
            // Start a new group with the topmost remaining block
            let firstBlock = remainingBlocks.removeFirst()
            var currentGroup = TextGroup(
                blocks: [firstBlock],
                boundingBox: firstBlock.boundingBox
            )
            
            var changed = true
            // Keep adding blocks to the group until no more can be added
            while changed {
                changed = false
                
                // Try to find blocks that belong to this group
                remainingBlocks = remainingBlocks.filter { block in
                    // Check if this block is close enough vertically to the current group
                    let verticalGap = block.boundingBox.minY - currentGroup.boundingBox.maxY
                    let closeVertically = verticalGap <= verticalGapThreshold
                    
                    // Check horizontal overlap
                    let overlapWidth = min(block.boundingBox.maxX, currentGroup.boundingBox.maxX) -
                                      max(block.boundingBox.minX, currentGroup.boundingBox.minX)
                    let minWidth = min(block.boundingBox.width, currentGroup.boundingBox.width)
                    let hasHorizontalOverlap = overlapWidth > 0 && (overlapWidth / minWidth) >= horizontalOverlapThreshold
                    
                    // Evaluate formatting characteristics (similar font size, styles, etc.)
                    // This could be extended with more sophisticated checks
                    
                    // Add to group if criteria are met
                    if closeVertically && hasHorizontalOverlap {
                        currentGroup.addBlock(block)
                        changed = true
                        return false
                    }
                    
                    return true
                }
            }
            
            groups.append(currentGroup)
        }
        
        // Sort groups top-to-bottom
        groups.sort { $0.boundingBox.minY < $1.boundingBox.minY }
        
        return groups
    }
    
    /// Analyze text features to identify section boundaries
    /// For future enhancement: detect headings, ingredient lists, instruction steps, etc.
    private func analyzeTextFeatures(_ text: String) -> [String: Any] {
        // This could use NLTagger to identify language features
        // For now, return a simple analysis
        return [
            "length": text.count,
            "hasNumbers": text.contains(where: { $0.isNumber }),
            "isUppercase": text.uppercased() == text
        ]
    }
}
