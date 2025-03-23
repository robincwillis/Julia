//
//  Timing.swift
//  Julia
//
//  Created by Robin Willis on 3/22/25.
//

import Foundation
import SwiftData

@Model
class Timing: Identifiable {
  @Attribute(.unique) var id: String = UUID().uuidString
  var type: String // maybe enum: prep, cook, bake, total
  var hours: Int
  var minutes: Int
  
  init(id: String = UUID().uuidString, type: String, hours: Int, minutes: Int) {
    self.id = id
    self.type = type
    self.hours = hours
    self.minutes = minutes
  }
  
  var displayShort: String {
    let hourText = hours > 0 ? "\(hours) hr" : ""
    let minuteText = minutes > 0 ? "\(minutes) min" : ""
    let separator = (hours > 0 && minutes > 0) ? " " : ""
    
    return "\(hourText)\(separator)\(minuteText)"
  }
  
  var display: String {
    if hours == 0 && minutes == 0 {
      return "Set time"
    }
    
    if hours == 0 {
      return "\(minutes) \(minutes == 1 ? "minute" :  "minutes")"
    }
    
    if minutes == 0 {
      return "\(hours) \(hours == 1 ? "hour" : "hours")"
    }
    
    return "\(hours) \(hours == 1 ? "hour" : "hours") \(minutes) \(minutes == 1 ? "minute" :  "minutes")"
  }
}
