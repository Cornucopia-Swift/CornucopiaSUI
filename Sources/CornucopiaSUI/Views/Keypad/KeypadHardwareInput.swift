//
//  KeypadHardwareInput.swift
//  CornucopiaSUI
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The current pasteboard string, across platforms.
var keypadPasteboardString: String? {
#if canImport(UIKit)
    UIPasteboard.general.string
#elseif canImport(AppKit)
    NSPasteboard.general.string(forType: .string)
#else
    nil
#endif
}

extension View {

    /// Wires a domain keypad up to a hardware keyboard: focus, character entry, delete,
    /// return, and clipboard paste.
    ///
    /// These keypads are custom focusable views (not `UITextField`), so paste has to be
    /// intercepted by hand. Command/Control combos are checked **first**: `⌘V` / `Ctrl+V`
    /// triggers `handlePaste`, every other shortcut is swallowed so a shortcut letter can
    /// never leak into the value (critical for the hex keypad, where `A`–`F` overlap with
    /// shortcut letters).
    @ViewBuilder
    func CC_keypadHardwareInput(
        internalFocus: FocusState<Bool>.Binding,
        externalFocus: FocusState<Bool>.Binding? = nil,
        handleKeyPress: @escaping (String) -> Bool,
        handleDelete: @escaping () -> Void,
        handleSubmit: @escaping () -> Void,
        handlePaste: @escaping () -> Bool
    ) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            self
                .focusable()
                .focused(externalFocus ?? internalFocus)
                .onKeyPress(phases: .down) { press in
                    if press.modifiers.contains(.command) || press.modifiers.contains(.control) {
                        if press.key.character == "v" {
                            return handlePaste() ? .handled : .ignored
                        }
                        return .ignored
                    }
                    if press.key == .delete {
                        handleDelete()
                        return .handled
                    }
                    if press.key == .return {
                        handleSubmit()
                        return .handled
                    }
                    return handleKeyPress(press.characters) ? .handled : .ignored
                }
        } else {
            self
        }
    }
}
