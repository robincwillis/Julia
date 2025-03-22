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
  @Binding var timings: [Timing]?
  
  private var timingsBinding: Binding<[Timing]> {
    Binding(
      get: { timings ?? [] },
      set: { timings = $0.isEmpty ? nil : $0 }
    )
  }
  
  // State for adding new timing
  @State private var isAddingNew = false
  
  // Common time types for recipes
  let timeTypes = ["Prep", "Cook", "Total", "Rest", "Chill", "Bake", "Freeze", "Rise", "Inactive", "Simmer"]
  
  // Track which timing is currently being edited
  @State private var editingTimingId: String? = nil
  
  var body: some View {
    Section(header: Text("Timings")) {
      // Existing timings
      ForEach(timingsBinding.wrappedValue) { timing in
        let index = getIndex(for: timing)
        TimingRow(
          timing: timingsBinding[index],
          timeTypes: timeTypes,
          isEditing: Binding(
            get: { editingTimingId == timing.id },
            set: { if $0 { editingTimingId = timing.id } else { editingTimingId = nil } }
          )
        )
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
      
      // Add timing button with improved styling
      Button(action: addTiming) {
        HStack {
          Image(systemName: "plus.circle.fill")
            .foregroundColor(.blue)
          Text("Add Timing")
            .foregroundColor(.blue)
          Spacer()
        }
        .padding(.vertical, 4)
      }
    }
  }
  
  // Helper to find the index of a timing in the array
  private func getIndex(for timing: Timing) -> Int {
    guard let index = timingsBinding.wrappedValue.firstIndex(where: { $0.id == timing.id }) else {
      return 0
    }
    return index
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
    
    // Create new timing with default values
    let timing = Timing(type: newTimeType, hours: 0, minutes: 15)
    context.insert(timing)
    
    // Add to our list and set it as the one being edited
    withAnimation {
      var updatedArray = timingsBinding.wrappedValue
      updatedArray.append(timing)
      timingsBinding.wrappedValue = updatedArray
      editingTimingId = timing.id
    }
  }
}

struct TimingRow: View {
  @Binding var timing: Timing
  let timeTypes: [String]
  @Binding var isEditing: Bool
  
  var body: some View {
    VStack(spacing: 8) {
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
            .foregroundColor(.primary)
            .padding(.vertical, 4)
        }
        
        Spacer()
        
        // Time display with edit on tap
        Button(action: {
          withAnimation {
            isEditing.toggle()
          }
        }) {
          Text(timing.display)
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
        }
      }
      
      // Time editor that animates in and out
      if isEditing {
        VStack(spacing: 12) {
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
              withAnimation {
                isEditing = false
              }
            }) {
              Text("Clear")
                .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            
            Spacer()
            
            Button(action: {
              withAnimation {
                isEditing = false
              }
            }) {
              Text("Done")
                .foregroundColor(.blue)
                .fontWeight(.medium)
            }
            .buttonStyle(.borderless)
          }
          .padding(.horizontal, 4)
        }
        .padding(.top, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .padding(.vertical, 4)
  }
}


#Preview("EditTimings - Simple") {
  // Use a completely minimal approach for reliability
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: Schema([
      Timing.self,
      Ingredient.self,
      Recipe.self,
      IngredientSection.self
    ])
  )
  
  // Use a container-aware preview
  struct PreviewContent: View {
    @Environment(\.modelContext) private var context
    @State private var timings: [Timing]? = []

    
    var body: some View {
      Form {
        RecipeEditTimingsSection(timings: $timings)
      }
      .onAppear {
        // Create sample timings when the view appears
        if timings == nil || timings!.isEmpty {
          createSampleTimings()
        }
      }
    }
    
    private func createSampleTimings() {
      let timing1 = Timing(type: "Prep", hours: 0, minutes: 15)
      let timing2 = Timing(type: "Cook", hours: 1, minutes: 30)
      
      context.insert(timing1)
      context.insert(timing2)
      
      timings = [timing1, timing2]
    }
  }
  
  return PreviewContent()
    .modelContainer(container)
}

