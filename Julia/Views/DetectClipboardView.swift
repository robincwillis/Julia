//
//  DetectClipboardView.swift
//  Julia
//
//  Created by Robin Willis on 4/8/25.
//

import SwiftUI

import UIKit


struct DetectClipboardView: View {
  //@Binding var detectedURL: String?

//  @State private var detectedURL: String? = "https://robincwillis.com"
//  ,
//detectedURL: $detectedURL,
//onImportURL: { url in
//  print(url)
//}
//  
  
//  .onChange(of: detectedURL) { _, newValue in
//    // Show bar when URL is detected
//    if newValue != nil {
//      //show()
//    } else {
//      //dismiss()
//    }
//  }

//   var onImportURL: (String) -> Void

  
  var body: some View {
    Text("Hello for now")
  }
}

//  var body: some View {
//    if (detectedURL != nil) {
//      HStack(spacing: 12) {
//        // Icon
//        Image(systemName: "list.clipboard")
//          .font(.system(size: 18))
//          .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
//          .padding(12)
//          .frame(width: 30, height: 30)
//        //.background(Color(red: 0.85, green: 0.92, blue: 1.0))
//        
//        // URL preview text
//        
//        VStack (alignment: .leading) {
//          Text("Website Avaliable")
//          Text("On your clipboard")
//          
//        }
//        
//        //.font(.system(size: 15, weight: .medium))
//        //.lineLimit(1)
//        
//        
//        Spacer()
//        
//        Button(action: {
//          if let url = detectedURL {
//            onImportURL(url)
//            dismiss()
//          }
//        }) {
//          Text("Import")
//            .font(.system(size: 14, weight: .semibold))
//            .padding(.horizontal, 12)
//            .padding(.vertical, 12)
//            .background(.blue)
//            .cornerRadius(12)
//            .foregroundColor(.white)
//        }
//        
//        
//      }
//      
//      .padding(24)
//      //.offset(y: offsetY)
//      .background(.white)
//      .cornerRadius(24)
//      .animation(.spring(response: 0.4, dampingFraction: 0.7), value: offsetY)
//      //.animation(.easeInOut, value: isVisible)
//      .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
//      .padding(.horizontal, 24)
//    }
//  }
//}
//  .onChange(of: detectedURL) { _, newValue in
//    // Show bar when URL is detected
//    if newValue != nil {
//      //show()
//    } else {
//      //dismiss()
//    }
//  }
//}


#Preview {
  DetectClipboardView()
}
