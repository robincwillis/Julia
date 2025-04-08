//
//  RecipeEditTagsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/30/25.
//


import SwiftUI

struct RecipeEditTagsSection: View {
  @Binding var tags: [String]
  @State private var newTag: String = ""
  
  var body: some View {
    Section("Tags") {
      VStack(alignment: .leading) {
        // Display existing tags in a wrapped layout
        if !tags.isEmpty {
          FlowHStack {
            ForEach(tags, id: \.self) { tag in
              Button(action: {
                removeTag(tag)
              }) {
                HStack(spacing: 4) {
                  Text(tag)
                    .font(.subheadline)
                  Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                }
                .padding(.vertical, 8)
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .background(Color(red: 0.85, green: 0.92, blue: 1.0))
                .clipShape(Capsule())
              }
              .buttonStyle(BorderlessButtonStyle())
            }
          }
          .padding(.vertical, 6)
        } else {
          Text("No tags added")
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
        }
        // Add new tag
        HStack {
          VStack {
            TextField("Add a tag", text: $newTag)
              .submitLabel(.done)
              .onSubmit {
                addTag()
              }
          }
          Button(action: addTag) {
            Image(systemName: "plus.circle.fill")
              .foregroundColor(.blue)
          }
          .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.top, 3)
      }
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


struct FlowHStack: Layout {
  var horizontalSpacing: CGFloat = 8
  var verticalSpacing: CGFloat = 8
  
  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let subviewSizes = subviews.map { $0.sizeThatFits(proposal) }
    let maxSubviewHeight = subviewSizes.map { $0.height }.max() ?? .zero
    var currentRowWidth: CGFloat = .zero
    var totalHeight: CGFloat = maxSubviewHeight
    var totalWidth: CGFloat = .zero
    
    for size in subviewSizes {
      let requestedRowWidth = currentRowWidth + horizontalSpacing + size.width
      let availableRowWidth = proposal.width ?? .zero
      let willOverflow = requestedRowWidth > availableRowWidth
      
      if willOverflow {
        totalHeight += verticalSpacing + maxSubviewHeight
        currentRowWidth = size.width
      } else {
        currentRowWidth = requestedRowWidth
      }
      
      totalWidth = max(totalWidth, currentRowWidth)
    }
    
    return CGSize(width: totalWidth, height: totalHeight)
  }
  
  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let subviewSizes = subviews.map { $0.sizeThatFits(proposal) }
    let maxSubviewHeight = subviewSizes.map { $0.height }.max() ?? .zero
    var point = CGPoint(x: bounds.minX, y: bounds.minY)
    
    for index in subviews.indices {
      let requestedWidth = point.x + subviewSizes[index].width
      let availableWidth = bounds.maxX
      let willOverflow = requestedWidth > availableWidth
      
      if willOverflow {
        point.x = bounds.minX
        point.y += maxSubviewHeight + verticalSpacing
      }
      
      subviews[index].place(at: point, proposal: ProposedViewSize(subviewSizes[index]))
      point.x += subviewSizes[index].width + horizontalSpacing
    }
  }
}


// Helper extension for reading view sizes
private extension View {
  func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
    background(
      GeometryReader { geo in
        Color.clear
          .onAppear { onChange(geo.size) }
          .onChange(of: geo.size) { oldValue, newValue in
            onChange(newValue)
          }
      }
    )
  }
}


#Preview {
  struct RecipeEditTagsSectionPreview: View {
    @State private var tags: [String] = ["Italian", "Pasta", "Quick", "Dinner", "Family Favorite", "Vegetarian", "Easy"]
    
    var body: some View {
      Form {
        RecipeEditTagsSection(
          tags: $tags
        )
      }
    }
  }
  
  return RecipeEditTagsSectionPreview()
}
