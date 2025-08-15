//
//  Cornucopia – (C) Dr. Lauer Information Technology
//

// Taken from https://swiftuirecipes.com/blog/getting-size-of-a-view-in-swiftui

import SwiftUI

struct SizePreferenceKey: PreferenceKey {

    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

public struct MeasureSizeModifier: ViewModifier {

    public func body(content: Content) -> some View {
        content.background(GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self,
                                   value: geometry.size)
        })
    }
}

public extension View {

    /// Measures the size of an element and calls the supplied closure.
    func CC_measureSize(perform action: @escaping (CGSize) -> Void) -> some View {
        self.modifier(MeasureSizeModifier())
            .onPreferenceChange(SizePreferenceKey.self, perform: action)
    }
}

#if DEBUG
#Preview {
    struct MeasureSizeExample: View {
        @State private var textSize: CGSize = .zero
        @State private var rectangleSize: CGSize = .zero
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Hello, World!")
                    .font(.title)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .CC_measureSize { size in
                        textSize = size
                    }
                
                Text("Text Size: \(textSize.width, specifier: "%.0f") × \(textSize.height, specifier: "%.0f")")
                    .font(.caption)
                
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 200, height: 100)
                    .CC_measureSize { size in
                        rectangleSize = size
                    }
                
                Text("Rectangle Size: \(rectangleSize.width, specifier: "%.0f") × \(rectangleSize.height, specifier: "%.0f")")
                    .font(.caption)
            }
            .padding()
        }
    }
    
    return MeasureSizeExample()
}
#endif
