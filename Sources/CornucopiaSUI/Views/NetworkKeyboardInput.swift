//
//  NetworkKeyboardInput.swift
//  CornucopiaSUI
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A domain-specific IPv4 input with octet slots and a numeric keypad.
public struct IPv4KeyboardInput: View {

    @Binding private var text: String
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isInputFocused: Bool
    @State private var isActiveSlotPulsing = false

    private let focusedBinding: FocusState<Bool>.Binding?
    private let validationStateBinding: Binding<NetworkAwareTextField.ValidationState>?
    private let placeholder: String
    private let submitSystemImage: String
    private let autoFocus: Bool
    private let isSubmitEnabled: Bool
    private let onSubmit: (() -> Void)?

    public init(
        _ text: Binding<String>,
        focused: FocusState<Bool>.Binding? = nil,
        validationState: Binding<NetworkAwareTextField.ValidationState>? = nil,
        placeholder: String = "IPv4 address",
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.focusedBinding = focused
        self.validationStateBinding = validationState
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
        .onChange(of: text) { _ in
            normalizeBoundText()
        }
        .networkKeyboardInput(
            internalFocus: $isInputFocused,
            externalFocus: focusedBinding,
            handleKeyPress: handleKeyPress,
            handleDelete: deleteLastCharacter,
            handleSubmit: submit
        )
    }

    private var display: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    ForEach(0..<4, id: \.self) { index in
                        ipv4OctetCell(at: index)

                        if index < 3 {
                            Text(".")
                                .font(.system(.body, design: .monospaced).weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 14)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(placeholder)

                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule(style: .continuous)
                            .fill(octetMarkerColor(at: index))
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
            .buttonStyle(NetworkInlineButtonStyle(isEnabled: !text.isEmpty))
            .disabled(text.isEmpty)
            .accessibilityLabel("Clear IPv4 address")
        }
        .background(displayBackground)
    }

