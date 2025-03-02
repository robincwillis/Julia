//
//  TextRecognitionService.swift
//  Julia
//
//  Created by Claude on 3/2/25.
//

import Vision
import UIKit

/// Service to handle text recognition from images
class TextRecognitionService {
    static let shared = TextRecognitionService()
    
    private init() {}
    
    /// Performs OCR on an image and returns recognized text as an array of strings
    /// - Parameter image: The image to extract text from
    /// - Returns: Array of recognized text strings
    func recognizeText(from image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else {
            return []
        }
        
        return await withCheckedContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                
                let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: recognizedStrings)
            }
            
            // Configure for accurate recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            do {
                try requestHandler.perform([request])
            } catch {
                print("Unable to perform OCR request: \(error).")
                continuation.resume(returning: [])
            }
        }
    }
}