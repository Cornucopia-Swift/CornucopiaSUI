//
//  KeypadKeyStyle.swift
//  CornucopiaSUI
//

import SwiftUI

/// The resolved colours for a single keypad key in a given colour scheme.
struct KeypadKeyColors {
    let foreground: Color
    let background: Color
    let pressedBackground: Color
    let border: Color
}

/// A key role that knows how to paint itself. Each domain keypad defines its own
/// role enum (digits, accent letters, separators, actions…) and maps it to colours.
protocol KeypadKeyRole {
    func colors(for colorScheme: ColorScheme) -> KeypadKeyColors
}

/// Shared button style for every domain keypad key (Hex / VIN / IPv4 / MAC).
///
/// Rendering — rounded fill, pressed scale, accent border on press, and dimming of
/// disabled keys — is identical across the keypads; only the per-role palette differs,
/// which each `Role` provides.
struct KeypadKeyStyle<Role: KeypadKeyRole>: ButtonStyle {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    let role: Role

    func makeBody(configuration: Configuration) -> some View {
        let colors = role.colors(for: colorScheme)
        return configuration.label
            .foregroundStyle(isEnabled ? colors.foreground : Color.secondary.opacity(0.45))
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isEnabled ? (configuration.isPressed ? colors.pressedBackground : colors.background) : Color.secondary.opacity(0.12))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isEnabled ? (configuration.isPressed ? Color.accentColor.opacity(0.65) : colors.border) : Color.clear, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}

/// Shared style for the inline `✕` clear button that sits next to the slot display.
struct KeypadInlineButtonStyle: ButtonStyle {

    @Environment(\.colorScheme) private var colorScheme

    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .opacity(configuration.isPressed ? 0.68 : 1)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }

    private var foreground: Color {
        if colorScheme == .dark {
            return isEnabled ? .primary : .secondary.opacity(0.38)
        }
        return isEnabled ? .accentColor : .secondary.opacity(0.55)
    }
}
