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

#if DEBUG
#Preview {
    struct InvisibleNavigationExample: View {
        @State private var navigateToDetail = false
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Tap the button to navigate")
                        .font(.headline)
                    
                    Button("Navigate Programmatically") {
                        navigateToDetail = true
                    }
                    .buttonStyle(.borderedProminent)
                    .CC_withInvisibleNavigation {
                        Text("Detail View")
                            .font(.largeTitle)
                            .navigationTitle("Detail")
                    }
                    
                    Text("This uses an invisible NavigationLink\nbehind the scenes")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                .navigationTitle("Invisible Navigation")
            }
        }
    }
    
    return InvisibleNavigationExample()
}
#endif