    private func ipv4OctetCell(at index: Int) -> some View {
        let value = octet(at: index)
        let isActive = index == activeOctetIndex

        return VStack(alignment: .leading, spacing: 2) {
            Text("OCT \(index + 1)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(octetColor(at: index))

            HStack(spacing: 1) {
                if !value.isEmpty {
                    Text(value)
                        .foregroundStyle(octetTextColor(value))
                }
                NetworkSlotCursor(color: octetColor(at: index), isActive: isActive, isPulsing: isActiveSlotPulsing)
                Spacer(minLength: 0)
            }
            .font(.system(.body, design: .monospaced).weight(.medium))
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func octetMarkerColor(at index: Int) -> Color {
        if index == activeOctetIndex {
            return octetColor(at: index)
        }
        if !octet(at: index).isEmpty {
            return octetIsValid(at: index) ? octetColor(at: index) : .red
        }
        return Color.secondary.opacity(colorScheme == .dark ? 0.28 : 0.22)
    }

    private func octetTextColor(_ octet: String) -> Color {
        guard !octet.isEmpty else { return .secondary }
        guard let value = Int(octet), value <= 255 else { return .red }
        return .primary
    }

    private func octetColor(at index: Int) -> Color {
        switch index {
            case 0: .blue
            case 1: .teal
            case 2: .indigo
            default: .green
        }
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
        if text.isEmpty {
            return Color.primary.opacity(0.16)
        }
        return canSubmit ? Color.blue.opacity(0.65) : Color.orange.opacity(0.75)
    }

    private var keypad: some View {
        VStack(spacing: 6) {
            keypadRow(["1", "2", "3"])
            keypadRow(["4", "5", "6"])
            keypadRow(["7", "8", "9"])

            HStack(spacing: 6) {
                actionKey("arrow.right.to.line", role: canAdvanceOctet ? .separator : .action, accessibilityLabel: "Next octet") {
                    advanceOctet()
                }
                networkKey("0", role: .digit)
                deleteKey
                submitKey
            }
        }
    }

    private func keypadRow(_ keys: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                networkKey(key, role: .digit)
            }
        }
    }

    private func networkKey(_ key: String, role: NetworkKeyboardKeyRole) -> some View {
        Button {
            appendDigit(key)
        } label: {
            Text(key)
                .font(.title3.monospaced().weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(NetworkKeyboardKeyStyle(role: role))
        .disabled(!canAppendDigit(key))
        .accessibilityLabel("IPv4 \(key)")
    }

    private func actionKey(_ systemImage: String, role: NetworkKeyboardKeyRole, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(NetworkKeyboardKeyStyle(role: role))
        .disabled(role == .action || !canAdvanceOctet)
        .accessibilityLabel(accessibilityLabel)
    }

    private var deleteKey: some View {
        Button {
            deleteLastCharacter()
        } label: {
            Image(systemName: "delete.left")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(NetworkKeyboardKeyStyle(role: .action))
        .disabled(text.isEmpty)
        .accessibilityLabel("Delete")
    }

    private var submitKey: some View {
        Button {
            submit()
        } label: {
            Image(systemName: submitSystemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(NetworkKeyboardKeyStyle(role: canSubmit ? .submit : .action))
        .disabled(!canSubmit)
        .accessibilityLabel("Submit IPv4 address")
    }

    private var canSubmit: Bool {
        isSubmitEnabled && isIPv4(text)
    }

    private var parts: [String] {
        if text.isEmpty { return [""] }
        return text.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
    }

    private var activeOctetIndex: Int {
        min(max(parts.count - 1, 0), 3)
    }

    private var canAdvanceOctet: Bool {
        guard activeOctetIndex < 3 else { return false }
        guard !text.hasSuffix(".") else { return false }
        guard !octet(at: activeOctetIndex).isEmpty else { return false }
        return true
    }

    private func octet(at index: Int) -> String {
        guard parts.indices.contains(index) else { return "" }
        return parts[index]
    }

    private func octetIsValid(at index: Int) -> Bool {
        guard let value = Int(octet(at: index)) else { return false }
        return value <= 255
    }

    private func canAppendDigit(_ digit: String) -> Bool {
        guard digit.count == 1, digit.first?.isNumber == true else { return false }
        guard activeOctetIndex < 4 else { return false }
        let current = octet(at: activeOctetIndex)
        guard current.count < 3 else { return false }
        if let value = Int(current + digit), value > 255 { return false }
        return true
    }

    private func appendDigit(_ digit: String) {
        guard canAppendDigit(digit) else { return }
        let index = activeOctetIndex
        var currentParts = parts
        while currentParts.count <= index {
            currentParts.append("")
        }
        currentParts[index].append(digit)
        var newText = currentParts.prefix(4).joined(separator: ".")
        if index < 3, currentParts[index].count == 3 {
            newText.append(".")
        }
        text = newText
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func advanceOctet() {
        guard canAdvanceOctet else { return }
        text.append(".")
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func deleteLastCharacter() {
        guard !text.isEmpty else { return }
        text.removeLast()
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func clear() {
        guard !text.isEmpty else { return }
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
            if character.isNumber {
                appendDigit(String(character))
                handled = true
            } else if character == "." {
                advanceOctet()
                handled = true
            }
        }
        return handled
    }

    private func normalizeBoundText() {
        let normalized = Self.normalizedIPv4Draft(text)
        if text != normalized {
            text = normalized
        }
        updateValidationState()
    }

    private func updateValidationState() {
        validationStateBinding?.wrappedValue = text.isEmpty
            ? .empty
            : canSubmit ? .ipv4(text, hostname: nil) : .invalid(text)
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

    /// Keeps only IPv4 draft characters, max four octets and three digits per octet.
    public static func normalizedIPv4Draft(_ input: String) -> String {
        let rawParts = input.filter { $0.isNumber || $0 == "." }
            .split(separator: ".", omittingEmptySubsequences: false)
            .prefix(4)
            .map { String($0.prefix(3)) }
        return rawParts.joined(separator: ".")
    }
}

/// A domain-specific MAC address input with byte slots and a hex keypad.
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
        placeholder: String = "MAC address",
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
        .onChange(of: text) { _ in
            normalizeBoundText()
        }
        .networkKeyboardInput(
            internalFocus: $isInputFocused,
            externalFocus: focusedBinding,
            handleKeyPress: handleKeyPress,
            handleDelete: deleteLastNibble,
            handleSubmit: submit
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel(placeholder)

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
            .buttonStyle(NetworkInlineButtonStyle(isEnabled: !rawHex.isEmpty))
            .disabled(rawHex.isEmpty)
            .accessibilityLabel("Clear MAC address")
        }
        .background(displayBackground)
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
                NetworkSlotCursor(color: byteColor(at: index), isActive: isActive, isPulsing: isActiveSlotPulsing)
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
                macKey("0", role: .digit)
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
        Button {
            appendNibble(key)
        } label: {
            Text(key)
                .font(.title3.monospaced().weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(NetworkKeyboardKeyStyle(role: role))
        .disabled(rawHex.count >= 12)
        .accessibilityLabel("MAC \(key)")
    }

    private var deleteKey: some View {
        Button {
            deleteLastNibble()
        } label: {
            Image(systemName: "delete.left")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(NetworkKeyboardKeyStyle(role: .action))
        .disabled(rawHex.isEmpty)
        .accessibilityLabel("Delete")
    }

    private var submitKey: some View {
        Button {
            submit()
        } label: {
            Image(systemName: submitSystemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(NetworkKeyboardKeyStyle(role: canSubmit ? .submit : .action))
        .disabled(!canSubmit)
        .accessibilityLabel("Submit MAC address")
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

/// A text-style insertion cursor for the network slot displays.
///
/// Only the active slot shows the cursor, pulsing slowly (mirroring
/// `VINKeyboardInput`). Inactive slots keep the glyph at zero opacity so it still
/// anchors the baseline the separators align to, without rendering a visible cursor.
private struct NetworkSlotCursor: View {

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

private enum NetworkKeyboardKeyRole {
    case digit
    case hexLetter
    case separator
    case action
    case submit

    func foreground(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .digit:
                Color.primary
            case .hexLetter:
                colorScheme == .dark ? Color(red: 0.78, green: 1, blue: 0.86) : Color.green
            case .separator:
                colorScheme == .dark ? Color(red: 0.78, green: 0.9, blue: 1) : Color.blue
            case .action:
                Color.primary.opacity(0.76)
            case .submit:
                Color.white
        }
    }

    func background(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .digit:
                Color.primary.opacity(0.08)
            case .hexLetter:
                colorScheme == .dark ? Color.green.opacity(0.2) : Color.green.opacity(0.14)
            case .separator:
                colorScheme == .dark ? Color.blue.opacity(0.22) : Color.blue.opacity(0.14)
            case .action:
                Color.secondary.opacity(0.22)
            case .submit:
                Color.accentColor
        }
    }

    func pressedBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .digit:
                Color.primary.opacity(0.22)
            case .hexLetter:
                colorScheme == .dark ? Color.green.opacity(0.32) : Color.green.opacity(0.26)
            case .separator:
                colorScheme == .dark ? Color.blue.opacity(0.34) : Color.blue.opacity(0.26)
            case .action:
                Color.secondary.opacity(0.34)
            case .submit:
                Color.accentColor.opacity(0.78)
        }
    }

    func border(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .digit:
                Color.primary.opacity(0.06)
            case .hexLetter:
                Color.green.opacity(colorScheme == .dark ? 0.6 : 0.25)
            case .separator:
                Color.blue.opacity(colorScheme == .dark ? 0.6 : 0.25)
            case .action:
                Color.secondary.opacity(0.18)
            case .submit:
                Color.accentColor.opacity(0.85)
        }
    }
}

private struct NetworkKeyboardKeyStyle: ButtonStyle {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    let role: NetworkKeyboardKeyRole

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? role.foreground(for: colorScheme) : Color.secondary.opacity(0.45))
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isEnabled ? keyBackground(isPressed: configuration.isPressed) : Color.secondary.opacity(0.12))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isEnabled ? keyBorder(isPressed: configuration.isPressed) : Color.clear, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }

    private func keyBackground(isPressed: Bool) -> Color {
        isPressed ? role.pressedBackground(for: colorScheme) : role.background(for: colorScheme)
    }

    private func keyBorder(isPressed: Bool) -> Color {
        isPressed ? Color.accentColor.opacity(0.65) : role.border(for: colorScheme)
    }
}

private struct NetworkInlineButtonStyle: ButtonStyle {

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

private extension View {

    @ViewBuilder
    func networkKeyboardInput(
        internalFocus: FocusState<Bool>.Binding,
        externalFocus: FocusState<Bool>.Binding?,
        handleKeyPress: @escaping (String) -> Bool,
        handleDelete: @escaping () -> Void,
        handleSubmit: @escaping () -> Void
    ) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            if let externalFocus {
                self
                    .focusable()
                    .focused(externalFocus)
                    .networkKeyPressHandler(
                        handleKeyPress: handleKeyPress,
                        handleDelete: handleDelete,
                        handleSubmit: handleSubmit
                    )
            } else {
                self
                    .focusable()
                    .focused(internalFocus)
                    .networkKeyPressHandler(
                        handleKeyPress: handleKeyPress,
                        handleDelete: handleDelete,
                        handleSubmit: handleSubmit
                    )
            }
        } else {
            self
        }
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    func networkKeyPressHandler(
        handleKeyPress: @escaping (String) -> Bool,
        handleDelete: @escaping () -> Void,
        handleSubmit: @escaping () -> Void
    ) -> some View {
        onKeyPress(phases: .down) { press in
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
    }
}

private extension String {
    func chunked(every size: Int) -> [String] {
        guard size > 0 else { return [self] }
        var chunks: [String] = []
        var index = startIndex
        while index < endIndex {
            let next = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[index..<next]))
            index = next
        }
        return chunks
    }
}

private extension Int {
    var isOdd: Bool {
        !isMultiple(of: 2)
    }
}

private struct NetworkKeyboardInputPreview: View {

    enum Scenario {
        case ipv4Empty
        case ipv4Partial
        case ipv4Complete
        case macEmpty
        case macPartial
        case macComplete
        case dark
    }

    @State private var value: String

    private let scenario: Scenario

    init(_ scenario: Scenario) {
        self.scenario = scenario
        self._value = State(initialValue: Self.initialValue(for: scenario))
    }

    var body: some View {
        VStack(spacing: 16) {
            previewHeader
            Spacer()

            switch scenario {
                case .ipv4Empty, .ipv4Partial, .ipv4Complete:
                    IPv4KeyboardInput($value) {}
                case .macEmpty, .macPartial, .macComplete:
                    MACKeyboardInput($value) {}
                case .dark:
                    MACKeyboardInput($value, separatorStyle: .dash) {}
            }
        }
        .padding()
        .frame(width: 390, height: 560)
        .background(Color.gray.opacity(0.12))
        .preferredColorScheme(scenario == .dark ? .dark : nil)
    }

    private var previewHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(value.isEmpty ? "Empty" : value)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: String {
        switch scenario {
            case .ipv4Empty:
                "IPv4 Keyboard"
            case .ipv4Partial:
                "IPv4 Partial"
            case .ipv4Complete:
                "IPv4 Complete"
            case .macEmpty:
                "MAC Keyboard"
            case .macPartial:
                "MAC Partial"
            case .macComplete:
                "MAC Complete"
            case .dark:
                "MAC Keyboard Dark"
        }
    }

    private static func initialValue(for scenario: Scenario) -> String {
        switch scenario {
            case .ipv4Empty:
                ""
            case .ipv4Partial:
                "192.168"
            case .ipv4Complete:
                "192.168.4.42"
            case .macEmpty:
                ""
            case .macPartial:
                "A4:C1:38"
            case .macComplete:
                "A4:C1:38:2F:90:01"
            case .dark:
                "A4-C1-38"
        }
    }
}

#Preview("IPv4 Keyboard Empty") {
    NetworkKeyboardInputPreview(.ipv4Empty)
}

#Preview("IPv4 Keyboard Partial") {
    NetworkKeyboardInputPreview(.ipv4Partial)
}

#Preview("IPv4 Keyboard Complete") {
    NetworkKeyboardInputPreview(.ipv4Complete)
}

#Preview("MAC Keyboard Empty") {
    NetworkKeyboardInputPreview(.macEmpty)
}

#Preview("MAC Keyboard Partial") {
    NetworkKeyboardInputPreview(.macPartial)
}

#Preview("MAC Keyboard Complete") {
    NetworkKeyboardInputPreview(.macComplete)
}

#Preview("MAC Keyboard Dark") {
    NetworkKeyboardInputPreview(.dark)
}
