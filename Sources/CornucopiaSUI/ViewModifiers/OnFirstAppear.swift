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
