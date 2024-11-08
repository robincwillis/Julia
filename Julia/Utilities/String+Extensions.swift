//
//  String+Extensions.swift
//  Julia
//
//  Created by Robin Willis on 7/2/24.
//

import Foundation

extension String {
    func pluralized(for quantity: Double) -> String {
        if quantity > 1 {
            return self + "s"
        } else {
            return self
        }
    }
}
