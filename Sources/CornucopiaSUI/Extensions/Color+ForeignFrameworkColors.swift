//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

public extension Color {
    static var primaryBackground: Color { Color(.systemBackground) }
    static var secondaryBackground: Color { Color(.secondarySystemBackground) }
    static var tertiaryBackground: Color { Color(.tertiarySystemBackground) }

    static var primaryGroupedBackground: Color { Color(.systemGroupedBackground) }
    static var secondaryGroupedBackground: Color { Color(.secondarySystemGroupedBackground) }
    static var tertiaryGroupedBackground: Color { Color(.tertiarySystemGroupedBackground) }

    static var tertiary: Color { Color(.tertiaryLabel) }
    static var separatorColor: Color { Color(.separator) }
    static var opaqueSeparatorColor: Color { Color(.opaqueSeparator) }
}
#elseif os(macOS)
import AppKit

public extension Color {

    static var primaryBackground: Color { Color(.textBackgroundColor) }
    static var tertiary: Color { Color(.tertiaryLabelColor) }

}
#endif
