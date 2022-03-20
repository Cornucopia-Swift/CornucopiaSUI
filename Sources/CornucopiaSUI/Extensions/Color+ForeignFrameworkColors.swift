//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

public extension Color {

#if os(iOS) || os(tvOS) || os(watchOS)

    static var primaryBackground: Color {
        Color(.systemBackground)
    }
    static var secondaryBackground: Color {
        Color(.secondarySystemBackground)
    }
    static var tertiaryBackground: Color {
        Color(.tertiarySystemBackground)
    }

    static var primaryGroupedBackground: Color {
        Color(.systemGroupedBackground)
    }
    static var secondaryGroupedBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }
    static var tertiaryGroupedBackground: Color {
        Color(.tertiarySystemGroupedBackground)
    }

    static var tertiary: Color {
        Color(.tertiaryLabel)
    }

#elseif os(macOS)

    static var primaryBackground: Color {
        Color(.textBackgroundColor)
    }

    static var tertiary: Color {
        Color(.tertiaryLabelColor)
    }
#endif
}

