//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// An invisible navigation link.
public struct InvisibleNavigationLink<Destination>: ViewModifier where Destination: View {

    @ViewBuilder let destination: () -> Destination

    public init(@ViewBuilder destination: @escaping () -> Destination) {
        self.destination = destination
    }

    public func body(content: Content) -> some View {
        content.background {
            NavigationLink(destination: self.destination(), label: { EmptyView() })
                .buttonStyle(PlainButtonStyle()).frame(width:0).opacity(0)
        }
    }
}

extension View {
    /// Creates an invisible ``NavigationLink`` pointing to the specified ``View``.
    public func CC_withInvisibleNavigation<Destination: View>(@ViewBuilder destination: @escaping () -> Destination) -> some View {
        modifier(InvisibleNavigationLink(destination: destination))
    }
}
