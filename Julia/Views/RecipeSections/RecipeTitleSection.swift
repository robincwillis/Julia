//
//  RecipeTitleSection.swift
//  Julia
//
//  Created by Claude on 3/2/25.
//

import SwiftUI

struct RecipeTitleSection: View {
    let recipe: Recipe
    let isEditing: Bool
    @Binding var editedTitle: String
    @Binding var editedSummary: String
    @FocusState var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title section
            if isEditing {
                TextField("Recipe Title", text: $editedTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.vertical, 8)
                    .cornerRadius(8)
                    .background(Color(.systemGray6))
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
            }
            
            // Summary section
            if let summary = recipe.summary, !isEditing {
                VStack (alignment: .leading) {
                    Text("Summary")
                        .font(.headline)
                        .padding(.bottom, 6)
                    Text(summary)
                        .font(.caption)
                }
                Divider()
            } else if isEditing {
                VStack(alignment: .leading) {
                    Text("Summary")
                        .font(.headline)
                        .padding(.bottom, 6)
                    TextField("Recipe summary", text: $editedSummary, axis: .vertical)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .lineLimit(4...8)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isTextFieldFocused = false
                        }
                }
                Divider()
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var title = "Sample Recipe"
        @State private var summary = "A delicious sample recipe"
        @FocusState private var focused: Bool
        
        var body: some View {
            RecipeTitleSection(
                recipe: Recipe(
                    title: "Sample Recipe",
                    summary: "A delicious sample recipe",
                    ingredients: [],
                    instructions: []
                ),
                isEditing: true,
                editedTitle: $title,
                editedSummary: $summary,
                isTextFieldFocused: _focused
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}
