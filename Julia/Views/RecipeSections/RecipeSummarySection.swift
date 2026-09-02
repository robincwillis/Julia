//
//  RecipeTitleSection.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI
import SwiftData

struct ServingsCard: View {
  let servings: Int
  var adjustedServings: Int? = nil
  var onTap: (() -> Void)? = nil

  private var isScaled: Bool {
    guard let adj = adjustedServings else { return false }
    return adj != servings
  }
  private var displayServings: Int { adjustedServings ?? servings }

  var body: some View {
    Button(action: { onTap?() }) {
      VStack(spacing: 6) {
        Image(systemName: "person.2.fill")
          .font(.title2)
          .foregroundStyle(Color.app.primary)
        Text("\(displayServings)")
          .font(.headline)
          .foregroundStyle(Color.app.textPrimary)
        if isScaled {
          Text("of \(servings)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        } else {
          Text("servings")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .padding()
      .frame(minWidth: 80, minHeight: 80)
    }
    .buttonStyle(.plain)
    .overlay(alignment: .topTrailing) {
      if isScaled {
        Circle()
          .fill(Color.app.primary)
          .frame(width: 8, height: 8)
          .padding(8)
      }
    }
  }
}

struct TimingsCard: View {
  let timings: [Timing]
  let allowExpand: Bool

  var body: some View {
    VStack(alignment: .leading) {
      // If only one timing, use a centered HStack without ScrollView
      if timings.count == 1, let timing = timings.first {
        VStack(spacing: 6) {
          Image(systemName: "timer")
            .font(.title2)
            .foregroundColor(Color.app.primary)

          HStack(spacing: 4) {
            Text(timing.displayShort)
              .font(.headline)
              .foregroundColor(Color.app.textPrimary)

            Text(timing.type)
              .font(.headline)
              .foregroundColor(Color.app.textLabel)
          }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
      } else {
        // Multiple timings - use ScrollView with leading alignment
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 24) {
            ForEach(timings) { timing in
              HStack(alignment: .firstTextBaseline) {
                Image(systemName: "timer")
                  .font(.title2)
                  .foregroundColor(Color.app.primary)
                  .alignmentGuide(.firstTextBaseline) { d in
                    d[.bottom] - 8
                  }

                VStack(alignment: .leading, spacing: 4) {
                  Text(timing.displayShort)
                    .font(.headline)
                    .foregroundColor(Color.app.textPrimary)

                  Text(timing.type)
                    .font(.headline)
                    .foregroundColor(Color.app.textLabel)
                }
              }
            }
          }
          .padding()
        }
      }
    }
    .frame(minHeight: 80)
    .frame(maxWidth: allowExpand ? .infinity : nil, alignment: .leading)
  }
}

struct RecipeSummarySection: View {
  let recipe: Recipe
  var adjustedServings: Int? = nil
  var onTapServings: (() -> Void)? = nil

  var body: some View {
    if let summary = recipe.summary {
      Text(summary)
        .font(.body)
    }
    let hasServings = recipe.servings != nil
    let hasTimings = !recipe.timings.isEmpty
    let singleTiming = recipe.timings.count == 1

    if (hasServings || hasTimings) {
      GeometryReader { geometry in
        HStack(spacing: 12) {
          if hasServings {
            ServingsCard(
              servings: recipe.servings!,
              adjustedServings: adjustedServings,
              onTap: onTapServings
            )
            .frame(
              width: hasTimings && singleTiming ?
              geometry.size.width * 0.5 : nil
            )
            .background(Color.app.offWhite200)
            .cornerRadius(24)
          }

          if hasTimings {
            TimingsCard(
              timings: recipe.timings,
              allowExpand: !hasServings || !singleTiming
            )
            .frame(
              width: hasServings && singleTiming ?
              geometry.size.width * 0.5 : nil
            )
            .background(Color.app.offWhite200)
            .cornerRadius(24)
          }
        }
        .frame(maxWidth: geometry.size.width)
      }
      .frame(height: 80)
    }
  }
}

struct ServingAdjusterSheet: View {
  let originalServings: Int
  @Binding var adjustedServings: Int?
  @Environment(\.dismiss) private var dismiss

  @State private var currentValue: Int

  init(originalServings: Int, adjustedServings: Binding<Int?>) {
    self.originalServings = originalServings
    self._adjustedServings = adjustedServings
    self._currentValue = State(initialValue: adjustedServings.wrappedValue ?? originalServings)
  }

  var body: some View {
    VStack(spacing: 20) {
      Text("Adjust Servings")
        .font(.headline)
        .padding(.top, 24)

      HStack(spacing: 32) {
        Button {
          if currentValue > 1 { currentValue -= 1 }
        } label: {
          Image(systemName: "minus")
            .font(.title3.weight(.medium))
            .frame(width: 44, height: 44)
            .background(Color.app.offWhite200)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)

        Text("\(currentValue)")
          .font(.system(size: 40, weight: .semibold, design: .rounded))
          .frame(minWidth: 60, alignment: .center)
          .contentTransition(.numericText())
          .animation(.snappy, value: currentValue)

        Button {
          currentValue += 1
        } label: {
          Image(systemName: "plus")
            .font(.title3.weight(.medium))
            .frame(width: 44, height: 44)
            .background(Color.app.offWhite200)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
      }

      Text(currentValue == originalServings ? "Original: \(originalServings) servings" : "Original: \(originalServings) servings")
        .font(.caption)
        .foregroundStyle(currentValue == originalServings ? Color.clear : .secondary)

      HStack(spacing: 24) {
        if adjustedServings != nil && adjustedServings != originalServings {
          Button("Reset") {
            adjustedServings = nil
            dismiss()
          }
          .foregroundStyle(.secondary)
        }

        Button("Done") {
          adjustedServings = currentValue == originalServings ? nil : currentValue
          dismiss()
        }
        .foregroundStyle(Color.app.primary)
        .fontWeight(.medium)
      }
      .padding(.bottom, 8)
    }
    .padding(.horizontal)
  }
}

#Preview("RecipeSummarySection") {
  Previews.customRecipe(
    hasTimings: true,
    hasServings: true,
    timingsCount: 3
  ) { recipe in
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        RecipeSummarySection(recipe: recipe)
      }
      .padding()
    }
  }
}
