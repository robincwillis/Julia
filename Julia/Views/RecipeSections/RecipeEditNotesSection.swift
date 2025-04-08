//
//  RecipeEditNotesSection.swift
//  Julia
//
//  Created by Robin Willis on 3/30/25.
//

import SwiftUI

struct RecipeEditNotesSection: View {
  @Binding var notes: [Note]
  @State private var newNoteText: String = ""
  @Binding var focusedField: RecipeFocusedField

  @FocusState private var focusedNoteField: String?
  
  var body: some View {

    Section(header: Text("Notes")) {
      if notes.isEmpty {
        Text("No notes added")
          .foregroundColor(.secondary)
      } else {
        let sortedNotes: [Note] = notes.sorted { $0.position < $1.position }
        ForEach(sortedNotes) { note in
          if let noteIndex = notes.firstIndex(where: {$0.id == note.id }) {
            TextField("Note \(note.id)", text: $notes[noteIndex].text, axis: .vertical)
              .focused($focusedNoteField, equals: note.id)
              .onSubmit {
                focusedNoteField = nil
              }
          }
        }
        .onDelete { indices in
          deleteNote(at: indices)
        }
        .onMove { from, to in
          moveNote(from: from, to: to)
        }
      }
      
      
      HStack {
        TextField("Add a note", text: $newNoteText)
          .submitLabel(.done)
          .focused($focusedNoteField, equals: "new")
          .onSubmit {
            focusedNoteField = nil
          }
        
        Button(action: addNewNote) {
          Image(systemName: "plus.circle.fill")
            .foregroundColor(.blue)
        }
        .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding(.top, 4)
    }
    .onChange(of: focusedNoteField) { _, newValue in
      if let noteId =  newValue {
        focusedField = .note(noteId)
      } else {
        focusedField = .none
      }
    }
  }
  
  private func addNewNote() {
    let noteText = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if !noteText.isEmpty {
      withAnimation {
        notes.append(Note(text:noteText))
        newNoteText = ""
      }
    }
  }

  private func deleteNote(at offsets: IndexSet) {
    withAnimation {
      notes.remove(atOffsets: offsets)
    }
  }
  
  private func moveNote(from source: IndexSet, to destination: Int) {
      var sortedNotes: [Note] = notes.sorted { $0.position < $1.position }
      sortedNotes.move(fromOffsets: source, toOffset: destination)
      for (index, note) in sortedNotes.enumerated() {
        note.position = index
      }
      notes.move(fromOffsets: source, toOffset: destination)
  }
}


#Preview {
  struct RecipeEditNotesSectionPreview: View {
    @State var notes: [Note] = [
     Note(text:"This recipe can be made ahead and refrigerated for up to 3 days."),
     Note(text:"Substitute almond milk for a dairy-free version."),
     Note(text:"Make sure you use ice cold butter"),
    ]
    
    @State private var focusedField: RecipeFocusedField = .none

    
    var body: some View {
      NavigationStack {
        Form {
          RecipeEditNotesSection(
            notes: $notes,
            focusedField: $focusedField
          )
        }
        .toolbar {
          EditButton()
        }
      }
    }
  }
  
  return RecipeEditNotesSectionPreview()
}
