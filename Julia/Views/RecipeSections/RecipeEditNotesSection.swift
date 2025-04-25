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
      notesList
      addNoteRow
    }
    .onChange(of: focusedNoteField) { _, newValue in
      if let noteId = newValue {
        focusedField = .note(noteId)
      } else {
        focusedField = .none
      }
    }
  }
  
  // Break the complex expressions into separate computed properties
  private var notesList: some View {
    Group {
      if notes.isEmpty {
        Text("No notes added")
          .foregroundColor(Color.app.textLabel)
      } else {
        notesContent
      }
    }
  }
  
  private var notesContent: some View {
    let sortedNotes = notes.sorted { $0.position < $1.position }
    
    return ForEach(sortedNotes, id: \.id) { note in
      noteRow(for: note)
    }
    .onDelete { indices in
      deleteNote(at: indices)
    }
    .onMove { from, to in
      moveNote(from: from, to: to)
    }
  }
  
  private func noteRow(for note: Note) -> some View {
    Group {
      if let noteIndex = notes.firstIndex(where: {$0.id == note.id }) {
        TextField("Note \(note.id)", text: $notes[noteIndex].text, axis: .vertical)
          .foregroundColor(Color.app.textPrimary)
          .focused($focusedNoteField, equals: note.id)
          .onSubmit {
            focusedNoteField = nil
          }
      }
    }
  }
  
  private var addNoteRow: some View {
    HStack {
      TextField("Add a note", text: $newNoteText)
        .foregroundColor(Color.app.textPrimary)
        .submitLabel(.done)
        .focused($focusedNoteField, equals: "new")
        .onSubmit {
          focusedNoteField = nil
        }
      
      Button(action: addNewNote) {
        Image(systemName: "plus.circle.fill")
      }
      .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    .padding(.top, 4)
  }
  
  // Leave your existing methods as they are
  private func addNewNote() {
    let noteText = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if !noteText.isEmpty {
      withAnimation {
        notes.append(Note(text: noteText))
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
