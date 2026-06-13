//
//  MACKeyboardInput.swift
//  CornucopiaSUI
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A domain-specific MAC address input with byte slots and a hex keypad.
///
/// - Important: Do not pair this control with `NetworkAwareTextField` or any other
///   field that mirrors the same MAC value. A `*KeyboardInput` is already the
///   visible value display, focus target, normalization boundary, keypad,
///   hardware-keyboard bridge, and submit surface. Rendering a matching field above
///   it creates two competing input controls for one value, breaks the mental model,
///   and usually leaves the keypad floating in the middle of unrelated layout. If an
///   app needs an OS-positioned keyboard, implement that as a real input method for
///   the field; do not compose a field and a `*KeyboardInput` side by side or one
///   above the other.
public struct MACKeyboardInput: View {

    public enum SeparatorStyle {
        case colon
        case dash
        case dot
        case compact

        var separator: String {
            switch self {
                case .colon: ":"
                case .dash: "-"
                case .dot: "."
                case .compact: ""
            }
        }
    }

    @Binding private var text: String
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isInputFocused: Bool
    @State private var isActiveSlotPulsing = false

    private let focusedBinding: FocusState<Bool>.Binding?
    private let validationStateBinding: Binding<NetworkAwareTextField.ValidationState>?
    private let separatorStyle: SeparatorStyle
    private let placeholder: String
    private let submitSystemImage: String
    private let autoFocus: Bool
    private let isSubmitEnabled: Bool
    private let onSubmit: (() -> Void)?

