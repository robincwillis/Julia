//
//  Image.swift
//  Julia
//
//  Created by Robin Willis on 4/5/25.
//

import Foundation
import SwiftData
import UIKit

@Model
final class ImageItem: Identifiable {
  @Attribute(.unique) var id: String = UUID().uuidString
  var title: String
  var imageData: Data?
  var creationDate: Date
  var isFavorite: Bool
  
  init(
    id: String = UUID().uuidString,
    title: String,
    imageData: Data? = nil,
    creationDate: Date = Date(),
    isFavorite: Bool = false
  ) {
    self.id = id
    self.title = title
    self.imageData = imageData
    self.creationDate = creationDate
    self.isFavorite = isFavorite
  }
  
  // Computed property to get the image if available
  var image: UIImage? {
    if let imageData = imageData {
      return UIImage(data: imageData)
    }
    return nil
  }
  
  // Method to update the image
  func updateImage(_ newImage: UIImage?) {
    self.imageData = newImage?.jpegData(compressionQuality: 0.8)
  }
}
