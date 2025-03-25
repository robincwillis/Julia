import SwiftUI



struct ExpandableFormView: View {
  struct Item: Identifiable {
    let id: UUID  // Explicitly defining the unique ID
    let title: String
    var isExpanded: Bool
  }
  
  @State private var items: [Item] = [
    Item(id: UUID(), title: "Item 1", isExpanded: false),
    Item(id: UUID(), title: "Item 2", isExpanded: false),
    Item(id: UUID(), title: "Item 3", isExpanded: false)
  ]
  
  var body: some View {
    List {
      ForEach($items, id: \.id) { $item in
        ExpandableRow(item: $item)
      }
    }
    .listStyle(.inset)
  }
}

struct ExpandableRow: View {
  @Binding var item: ExpandableFormView.Item
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(item.title)
          .font(.headline)
        Spacer()
        Button(action: {
          withAnimation {
            item.isExpanded.toggle()
          }
        }) {
          Image(systemName: item.isExpanded ? "chevron.up" : "chevron.down")
            .foregroundColor(.blue)
        }
      }
      
      if item.isExpanded {
        Text("Additional content for \(item.title)")
          .font(.subheadline)
          .transition(.opacity.combined(with: .slide))
      }
    }
    //.frame(maxHeight: item.isExpanded ? 200 : 100)
    .id(item.id.uuidString + String(item.isExpanded))
    .padding()
  }
}

#Preview {
  ExpandableFormView()
}
