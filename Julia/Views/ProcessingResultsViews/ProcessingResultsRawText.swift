//
//  ProcessingResultsRawText.swift
//  Julia
//
//  Created by Robin Willis on 3/16/25.
//

import SwiftUI

struct ProcessingResultsRawText: View {
  let recognizedText: [String]

  var body: some View {

      Form {
        Section {
          ForEach(Array(recognizedText.enumerated()), id: \.offset) { index, line in
            VStack(alignment: .leading) {
              HStack(alignment: .top) {
                Text("\(index + 1).")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .frame(width: 30, alignment: .trailing)
                  .padding(.top, 2)
                
                Text(line)
                  .font(.system(size: 14, design: .monospaced))
                  .textSelection(.enabled)
              }
            }
            .listRowSeparator(.visible)
          }
        } header: {
          Text("Raw Text (\(recognizedText.count) lines)")
        }
      }
      .listStyle(.inset)
  }
}
  

#Preview {
    let recognizedText: [String] = [
     "Line 1",
     "Line 2",
     "Line 3",
    ]
    return ProcessingResultsRawText(recognizedText:recognizedText)
}
