//
//  IPv4KeyboardInput.swift
//  CornucopiaSUI
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A domain-specific IPv4 input with octet slots and a numeric keypad.
///
/// - Important: Do not pair this control with `NetworkAwareTextField` or any other
///   field that mirrors the same IPv4 value. A `*KeyboardInput` is already the
///   visible value display, focus target, normalization boundary, keypad,
///   hardware-keyboard bridge, and submit surface. Rendering a matching field above
///   it creates two competing input controls for one value, breaks the mental model,
///   and usually leaves the keypad floating in the middle of unrelated layout. If an
///   app needs an OS-positioned keyboard, implement that as a real input method for
///   the field; do not compose a field and a `*KeyboardInput` side by side or one
///   above the other.
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
        placeholder: String = CC_localized("IPv4 address"),
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
        .CC_keypadHardwareInput(
            internalFocus: $isInputFocused,
            externalFocus: focusedBinding,
            handleKeyPress: handleKeyPress,
            handleDelete: deleteLastCharacter,
            handleSubmit: submit,
            handlePaste: paste
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(placeholder)
                .accessibilityValue(addressAccessibilityValue)

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
            .buttonStyle(KeypadInlineButtonStyle(isEnabled: !text.isEmpty))
            .disabled(text.isEmpty)
            .accessibilityLabel(CC_localized("Clear IPv4 address"))
        }
        .background(displayBackground)
    }

    /// The entered address read out for VoiceOver (the label override otherwise hides it).
    private var addressAccessibilityValue: String {
        text.isEmpty ? CC_localized("empty") : text
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
                KeypadSlotCursor(color: octetColor(at: index), isActive: isActive, isPulsing: isActiveSlotPulsing)
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
                networkKey("0", role: .zero)
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
        KeypadKey(
            title: key,
            role: role,
            isEnabled: canAppendDigit(key),
            alternates: Self.maskAlternates[key] ?? [],
            accessibilityLabel: CC_localized("IPv4 \(key)"),
            onTap: { appendDigit(key) },
            onSelectAlternate: { selectOctet($0) }
        )
    }

    private func actionKey(_ systemImage: String, role: NetworkKeyboardKeyRole, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(KeypadKeyStyle(role: role))
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
        .buttonStyle(KeypadKeyStyle(role: NetworkKeyboardKeyRole.action))
        .disabled(text.isEmpty)
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
        .accessibilityLabel(CC_localized("Submit IPv4 address"))
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

    /// Subnet-mask octets offered on long-press, grouped by their leading digit so each
    /// alternate stays consistent with the key that's held (e.g. hold `2` → 224…255).
    static let maskAlternates: [String: [String]] = [
        "1": ["128", "192"],
        "2": ["224", "240", "248", "252", "254", "255"]
    ]

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

    /// Replaces the active octet with a long-press preset (a mask octet) and advances.
    private func selectOctet(_ value: String) {
        let index = activeOctetIndex
        var currentParts = parts
        while currentParts.count <= index {
            currentParts.append("")
        }
        currentParts[index] = value
        var newText = currentParts.prefix(4).joined(separator: ".")
        if index < 3 {
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

    /// Replaces the value with the normalized clipboard contents (overwrites rather than appends).
    private func paste() -> Bool {
        guard let pasted = keypadPasteboardString else { return false }
        let normalized = Self.normalizedIPv4Draft(pasted)
        guard !normalized.isEmpty else { return false }
        text = normalized
        updateValidationState()
        requestFocus()
        feedback()
        return true
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

