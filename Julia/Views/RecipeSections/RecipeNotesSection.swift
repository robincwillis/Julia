//
//  RecipeNotesSection.swift
//  Julia
//
//  Created by Robin Willis on 3/30/25.
//

import SwiftUI

struct RecipeNotesSection: View {
  let notes: [Note]
  
  private var sortedNotes: [Note] {
    return notes.sorted { $0.position < $1.position }
  }
  
    var body: some View {
      VStack (alignment: .leading, spacing: 8) {
        if !notes.isEmpty {
          Text("Notes")
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.bottom, 8)
        }
        ForEach(sortedNotes) { note in
          Text(note.text)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading) // This makes it expand to available width
            .background(.background.secondary)
            .cornerRadius(12)
            
        }
    
      }
    }
}
#Preview {
  let notes: [Note] = [
    Note(text: "This recipe can be made ahead and refrigerated for up to 3 days."),
    Note(text: "Substitute almond milk for a dairy-free version.")
  ]
  return RecipeNotesSection(notes:notes)
}
