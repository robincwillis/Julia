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
    
    struct Column {
        let blocks: [TextBlock]
        let boundingBox: CGRect
    }
    
        
    /// Analyze OCR results and reorder text based on spatial layout
    func analyzeAndReorderText(from image: UIImage) async throws -> [String] {
        // First, get OCR results with layout information
        let blocks = try await extractTextBlocksWithLayout(from: image)
        
        // Group blocks into columns
        let columns = groupBlocksIntoColumns(blocks)
        
        // Sort columns left-to-right
        let sortedColumns = columns.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
        
        // For each column, sort blocks top-to-bottom
        var orderedText: [String] = []
        for column in sortedColumns {
            let sortedBlocks = column.blocks.sorted { $0.boundingBox.minY < $1.boundingBox.minY }
            orderedText.append(contentsOf: sortedBlocks.map { $0.text })
        }
        
        return orderedText
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
    
    /// Group text blocks into columns based on horizontal overlap
    private func groupBlocksIntoColumns(_ blocks: [TextBlock]) -> [Column] {
        var columns: [Column] = []
        var remainingBlocks = blocks
        
        while !remainingBlocks.isEmpty {
            let firstBlock = remainingBlocks.removeFirst()
            var columnBlocks = [firstBlock]
            var columnBox = firstBlock.boundingBox
            
            // Find all blocks that horizontally overlap with this column
            remainingBlocks = remainingBlocks.filter { block in
                let horizontalOverlap = columnBox.intersection(
                    CGRect(x: block.boundingBox.minX, y: 0,
                           width: block.boundingBox.width, height: 1)
                ).width > 0
                
                if horizontalOverlap {
                    columnBlocks.append(block)
                    columnBox = columnBox.union(block.boundingBox)
                    return false
                }
                return true
            }
            
            columns.append(Column(blocks: columnBlocks, boundingBox: columnBox))
        }
        
        return columns
    }
}
