//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

public extension View {

    func CC_debugPrinting(_ value: Any) -> some View {
#if DEBUG
        print(value)
#endif
        return self
    }
}

#if DEBUG
#Preview {
    struct DebugPrintingExample: View {
        @State private var counter = 0
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Counter: \(counter)")
                    .font(.largeTitle)
                    .CC_debugPrinting("Counter value is: \(counter)")
                
                Button("Increment") {
                    counter += 1
                }
                .buttonStyle(.borderedProminent)
                .CC_debugPrinting("Button tapped, new value will be: \(counter + 1)")
                
                Text("Check the console for debug output")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .CC_debugPrinting("View body recomputed")
        }
    }
    
    return DebugPrintingExample()
}
#endif
