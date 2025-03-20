//
//  EditTimings.swift
//  Julia
//
//  Created by Robin Willis on 3/18/25.
//

import SwiftUI
import SwiftData

struct EditTimings: View {
  //@Binding var recipe: Recipe
  @Binding var timings: [Timing]
  
  @State private var newTimeType = ""
  @State private var newTimeHours = 0
  @State private var newTimeMinutes = 0
  @State private var isAddingNew = false
  
  private let timeTypes = ["Prep", "Cook", "Total", "Rest", "Chill", "Bake", "Freeze", "Rise", "Inactive", "Simmer"]
  
  var body: some View {
    List {
      // Standard iOS list with swipe-to-delete functionality
      ForEach(timings) { timing in
        TimingRow(timing: $timings[getIndex(for: timing)])
      }
      .onDelete { indices in
        // Standard iOS delete pattern
        withAnimation {
          // We need to map indices to actual timings since the index
          // in ForEach might not match the underlying array
          for index in indices.sorted(by: >) {
            if index < timings.count {
              timings.remove(at: index)
            }
          }
        }
      }
      
      // "Add Timing" button as a list row
      if !isAddingNew {
        Button(action: {
          withAnimation {
            isAddingNew = true
            newTimeType = ""
            newTimeHours = 0
            newTimeMinutes = 0
          }
        }) {
          HStack {
            Label("Add Timing", systemImage: "plus")
              .foregroundColor(.blue)
            Spacer()
          }
        }
      } else {
        // Add new timing form
        VStack(spacing: 12) {
          HStack {
            Menu {
              ForEach(timeTypes, id: \.self) { type in
                Button(type) {
                  newTimeType = type
                }
              }
              
              Button("Custom") {
                // Use the empty string to allow custom input
                newTimeType = ""
              }
            } label: {
              HStack {
                Text(newTimeType.isEmpty ? "Select Type" : newTimeType)
                Spacer()
                Image(systemName: "chevron.down")
                  .font(.caption)
              }
              .foregroundColor(newTimeType.isEmpty ? .secondary : .primary)
              .padding(.vertical, 8)
              .padding(.horizontal, 12)
              .background(Color(.systemGray6))
              .cornerRadius(8)
            }
            
            if newTimeType.isEmpty {
              TextField("Custom Type", text: $newTimeType)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
          }
          
          HStack(spacing: 8) {
            Picker("Hours", selection: $newTimeHours) {
              ForEach(0..<24) { hour in
                Text("\(hour) hr")
                  .tag(hour)
              }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .clipped()
            
            Picker("Minutes", selection: $newTimeMinutes) {
              ForEach(0..<60) { minute in
                Text("\(minute) min")
                  .tag(minute)
              }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .clipped()
          }
          .background(Color(.systemGray6))
          .cornerRadius(8)
          
          HStack {
            Button("Cancel") {
              withAnimation {
                isAddingNew = false
              }
            }
            .foregroundColor(.red)
            
            Spacer()
            
            Button("Add") {
              if !newTimeType.isEmpty && (newTimeHours > 0 || newTimeMinutes > 0) {
                withAnimation {
                  timings.append(Timing(
                    type: newTimeType,
                    hours: newTimeHours,
                    minutes: newTimeMinutes
                  ))
                  isAddingNew = false
                }
              }
            }
            .foregroundColor(.blue)
            .disabled(newTimeType.isEmpty || (newTimeHours == 0 && newTimeMinutes == 0))
          }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
      }
    }
  }
  
  private func getIndex(for timing: Timing) -> Int {
    guard let index = timings.firstIndex(where: { $0.id == timing.id }) else {
      return 0
    }
    return index
  }
}

struct TimingRow: View {
  @Binding var timing: Timing
  
  // Available timing types
  private let timeTypes = ["Prep", "Cook", "Total", "Rest", "Chill", "Bake", "Freeze", "Rise", "Inactive", "Simmer"]
  
  // States for different edit modes
  @State private var isEditingType = false
  @State private var isEditingTime = false
  @State private var editedHours = 0
  @State private var editedMinutes = 0
  
  var body: some View {
    HStack {
      // Type label with edit on tap
      Button(action: {
        isEditingType = true
      }) {
        Text(timing.type)
          .font(.headline)
          .foregroundColor(.primary)
      }
      .sheet(isPresented: $isEditingType) {
        // Type picker in a sheet
        NavigationStack {
          List {
            ForEach(timeTypes, id: \.self) { type in
              Button(action: {
                timing.type = type
                isEditingType = false
              }) {
                HStack {
                  Text(type)
                  Spacer()
                  if timing.type == type {
                    Image(systemName: "checkmark")
                      .foregroundColor(.blue)
                  }
                }
              }
              .foregroundColor(.primary)
            }
            
            Section("Custom") {
              TextField("Custom Type", text: $timing.type)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.done)
                .onSubmit {
                  isEditingType = false
                }
            }
          }
          .navigationTitle("Select Timing Type")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                isEditingType = false
              }
            }
            
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") {
                isEditingType = false
              }
            }
          }
        }
        .presentationDetents([.medium])
      }
      
      Spacer()
      
      // Time display with edit on tap
      Button(action: {
        // Initialize with current values
        editedHours = timing.hours
        editedMinutes = timing.minutes
        isEditingTime = true
      }) {
        Text(timing.display)
          .font(.body)
          .foregroundColor(.secondary)
      }
      .sheet(isPresented: $isEditingTime) {
        // Combined time picker in a sheet
        NavigationStack {
          VStack {
            HStack {
              Picker("Hours", selection: $editedHours) {
                ForEach(0..<24) { hour in
                  Text("\(hour) hr")
                    .tag(hour)
                }
              }
              .pickerStyle(.wheel)
              .frame(height: 150)
              .clipped()
              
              Picker("Minutes", selection: $editedMinutes) {
                ForEach(0..<60) { minute in
                  Text("\(minute) min")
                    .tag(minute)
                }
              }
              .pickerStyle(.wheel)
              .frame(height: 150)
              .clipped()
            }
            .padding()
          }
          .navigationTitle("Edit Time")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                isEditingTime = false
              }
            }
            
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") {
                timing.hours = editedHours
                timing.minutes = editedMinutes
                isEditingTime = false
              }
            }
          }
        }
        .presentationDetents([.medium])
      }
    }
    .padding(.vertical, 8)
  }
}
  
  
  #Preview("EditTimings") {
    // Define preview components outside the ViewBuilder closure
    struct TimingRowPreview: View {
        @State private var timing: Timing
        
        init(timing: Timing) {
            self._timing = State(initialValue: timing)
        }
        
        var body: some View {
            TimingRow(timing: $timing)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
        }
    }
    
    struct EditTimingsPreview: View {
        @State private var timings: [Timing]
        
        init(timings: [Timing]) {
            self._timings = State(initialValue: timings)
        }
        
        var body: some View {
            Form {
                EditTimings(timings: $timings)
            }
        }
    }
    
    // Simple sample data creation
    let timing1 = Timing(type: "Prep", hours: 0, minutes: 15)
    let timing2 = Timing(type: "Cook", hours: 1, minutes: 30)
    
    // Use our preview helper with a simple ViewBuilder closure
    return DataController.makePreview {
        VStack(spacing: 20) {
            Text("Single Row Preview").font(.headline)
            TimingRowPreview(timing: timing1)
            
            Divider().padding(.vertical, 10)
            
            Text("Full Editor Preview").font(.headline)
            EditTimingsPreview(timings: [timing1, timing2])
                .frame(height: 400)
        }
    }
}
