//
//  Binding+Extensions.swift
//  Julia
//
//  Created by Robin Willis on 3/30/25.
//

import SwiftUI

extension Binding {
  init(_ source: Binding<Value?>, default defaultValue: Value) {
    self.init(
      get: { source.wrappedValue ?? defaultValue },
      set: { source.wrappedValue = $0 }
    )
  }
}
