//
//  KeypadSlotCursor.swift
//  CornucopiaSUI
//

import SwiftUI

/// A text-style insertion cursor for keypad slot displays (IPv4 octets, MAC bytes…).
///
/// Only the active slot shows the cursor, pulsing slowly. Inactive slots keep the glyph
/// at zero opacity so it still anchors the baseline the separators align to, without
/// rendering a visible cursor — one cursor on screen at a time.
struct KeypadSlotCursor: View {

    let color: Color
    let isActive: Bool
    let isPulsing: Bool

    var body: some View {
        Text(verbatim: "|")
            .foregroundStyle(color)
            .opacity(isActive ? (isPulsing ? 0.95 : 0.25) : 0)
            .animation(isActive ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isPulsing)
    }
}