    public init(
        _ text: Binding<String>,
        focused: FocusState<Bool>.Binding? = nil,
        validationState: Binding<NetworkAwareTextField.ValidationState>? = nil,
        separatorStyle: SeparatorStyle = .colon,
        placeholder: String = CC_localized("MAC address"),
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.focusedBinding = focused
        self.validationStateBinding = validationState
        self.separatorStyle = separatorStyle
        self.placeholder = placeholder
        self.submitSystemImage = submitSystemImage
        self.autoFocus = autoFocus
        self.isSubmitEnabled = isSubmitEnabled
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 8) {
            display
            keypad
        }
        .padding(10)
        .background(.bar)
        .contentShape(Rectangle())
        .onTapGesture {
            requestFocus()
        }
        .task {
            if autoFocus {
                requestFocus()
            }
            normalizeBoundText()
            isActiveSlotPulsing = true
        }
        .onChange(of: text) {
            normalizeBoundText()
        }
        .CC_keypadHardwareInput(
            internalFocus: $isInputFocused,
            externalFocus: focusedBinding,
            handleKeyPress: handleKeyPress,
            handleDelete: deleteLastNibble,
            handleSubmit: submit,
            handlePaste: paste
        )
    }

    private var display: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    ForEach(0..<6, id: \.self) { index in
                        macByteCell(at: index)

                        if index < 5, separatorStyle != .compact {
                            Text(separatorStyle.separator)
                                .font(.system(.body, design: .monospaced).weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(width: separatorStyle == .dot && index.isOdd ? 14 : 10)
                                .opacity(separatorStyle == .dot && index.isMultiple(of: 2) ? 0 : 1)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(placeholder)
                .accessibilityValue(addressAccessibilityValue)

                HStack(spacing: 3) {
                    ForEach(0..<6, id: \.self) { index in
                        Capsule(style: .continuous)
                            .fill(byteMarkerColor(at: index))
                            .frame(maxWidth: .infinity)
                            .frame(height: 4)
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .padding(.vertical, 10)

            Button {
                clear()
            } label: {
                Image(systemName: "xmark")
                    .font(.callout.weight(.bold))
                    .frame(width: 44, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(KeypadInlineButtonStyle(isEnabled: !rawHex.isEmpty))
            .disabled(rawHex.isEmpty)
            .accessibilityLabel(CC_localized("Clear MAC address"))
        }
        .background(displayBackground)
    }

    /// The entered address read out for VoiceOver (the label override otherwise hides it).
    private var addressAccessibilityValue: String {
        rawHex.isEmpty ? CC_localized("empty") : text
    }

    private func macByteCell(at index: Int) -> some View {
        let value = byte(at: index)
        let isActive = index == activeByteIndex
        return VStack(alignment: .leading, spacing: 2) {
            Text("B\(index + 1)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(byteColor(at: index))

            HStack(spacing: 1) {
                if !value.isEmpty {
                    Text(value)
                        .foregroundStyle(.primary)
                }
                KeypadSlotCursor(color: byteColor(at: index), isActive: isActive, isPulsing: isActiveSlotPulsing)
                Spacer(minLength: 0)
            }
            .font(.system(.body, design: .monospaced).weight(.medium))
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func byteMarkerColor(at index: Int) -> Color {
        if index == activeByteIndex {
            return byteColor(at: index)
        }
        if !byte(at: index).isEmpty {
            return byteColor(at: index)
        }
        return Color.secondary.opacity(colorScheme == .dark ? 0.28 : 0.22)
    }

    private func byteColor(at index: Int) -> Color {
        index.isMultiple(of: 2) ? .green : .teal
    }

    private var displayBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(displayBorderColor, lineWidth: 1)
            }
    }

    private var displayBorderColor: Color {
        if rawHex.isEmpty {
            return Color.primary.opacity(0.16)
        }
        return canSubmit ? Color.green.opacity(0.65) : Color.orange.opacity(0.75)
    }

    private var keypad: some View {
        VStack(spacing: 6) {
            keypadRow(["1", "2", "3", "A", "B", "C"])
            keypadRow(["4", "5", "6", "D", "E", "F"])
            HStack(spacing: 6) {
                macKey("7", role: .digit)
                macKey("8", role: .digit)
                macKey("9", role: .digit)
                macKey("0", role: .zero)
                deleteKey
                submitKey
            }
        }
    }

    private func keypadRow(_ keys: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                macKey(key, role: key.first?.isNumber == true ? .digit : .hexLetter)
            }
        }
    }

    private func macKey(_ key: String, role: NetworkKeyboardKeyRole) -> some View {
        KeypadKey(title: key, role: role, isEnabled: rawHex.count < 12, accessibilityLabel: CC_localized("MAC \(key)")) {
            appendNibble(key)
        }
    }

    private var deleteKey: some View {
        Button {
            deleteLastNibble()
        } label: {
            Image(systemName: "delete.left")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(KeypadKeyStyle(role: NetworkKeyboardKeyRole.action))
        .disabled(rawHex.isEmpty)
        .accessibilityLabel(CC_localized("Delete"))
    }

    private var submitKey: some View {
        Button {
            submit()
        } label: {
            Image(systemName: submitSystemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(KeypadKeyStyle(role: canSubmit ? NetworkKeyboardKeyRole.submit : .action))
        .disabled(!canSubmit)
        .accessibilityLabel(CC_localized("Submit MAC address"))
    }

    private var rawHex: String {
        Self.normalizedMACHex(text)
    }

    private var activeByteIndex: Int {
        min(rawHex.count / 2, 5)
    }

    private var canSubmit: Bool {
        isSubmitEnabled && rawHex.count == 12 && isMACAddress(text) != nil
    }

    private func byte(at index: Int) -> String {
        let start = index * 2
        guard rawHex.count > start else { return "" }
        return String(rawHex.dropFirst(start).prefix(2))
    }

    private func appendNibble(_ nibble: String) {
        guard rawHex.count < 12 else { return }
        guard let character = nibble.first, character.isHexDigit else { return }
        text = Self.formattedMAC(rawHex + String(character).uppercased(), separatorStyle: separatorStyle)
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func deleteLastNibble() {
        var hex = rawHex
        guard !hex.isEmpty else { return }
        hex.removeLast()
        text = Self.formattedMAC(hex, separatorStyle: separatorStyle)
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func clear() {
        guard !rawHex.isEmpty else { return }
        text = ""
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func submit() {
        guard canSubmit else { return }
        onSubmit?()
        isInputFocused = false
        focusedBinding?.wrappedValue = false
        feedback()
    }

    private func handleKeyPress(_ characters: String) -> Bool {
        var handled = false
        for character in characters {
            if character.isHexDigit {
                appendNibble(String(character).uppercased())
                handled = true
            }
        }
        return handled
    }

    /// Replaces the value with the normalized clipboard contents (overwrites rather than appends).
    private func paste() -> Bool {
        guard let pasted = keypadPasteboardString else { return false }
        guard !Self.normalizedMACHex(pasted).isEmpty else { return false }
        text = Self.formattedMAC(pasted, separatorStyle: separatorStyle)
        updateValidationState()
        requestFocus()
        feedback()
        return true
    }

    private func normalizeBoundText() {
        let formatted = Self.formattedMAC(rawHex, separatorStyle: separatorStyle)
        if text != formatted {
            text = formatted
        }
        updateValidationState()
    }

    private func updateValidationState() {
        validationStateBinding?.wrappedValue = rawHex.isEmpty
            ? .empty
            : canSubmit ? .macAddress(text, format: separatorStyle.validationFormat) : .invalid(text)
    }

    private func requestFocus() {
        isInputFocused = true
        focusedBinding?.wrappedValue = true
    }

    private func feedback() {
#if canImport(UIKit)
        UIDevice.current.playInputClick()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
    }

    /// Returns uppercase hex digits only, truncated to 12 MAC nibbles.
    public static func normalizedMACHex(_ input: String) -> String {
        String(input.uppercased().filter(\.isHexDigit).prefix(12))
    }

    /// Formats raw MAC hex according to the selected separator style.
    public static func formattedMAC(_ input: String, separatorStyle: SeparatorStyle = .colon) -> String {
        let hex = normalizedMACHex(input)
        switch separatorStyle {
            case .colon, .dash:
                return hex.chunked(every: 2).joined(separator: separatorStyle.separator)
            case .dot:
                return hex.chunked(every: 4).joined(separator: ".")
            case .compact:
                return hex
        }
    }
}

private extension MACKeyboardInput.SeparatorStyle {
    var validationFormat: String {
        switch self {
            case .colon: "IEEE 802"
            case .dash: "Windows"
            case .dot: "Cisco"
            case .compact: "Compact"
        }
    }
}

