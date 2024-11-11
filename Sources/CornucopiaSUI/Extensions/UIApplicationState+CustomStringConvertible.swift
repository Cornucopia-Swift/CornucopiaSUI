//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if os(iOS) || os(tvOS) || os(watchOS)
#if canImport(UIKit)
import UIKit

extension UIApplication.State: @retroactive CustomStringConvertible {
    /// A friendly description for the application state enum.
    public var description: String {
        switch self {
            case .active: "Active"
            case .inactive: "Inactive"
            case .background: "Background"
            @unknown default: "Unknown"
        }
    }
}
#endif
#endif
