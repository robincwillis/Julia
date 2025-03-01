//
//  EditIngredient.swift
//  Julia
//
//  Created by Robin Willis on 11/11/24.
//

import SwiftUI

struct EditIngredient: View {
  
  @State private var name = ""
  @State private var measurementUnit = ""
  
    var body: some View {
        Text("Hello, World!")
      // Todo Move to EditIngredient
      // TextField("Enter Measurement Unit", text: $measurementUnit)
    }
}

#Preview {
    EditIngredient()
}
