//
//  RecipeEditRawTextSection.swift
//  Julia
//
//  Created by Robin Willis on 3/23/25.
//

import SwiftUI

struct RecipeEditMetaSection: View {
  @Binding var rawText: String
  var isRawTextFieldFocused: FocusState<Bool>.Binding
  
  @State private var sourceType: SourceType = .manual
  @State private var website: String = ""
  @State private var sourceTitle: String = ""
  @State private var author: String = ""
  
  @State private var notes: [String] = []
  @State private var tags: [String] = []
  
  @State private var newNote: String = ""
  @State private var newTag: String = ""
  
  var body: some View {
    Section("Notes") {
      if notes.isEmpty {
        Text("No notes added")
          .foregroundColor(.gray)
          .padding(.vertical, 4)
      } else {
        ForEach(notes.indices, id: \.self) { index in
          Text(notes[index])
            .padding(.vertical, 4)
        }
        .onDelete { indexSet in
          notes.remove(atOffsets: indexSet)
        }
      }
      
      HStack {
        TextField("Add a note", text: $newNote)
          .submitLabel(.done)
        
        Button(action: addNote) {
          Image(systemName: "plus.circle.fill")
            .foregroundColor(.blue)
        }
        .disabled(newNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    
    Section ("Source") {
      // Source
      // Source Title
      HStack {
        Text("Title")
          .foregroundColor(.secondary)
        Spacer()
        TextField("", text: $sourceTitle)
          .multilineTextAlignment(.trailing)
      }
      // Website
      HStack {
        Text("Website")
          .foregroundColor(.secondary)
        Spacer()
        TextField("", text: $website)
          .keyboardType(.URL)
          .autocapitalization(.none)
          .autocorrectionDisabled()
          .multilineTextAlignment(.trailing)
      }
      // author
      HStack {
        Text("Author")
          .foregroundColor(.secondary)
        Spacer()
        TextField("", text: $author)
          .multilineTextAlignment(.trailing)
          .frame(maxWidth: 200)
      }
      
    }
    
    Section(header: Text("Source Type")) {
      Picker("Type", selection: $sourceType) {
        ForEach(SourceType.allCases, id: \.self) { type in
          Text(type.displayName).tag(type)
        }
      }
      .pickerStyle(.menu)
    }
    
    Section("Tags") {
      VStack(alignment: .leading) {
        // Display existing tags in a wrapped layout
        if !tags.isEmpty {
          TagsFlowView(tags: tags) { tag in
            Button(action: {
              removeTag(tag)
            }) {
              HStack(spacing: 4) {
                Text(tag)
                  .font(.subheadline)
                Image(systemName: "xmark.circle.fill")
                  .font(.caption)
              }
              .padding(.vertical, 4)
              .padding(.horizontal, 8)
              .background(Color(.systemGray5))
              .clipShape(Capsule())
            }
          }
          .padding(.vertical, 4)
        } else {
          Text("No tags added")
            .foregroundColor(.gray)
            .padding(.vertical, 4)
        }
        
        // Add new tag
        HStack {
          TextField("Add a tag", text: $newTag)
            .submitLabel(.done)
            .onSubmit {
              addTag()
            }
          
          Button(action: addTag) {
            Image(systemName: "plus.circle.fill")
              .foregroundColor(.blue)
          }
          .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
    
    
    Section("Raw Text") {

      TextEditor(text: $rawText)
        .font(.system(size: 14, design: .monospaced))
        .padding(.vertical, 8)
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .foregroundColor(.secondary)
        .background(.white)
        .cornerRadius(12)
        .focused(isRawTextFieldFocused)
        .onSubmit {
          isRawTextFieldFocused.wrappedValue = false
        }
    }
  }
  
  private func addNote() {
    let trimmedNote = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if !trimmedNote.isEmpty {
      notes.append(trimmedNote)
      newNote = ""
    }
  }
  
  private func addTag() {
    let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
      tags.append(trimmedTag)
      newTag = ""
    }
  }
  
  private func removeTag(_ tag: String) {
    if let index = tags.firstIndex(of: tag) {
      tags.remove(at: index)
    }
  }
  
  
}


// Helper view for wrapping tags in a flow layout
struct TagsFlowView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
  let tags: Data
  let tagContent: (Data.Element) -> Content
  
  init(tags: Data, @ViewBuilder tagContent: @escaping (Data.Element) -> Content) {
    self.tags = tags
    self.tagContent = tagContent
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      GeometryReader { geometry in
        self.generateRows(with: geometry.size.width)
      }
    }
  }
  
  private func generateRows(with containerWidth: CGFloat) -> some View {
    var rows: [[Data.Element]] = [[]]
    var currentRowWidth: CGFloat = 0
    
    // Calculate row arrangement
    for tag in tags {
      let label = tagContent(tag)
      let labelSize = UIHostingController(rootView: label).view.intrinsicContentSize
      
      if currentRowWidth + labelSize.width + 8 > containerWidth && !rows[rows.count - 1].isEmpty {
        // Start a new row
        rows.append([tag])
        currentRowWidth = labelSize.width + 8
      } else {
        // Add to the current row
        rows[rows.count - 1].append(tag)
        currentRowWidth += labelSize.width + 8
      }
    }
    
    return VStack(alignment: .leading, spacing: 8) {
      ForEach(0..<rows.count, id: \.self) { rowIndex in
        HStack(spacing: 8) {
          ForEach(rows[rowIndex], id: \.self) { tag in
            tagContent(tag)
          }
        }
      }
    }
  }
}




#Preview {
  @State var rawText = "Hello World"
  @FocusState var isRawTextFieldFocused: Bool
  return RecipeEditMetaSection(
    rawText: $rawText,
    isRawTextFieldFocused: $isRawTextFieldFocused
  )
}
