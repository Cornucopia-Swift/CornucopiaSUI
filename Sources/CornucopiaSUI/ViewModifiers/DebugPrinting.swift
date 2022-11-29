//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

public extension View {

    func CC_debugPrinting(_ value: Any) -> some View {
        print(value)
#if DEBUG
        return self
#endif
    }
}
