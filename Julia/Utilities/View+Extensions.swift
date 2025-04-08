//
//  View+Extensions.swift
//  Julia
//
//  Created by Robin Willis on 3/18/25.
//

import SwiftUI

extension View {
  func hideKeyboard() {
    print("Hiding keyboard called")
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
