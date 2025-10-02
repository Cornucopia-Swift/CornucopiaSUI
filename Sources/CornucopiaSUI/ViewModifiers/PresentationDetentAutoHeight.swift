//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// Measures the content's height and uses it as `presentationDetents`
struct PresentationDetentAutoHeight: ViewModifier {
    @State private var height: CGFloat? = nil
    @State private var isInitialized = false
    
    // Threshold to avoid micro-adjustments
    private let heightChangeThreshold: CGFloat = 5.0
    
    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { newHeight in
                // Only update if significantly different or first measurement
                if !isInitialized {
                    height = newHeight
                    isInitialized = true
                } else if let currentHeight = height,
                          abs(newHeight - currentHeight) > heightChangeThreshold {
                    height = newHeight
                }
            }
            .presentationDetents(
                height != nil ? [.height(height!)] : []
            )
            // Set background to ensure sheet doesn't resize content
            .presentationBackgroundInteraction(.enabled)
    }
}

public extension View {
    func CC_presentationDetentAutoHeight() -> some View {
        self.modifier(PresentationDetentAutoHeight())
    }
}
