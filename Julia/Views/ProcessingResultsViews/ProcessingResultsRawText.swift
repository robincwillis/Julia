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
      VStack {
        HStack {
          Text("Raw OCR Text (\(recognizedText.count) lines)")
            .font(.headline)
        }
        .padding(.horizontal)
        
        List {
          ForEach(Array(recognizedText.enumerated()), id: \.offset) { index, line in
            VStack(alignment: .leading) {
              HStack(alignment: .top) {
                Text("\(index + 1).")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .frame(width: 30, alignment: .trailing)
                  .padding(.top, 2)
                
                Text(line)
                  .font(.system(.body, design: .monospaced))
                  .textSelection(.enabled)
              }
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .listRowSeparator(.visible)
          }
        }
        .listStyle(.inset)
      }
    }
}

#Preview {
    let recognizedText: [String] = [
     "Line 1",
     "Line 2",
     "Line 3"
    ]
    return ProcessingResultsRawText(recognizedText:recognizedText)
}
