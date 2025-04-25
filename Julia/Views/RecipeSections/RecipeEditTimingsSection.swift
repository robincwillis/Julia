//
//  RecipeEditTimingsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/18/25.
//

import SwiftUI
import SwiftData

struct RecipeEditTimingsSection: View {
  @Environment(\.modelContext) private var context
  @Binding var timings: [Timing]
  
  private var sortedTimings: [Timing] {
    timings.sorted(by: { $0.position < $1.position })
  }
  
  private var timingsBinding: Binding<[Timing]> {
    Binding(
      get: { timings },
      set: { timings = $0 }
    )
  }
  
  // Common time types for recipes
  let timeTypes = ["Prep", "Cook", "Total", "Rest", "Chill", "Bake", "Freeze", "Rise", "Inactive", "Simmer"]
  
  // Track which timing is currently being edited
  @State private var editingTimingId: String? = nil
  
  var body: some View {
    Section(header: Text("Timings")) {
      // Existing timings
      ForEach(sortedTimings) { timing in
        let index = getIndex(for: timing)
        TimingRow(
          timing: timingsBinding[index],
          timeTypes: timeTypes,
          editingId: $editingTimingId
          
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: editingTimingId)
        
      }
      .onDelete { indices in
        // Delete timings
        withAnimation {
          // Remove from the array in reverse order to avoid index shifting
          for index in indices.sorted(by: >) {
            if index < timingsBinding.wrappedValue.count {
              let timing = timingsBinding.wrappedValue[index]
              var updatedArray = timingsBinding.wrappedValue
              updatedArray.remove(at: index)
              timingsBinding.wrappedValue = updatedArray
              context.delete(timing)
            }
          }
        }
      }
      .onMove { from, to in
        // Handle moving timings
        var updatedTimings = sortedTimings
        updatedTimings.move(fromOffsets: from, toOffset: to)
        
        // Update positions
        for (index, timing) in updatedTimings.enumerated() {
          timing.position = index
        }
        
        // Update binding
        timings = updatedTimings
      }
      // Add timing button with improved styling
      Button(action: addTiming) {
        Label("Add Timing", systemImage: "plus")
      }
    }
  }
  
  // Helper to find the index of a timing in the array
  private func getIndex(for timing: Timing) -> Int {
    guard let index = sortedTimings.firstIndex(where: { $0.id == timing.id }) else {
      return 0
    }
    return index
  }
  
  private func updateTimingPositions() {
    for (index, timing) in sortedTimings.enumerated() {
      timing.position = index
    }
  }
  
  private func addTiming() {
    // Find the first timing type that doesn't exist yet
    var newTimeType = timeTypes.first ?? "Prep"
    let existingTypes = Set(timingsBinding.wrappedValue.map { $0.type })
    
    for type in timeTypes {
      if !existingTypes.contains(type) {
        newTimeType = type
        break
      }
    }
    
    let position = timings.count
    
    // Create new timing with default values
    let timing = Timing(type: newTimeType, hours: 0, minutes: 15, position: position)
    context.insert(timing)
    
    // Add to our list and set it as the one being edited
    withAnimation {
      timings.append(timing)
      editingTimingId = nil
    }
  }
}

struct TimingRow: View {
  @Binding var timing: Timing
  let timeTypes: [String]
  @Binding var editingId: String?
  @Environment(\.modelContext) private var context
  
  @State var isEditing: Bool = false
  
  var body: some View {
    VStack (spacing: 8) { //
                          // Main row content
      HStack {
        // Type picker menu
        Menu {
          Picker("Type", selection: $timing.type) {
            ForEach(timeTypes, id: \.self) { type in
              Text(type).tag(type)
            }
          }
        } label: {
          Text("\(timing.type) Time")
            .foregroundColor(Color.app.textPrimary)
            .padding(.vertical, 4)
        }
        
        Spacer()
        
        // Time display with edit on tap
        Button(action: {
          if editingId == timing.id {
              editingId = nil
          } else {
            editingId = timing.id
          }
          //withAnimation {
          //}
        }) {
          Text(timing.display)
            .foregroundColor(Color.app.textSecondary)
            .padding(.vertical, 4)
        }
      }
      // Time editor that animates in and out
      if isEditing {
        VStack (spacing: 12) {
          HStack {
            Picker("Hours", selection: $timing.hours) {
              ForEach(0..<73) { hour in
                if hour == 1 {
                  Text("1 hour").tag(1)
                } else {
                  Text("\(hour) hours").tag(hour)
                }
              }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            
            Picker("Minutes", selection: $timing.minutes) {
              ForEach(0..<60) { minute in
                if minute == 1 {
                  Text("1 minute").tag(1)
                } else {
                  Text("\(minute) minutes").tag(minute)
                }
              }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
          }
          HStack {
            Button(action: {
              timing.hours = 0
              timing.minutes = 0
              saveChanges()
              editingId = nil
            }) {
              Text("Clear")
                .foregroundColor(.red)
            }
            .padding(.horizontal, 4)
            .buttonStyle(BorderlessButtonStyle())
            Spacer()
            Button(action: {
              saveChanges()
              editingId = nil
            }) {
              Text("Done")
                .fontWeight(.medium)
            }
            .padding(.horizontal, 4)
            .buttonStyle(BorderlessButtonStyle())

          }
        }
      }
    }
    .padding(.vertical, 4)
    .onChange(of: editingId) { oldValue, newValue in
      withAnimation(.easeInOut(duration: 0.3)) {
        isEditing = newValue == timing.id
      }
    }
    .onChange(of: timing.hours) { _, _ in
      saveChanges()
    }
    .onChange(of: timing.minutes) { _, _ in
      saveChanges()
    }
    .onChange(of: timing.type) { _, _ in
      saveChanges()
    }
    .id(timing.id + "-" + String(isEditing))
  }
  
  private func saveChanges() {
    do {
      try context.save()
    } catch {
      print("Error saving timing changes: \(error.localizedDescription)")
    }
  }
}

struct TimingsPreview: View {
  @State var recipe: Recipe
  
  var body: some View {
    Form {
      RecipeEditTimingsSection(timings: $recipe.timings)
    }
  }
}

#Preview("Edit Timings") {
  Previews.customRecipe( hasTimings: true) { recipe in
    TimingsPreview(recipe: recipe)
  }
}

