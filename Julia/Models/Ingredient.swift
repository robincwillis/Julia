//
//  Ingredient.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import Foundation
import SwiftData

@Model
final class Ingredient: Identifiable, Hashable {
    enum CodingKeys: CodingKey {
        case name
    }
    
    @Attribute(.unique) var id: String = UUID().uuidString
    var createdDate: Date
    var name: String
    var quantity: Double?
    var measurement: String?
    var comment: String?
    var recipe: Recipe?
    private var imageName: String?
    //  var image: Image? {
    //        Image(imageName)
    //  }
  init(id: String = UUID().uuidString, name: String, quantity: Double? = nil, measurement: String? = nil, comment: String? = nil, imageName: String? = nil, recipe: Recipe? = nil) {
        self.id = id
        self.createdDate = Date()
        self.name = name
        self.quantity = quantity
        self.measurement = measurement
        self.comment = comment
        self.imageName = imageName
        self.recipe = recipe
    }
  
}
