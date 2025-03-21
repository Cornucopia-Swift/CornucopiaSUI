//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// Measures the content's height and uses it as `presentationDetents`
struct PresentationDetentAutoHeight: ViewModifier {
    @State private var height: CGFloat? = nil

    func body(content: Content) -> some View {
        content
        // Use the new onGeometryChange to track the view's geometry
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { newHeight in
                if height != newHeight {
                    height = newHeight
                }
            }
        // Use the measured height as the presentation detent,
        // falling back to .medium until the height is available.
            .presentationDetents(
                height != nil ?
                [.height(height!)] :
                    [.medium]
            )
    }
}

public extension View {
    func CC_presentationDetentAutoHeight() -> some View {
        self.modifier(PresentationDetentAutoHeight())
    }
}

#if DEBUG
//MARK: - Example

struct BottomView: View {
    var body: some View {
        VStack {
            Text("Hello")
            Text("World")
        }
        .padding()
    }
}

struct MyContentView: View {
    @State private var presentSheet: Bool = false

    var body: some View {
        Button("Tap me") {
            presentSheet.toggle()
        }
        .sheet(isPresented: $presentSheet) {
            BottomView()
                .CC_presentationDetentAutoHeight()
        }
    }
}

#Preview {
    MyContentView()
}
#endif
