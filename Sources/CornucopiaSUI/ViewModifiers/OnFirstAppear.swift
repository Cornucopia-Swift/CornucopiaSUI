//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

public struct OnFirstAppear: ViewModifier {

    let perform: () -> Void

    @State private var firstTime: Bool = true

    public func body(content: Content) -> some View {

        content
            .onAppear {
                guard self.firstTime else { return }
                self.firstTime = false
                self.perform()
            }
    }
}

extension View {

    public func CC_onFirstAppear(perform: @escaping () -> Void ) -> some View {
        self.modifier(OnFirstAppear(perform: perform))
    }
}
