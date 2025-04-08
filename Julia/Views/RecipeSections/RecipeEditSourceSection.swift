//
//  RecipeEditSourceSection.swift
//  Julia
//
//  Created by Robin Willis on 3/30/25.
//

import SwiftUI

struct RecipeEditSourceSection: View {
  @Binding var source: String
  @Binding var sourceTitle: String
  @Binding var author: String
  @Binding var website: String
  @Binding var sourceType: SourceType
  
  var body: some View {
    Section("Source") {
      // Source Title
      HStack {
        Text("Title")
          .foregroundColor(.secondary)
        Spacer()
        TextField("Optional", text: $sourceTitle)
          .multilineTextAlignment(.trailing)
          .submitLabel(.done)
      }

      // author
      HStack {
        Text("Author")
          .foregroundColor(.secondary)
        Spacer()
        TextField("Optional", text: $author)
          .multilineTextAlignment(.trailing)
          .submitLabel(.done)
      }

      // Website
      HStack {
        Text("Website")
          .foregroundColor(.secondary)
        Spacer()
        TextField("Optional", text: $website)
          .keyboardType(.URL)
          .autocapitalization(.none)
          .autocorrectionDisabled()
          .multilineTextAlignment(.trailing)
          .submitLabel(.done)
      }

      HStack {
        Text("Type")
          .foregroundColor(.secondary)
        Spacer()
        Menu {
          Picker("Type", selection: $sourceType) {
            ForEach(SourceType.allCases, id: \.self) { type in
              Text(type.displayName).tag(type)
            }
          }
        } label: {
          Text("\(sourceType.displayName)")
        }
      }
    }
  }
}

#Preview {
  struct RecipeEditSourceSectionPreview: View {
    @State private var source: String = ""
    @State private var sourceTitle: String = ""
    @State private var author: String = ""
    @State private var website: String = ""
    @State private var sourceType: SourceType = .manual
    
    var body: some View {
      Form {
        RecipeEditSourceSection(
          source: $source,
          sourceTitle: $sourceTitle,
          author: $author,
          website: $website,
          sourceType: $sourceType
        )
      }
    }
  }
  
  return RecipeEditSourceSectionPreview()
}
