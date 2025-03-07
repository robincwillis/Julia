//
//  RecipeTitleSection.swift
//  Julia
//
//  Created by Robin Willis on 3/7/25.
//

import SwiftUI

struct RecipeTitleSection: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(recipe.title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 4)
            
            if let summary = recipe.summary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}

#Preview {
    RecipeTitleSection(
        recipe: Recipe(
            title: "Classic Chocolate Chip Cookies",
            summary: "Delicious, chewy chocolate chip cookies with crisp edges and soft centers. Perfect for any occasion!",
            ingredients: [],
            instructions: []
        )
    )
    .padding()
    .background(Color(.systemGray6))
}