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
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Image(systemName: "person.2.fill")
            .font(.headline)
            .foregroundStyle(Color.app.primary)
          Text("\(displayServings)")
            .font(.headline)
            .foregroundStyle(Color.app.textPrimary)
        }
        Text(isScaled ? "of \(servings)" : "servings")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
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

  var body: some View {
    if timings.count == 1, let timing = timings.first {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Image(systemName: "timer")
            .font(.headline)
            .foregroundColor(Color.app.primary)
          Text(timing.displayShort)
            .font(.headline)
            .foregroundColor(Color.app.textPrimary)
        }
        Text(timing.type)
          .font(.caption2)
          .foregroundColor(Color.app.labelPrimary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          ForEach(timings) { timing in
            VStack(alignment: .leading, spacing: 4) {
              HStack(spacing: 6) {
                Image(systemName: "timer")
                  .font(.headline)
                  .foregroundColor(Color.app.primary)
                Text(timing.displayShort)
                  .font(.headline)
                  .foregroundColor(Color.app.textPrimary)
              }
              Text(timing.type)
                .font(.caption2)
                .foregroundColor(Color.app.labelPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .containerRelativeFrame(.horizontal, count: 2, spacing: 16)
          }
        }
      }
    }
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
    let multipleTimings = recipe.timings.count > 1

    if hasServings || hasTimings {
      HStack(spacing: 12) {
        if hasServings {
          ServingsCard(
            servings: recipe.servings!,
            adjustedServings: adjustedServings,
            onTap: onTapServings
          )
          .background(Color.app.backgroundInput)
          .cornerRadius(16)
          // Expand to fill 50% when paired with a single timing; stay compact otherwise
          .frame(maxWidth: (hasTimings && !multipleTimings) ? .infinity : nil, minHeight: 64)
        }

        if hasTimings {
          TimingsCard(timings: recipe.timings)
            .background(Color.app.backgroundInput)
            .cornerRadius(16)
            .frame(maxWidth: .infinity, minHeight: 64)
        }
      }
      // Left-align the HStack so a lone card doesn't centre-stretch
      .frame(maxWidth: .infinity, alignment: .leading)
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
            .background(Color.app.backgroundCard)
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
            .background(Color.app.backgroundCard)
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
