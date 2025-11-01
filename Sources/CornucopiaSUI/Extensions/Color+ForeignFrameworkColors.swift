//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

public extension Color {

#if os(iOS) || os(watchOS)
    static var primaryBackground: Color { Color(.systemBackground) }
    static var secondaryBackground: Color { Color(.secondarySystemBackground) }
    static var tertiaryBackground: Color { Color(.tertiarySystemBackground) }

    static var primaryGroupedBackground: Color { Color(.systemGroupedBackground) }
    static var secondaryGroupedBackground: Color { Color(.secondarySystemGroupedBackground) }
    static var tertiaryGroupedBackground: Color { Color(.tertiarySystemGroupedBackground) }

#elseif os(tvOS)
    static var primaryBackground: Color { Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.1, alpha: 1) : UIColor(white: 0.95, alpha: 1) }) }
    static var secondaryBackground: Color { Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 1) : UIColor(white: 1.0, alpha: 1) }) }
    static var tertiaryBackground: Color { Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.2, alpha: 1) : UIColor(white: 0.9, alpha: 1) }) }

    static var primaryGroupedBackground: Color { Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.1, alpha: 1) : UIColor(white: 0.95, alpha: 1) }) }
    static var secondaryGroupedBackground: Color { Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 1) : UIColor(white: 1.0, alpha: 1) }) }
    static var tertiaryGroupedBackground: Color { Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.2, alpha: 1) : UIColor(white: 0.9, alpha: 1) }) }
#endif

    static var tertiary: Color { Color(.tertiaryLabel) }
    static var separatorColor: Color { Color(.separator) }
    static var opaqueSeparatorColor: Color { Color(.opaqueSeparator) }
}
#elseif os(macOS)
import AppKit

public extension Color {

    static var primaryBackground: Color { Color(.textBackgroundColor) }
    static var tertiary: Color { Color(.tertiaryLabelColor) }
    static var separatorColor: Color { Color(.tertiaryLabelColor) }

}
#endif
