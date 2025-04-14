import SwiftUI



struct PlaygroundView: View {
  
  struct Item: Identifiable {
    let id: UUID  // Explicitly defining the unique ID
    let title: String
    
  }
  @State var isExpanded = false
  
  @State var showTwo = false
  @State var showThree = false
  
  @State var isVisible = false
  @State var isLoading = false
  
  @State var y: CGFloat = -100
  @State var red = false
  
  var body: some View {
    ZStack {

      if isVisible {
        
        
        VStack {
          Loader(isLoading: $isLoading)
          
          
          //      VStack {
          //        Text("Hello world")
          //          .offset(x: animated ? 100 : 0)
          //
          //
          //        Text("Fat")
          //          .offset(x: animated ? 100 : 0)
          //      }
          //      .animation(.easeInOut, value: animated)
          
          if isExpanded {
            Text("Something in here")
            // .fadeIn(isVisible: isExpanded, delay: 0.5)
          }
          
          if showTwo {
            
            Circle()
              .offset(y: y)
              .fill(red ? .red : .blue)
              .frame(width: 30, height: 30)
              
            //.fadeIn(isVisible: isExpanded, delay: 1)
            //.opacity(isExpanded ? 1 : 2)
          }
          
        }
        
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white)
        .cornerRadius(24)
        .padding(.horizontal, 64)
        .offset(y: isVisible ?  -100 : 100)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -300)
        //.offset(x: 100)
        .animation(.linear(duration: 1), value: isVisible)
        
      }
      

      VStack(spacing: 8) {
        Spacer()
        Button("Animate In") {
          print(y)
          
          withAnimation {
            isVisible.toggle()
            y = 0
            print(y)

          } completion: {
            isLoading.toggle()
          }
          
          withAnimation (.spring(response: 0.4,dampingFraction: 0.8,blendDuration: 0
                                ).delay(1)) {
            isExpanded.toggle()
          }
          withAnimation (.spring(response: 0.4,dampingFraction: 0.8,blendDuration: 0).delay(2))  {
            showTwo.toggle()
          }
          
        }
        Button("Animate Out") { 
          print(y)
          isLoading.toggle()
          // changes the values of two dependencies in the closure
          withAnimation (.spring(response: 0.4,dampingFraction: 0.8,blendDuration: 0
                                ).delay(1)) {
            isExpanded.toggle()
          }
          withAnimation (.spring(response: 0.4,dampingFraction: 0.8,blendDuration: 0).delay(2))  {
            showTwo.toggle()
          } completion: {
            withAnimation {
              isVisible.toggle()
              y = 100
              print(y)

            } completion: {
              y = -100
              print(y)

            }
          }
          
          // Wait for the animation duration before changing otherState
          //        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
          //        }
        }
      }
    }
    .frame(maxWidth: .infinity)
    .background(Color.gray.opacity(0.5))
    
    //.background(.grey)
//    .onAppear {
//      .animation(
//        .spring(
//          response: 0.4,
//          dampingFraction: 0.8,
//          blendDuration: 0
//        )
//        .delay(delay),
//        value: isVisible
//      )
      
    }
  }
  


extension View {
  func fadeIn(
    isVisible: Bool,
    delay: Double = 0
  ) -> some View {
    self
      //.frame(height: isVisible ? .infinity: 0)
      .opacity(isVisible ? 1 : 0)
      .animation(
        .spring(
          response: 0.4,
          dampingFraction: 0.8,
          blendDuration: 0
        )
        .delay(delay),
        value: isVisible
      )
  }
}


struct FloatingPlaygroundSheet: View {
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
    }
  }
}

#Preview {
  PlaygroundView()
}
