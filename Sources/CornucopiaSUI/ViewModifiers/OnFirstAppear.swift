//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// Schedules a closure to execute when the view appears, but only once.
public struct OnFirstAppear: ViewModifier {

    let perform: () -> Void

    @State private var isExecutingForTheFirstTime: Bool = true

    public func body(content: Content) -> some View {

        content
            .onAppear {
                guard self.isExecutingForTheFirstTime else { return }
                self.isExecutingForTheFirstTime = false
                self.perform()
            }
    }
}

extension View {
    /// Executes the closure when the view first appears.
    public func CC_onFirstAppear(perform: @escaping () -> Void ) -> some View {
        self.modifier(OnFirstAppear(perform: perform))
    }
}

#if DEBUG
#Preview {
    struct OnFirstAppearExample: View {
        @State private var appearCount = 0
        @State private var firstAppearCount = 0
        @State private var showChild = true
        
        var body: some View {
            VStack(spacing: 20) {
                Text("First Appear Count: \(firstAppearCount)")
                    .font(.headline)
                
                Text("Regular Appear Count: \(appearCount)")
                    .font(.headline)
                
                Toggle("Show Child View", isOn: $showChild)
                    .padding()
                
                if showChild {
                    Text("Child View")
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .CC_onFirstAppear {
                            firstAppearCount += 1
                        }
                        .onAppear {
                            appearCount += 1
                        }
                }
                
                Text("Toggle the child view on/off.\nFirst appear only triggers once.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    return OnFirstAppearExample()
}
#endif
