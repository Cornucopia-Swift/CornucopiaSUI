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
