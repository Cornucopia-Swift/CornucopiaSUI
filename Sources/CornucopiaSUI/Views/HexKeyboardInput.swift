//
//  HexKeyboardInput.swift
//  CornucopiaSUI
//

import SwiftUI
#if canImport(UIKit)
import AudioToolbox
import UIKit
#endif

/// A reusable SwiftUI input control for entering hexadecimal payloads.
///
/// `HexKeyboardInput` keeps its bound text normalized to uppercase hex digits while
/// presenting the value as grouped bytes. It supports touch input through an
/// on-screen hex keypad, hardware keyboard entry, single-nibble deletion, clearing
/// the current payload, and an optional submit action.
public struct HexKeyboardInput: View {

    /// Semantic action shown in the keyboard return-key position.
    public enum ReturnKey {
        case hidden
        case next
        case done
        case send
    }

    @Binding private var text: String
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isInputFocused: Bool
    @State private var isCaretVisible = true
#if canImport(UIKit)
    @State private var feedbackPerformer = HexKeyboardFeedbackPerformer()
#endif

    private let placeholder: String
    private let submitSystemImage: String
    private let returnKey: ReturnKey
    private let autoFocus: Bool
    private let isSubmitEnabled: Bool
    private let minimumNibbleCount: Int
    private let requiresEvenNibbleCount: Bool
    private let onSubmit: (() -> Void)?

    /// Creates a hex payload input with a built-in keypad and optional submit action.
    ///
    /// - Parameters:
    ///   - text: The bound payload text. The control normalizes this value to uppercase
    ///     hexadecimal digits and removes separators such as spaces or `0x` prefixes.
    ///   - placeholder: Placeholder text shown while the payload is empty.
    ///   - submitSystemImage: SF Symbol used for the submit key.
    ///   - showsSubmitKey: When `false`, hides the submit key for inline editing contexts.
    ///   - returnKey: Semantic action shown in the return-key position. When omitted,
    ///     `showsSubmitKey` controls whether a send key or no return key is shown.
    ///   - autoFocus: When `true`, the control claims keyboard focus when it appears.
    ///   - isSubmitEnabled: External enablement flag for submit, useful while a parent
    ///     operation is busy or unavailable.
    ///   - minimumNibbleCount: Minimum number of hex nibbles required before submit is enabled.
    ///   - requiresEvenNibbleCount: When `true`, submit is enabled only for full-byte payloads.
    ///   - onSubmit: Called when the user taps the submit key or presses Return.
    public init(
        _ text: Binding<String>,
        placeholder: String = "Hex payload",
        submitSystemImage: String = "paperplane.fill",
        showsSubmitKey: Bool = true,
        returnKey: ReturnKey? = nil,
        autoFocus: Bool = true,
        isSubmitEnabled: Bool = true,
        minimumNibbleCount: Int = 1,
        requiresEvenNibbleCount: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.submitSystemImage = submitSystemImage
        self.returnKey = returnKey ?? (showsSubmitKey ? .send : .hidden)
        self.autoFocus = autoFocus
        self.isSubmitEnabled = isSubmitEnabled
        self.minimumNibbleCount = max(0, minimumNibbleCount)
        self.requiresEvenNibbleCount = requiresEvenNibbleCount
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
        .focused($isInputFocused)
        .onTapGesture {
            isInputFocused = true
        }
        .task {
            if autoFocus {
                isInputFocused = true
            }
            normalizeBoundText()
        }
        .onChange(of: text) { _ in
            normalizeBoundText()
        }
        .CC_keypadHardwareInput(
            internalFocus: $isInputFocused,
            handleKeyPress: handleKeyPress,
            handleDelete: deleteLastNibble,
            handleSubmit: submit,
            handlePaste: paste
        )
    }

    private var display: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        byteDisplay
                    }

                    if !text.isEmpty {
                        caret
                    }
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .padding(.vertical, 10)
            }

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
            .accessibilityLabel("Clear hex payload")
        }
        .background(displayBackground)
    }

    private var displayBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.16), lineWidth: 1)
            }
    }

    private var byteDisplay: some View {
        HStack(spacing: 0) {
            let bytes = Self.groupedHexBytes(text)
            ForEach(Array(bytes.enumerated()), id: \.offset) { index, byte in
                if index > 0 {
                    Text(Self.byteSeparator)
                        .foregroundStyle(.secondary)
                }
                Text(byte)
                    .foregroundStyle(byteForegroundStyle(at: index))
            }
        }
        .lineLimit(1)
    }

    private func byteForegroundStyle(at index: Int) -> Color {
        index.isMultiple(of: 2) ? .primary : .primary.opacity(0.62)
    }

    private var caret: some View {
        Capsule(style: .continuous)
            .fill(caretColor)
            .frame(width: 2, height: 20)
            .opacity(isCaretVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    isCaretVisible.toggle()
                }
            }
    }

    private var caretColor: Color {
        colorScheme == .dark ? .primary : .accentColor
    }

    private var keypad: some View {
        VStack(spacing: 6) {
            keypadRow(["1", "2", "3", "A", "B", "C"])
            keypadRow(["4", "5", "6", "D", "E", "F"])
            keypadBottomRow
        }
    }

    private var keypadBottomRow: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 6
            let keyWidth = (geometry.size.width - (spacing * 5)) / 6
            HStack(spacing: spacing) {
                hexKey("7")
                    .frame(width: keyWidth)
                hexKey("8")
                    .frame(width: keyWidth)
                hexKey("9")
                    .frame(width: keyWidth)
                hexKey("0", role: .zero)
                    .frame(width: keyWidth)
                deleteKey
                    .frame(width: showsReturnKey ? keyWidth : (keyWidth * 2) + spacing)
                if showsReturnKey {
                    returnKeyButton
                        .frame(width: keyWidth)
                }
            }
        }
        .frame(height: 42)
    }

    private func keypadRow(_ keys: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                hexKey(key, role: key.isHexLetter ? .hexLetter : .digit)
            }
        }
    }

    private func hexKey(_ key: String, role: HexKeyboardKeyRole = .digit) -> some View {
        KeypadKey(title: key, role: role, accessibilityLabel: "Hex \(key)") {
            append(key)
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
        .buttonStyle(KeypadKeyStyle(role: HexKeyboardKeyRole.action))
        .disabled(text.isEmpty)
        .accessibilityLabel("Delete")
    }

    private var returnKeyButton: some View {
        Button {
            submit()
        } label: {
            Image(systemName: returnKeySystemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(KeypadKeyStyle(role: canSubmit ? HexKeyboardKeyRole.submit : .action))
        .disabled(!canSubmit)
        .accessibilityLabel(returnKeyAccessibilityLabel)
    }

    private var canSubmit: Bool {
        isSubmitEnabled
            && showsReturnKey
            && normalizedNibbleCount >= minimumNibbleCount
            && (!requiresEvenNibbleCount || normalizedNibbleCount.isMultiple(of: 2))
            && onSubmit != nil
    }

    private var showsReturnKey: Bool {
        if case .hidden = returnKey {
            return false
        }
        return true
    }

    private var returnKeySystemImage: String {
        switch returnKey {
            case .hidden:
                submitSystemImage
            case .next:
                "arrow.right"
            case .done:
                "keyboard.chevron.compact.down"
            case .send:
                submitSystemImage
        }
    }

    private var returnKeyAccessibilityLabel: String {
        switch returnKey {
            case .hidden:
                "Return"
            case .next:
                "Next"
            case .done:
                "Done"
            case .send:
                "Send hex payload"
        }
    }

    private var normalizedNibbleCount: Int {
        Self.normalizedHex(text).count
    }

    private func append(_ nibble: String) {
        var hex = Self.normalizedHex(text)
        hex.append(nibble)
        text = hex
        isInputFocused = true
        performFeedback()
    }

    private func deleteLastNibble() {
        var hex = Self.normalizedHex(text)
        guard !hex.isEmpty else { return }
        hex.removeLast()
        text = hex
        isInputFocused = true
        performFeedback()
    }

    private func clear() {
        guard !text.isEmpty else { return }
        text = ""
        isInputFocused = true
        performFeedback()
    }

    private func submit() {
        guard canSubmit else { return }
        onSubmit?()
        isInputFocused = true
        performFeedback()
    }

    private func handleKeyPress(_ characters: String) -> Bool {
        for character in characters {
            if character.isHexDigit {
                append(String(character).uppercased())
            }
        }
        return characters.contains(where: \.isHexDigit)
    }

    /// Replaces the value with the normalized clipboard contents (overwrites rather than appends).
    private func paste() -> Bool {
        guard let pasted = keypadPasteboardString else { return false }
        let normalized = Self.normalizedHex(pasted)
        guard !normalized.isEmpty else { return false }
        text = normalized
        isInputFocused = true
        performFeedback()
        return true
    }

    private func normalizeBoundText() {
        let normalized = Self.normalizedHex(text)
        guard text != normalized else { return }
        text = normalized
    }

    private func performFeedback() {
#if canImport(UIKit)
        feedbackPerformer.perform()
#endif
    }

    /// Returns only uppercase hexadecimal digits from `input`.
    ///
    /// The normalization removes `0x` prefixes and any non-hex characters, making it
    /// suitable for display and keypad editing.
    public static func normalizedHex(_ input: String) -> String {
        input
            .replacingOccurrences(of: "0x", with: "", options: .caseInsensitive)
            .filter(\.isHexDigit)
            .uppercased()
    }

    /// Converts hex text into bytes.
    ///
    /// Whitespace and commas are accepted as separators. Invalid non-separator
    /// characters return `nil`. When `requiresEvenNibbleCount` is `false`, an odd
    /// nibble count is left-padded with `0` for conversion.
    public static func byteArray(from input: String, requiresEvenNibbleCount: Bool = true) -> [UInt8]? {
        var hex = ""
        let payload = input.replacingOccurrences(of: "0x", with: "", options: .caseInsensitive)

        for character in payload {
            if character.isHexDigit {
                hex.append(character)
            } else if character.isWhitespace || character == "," {
                continue
            } else {
                return nil
            }
        }

        guard !hex.isEmpty else { return nil }
        if hex.count % 2 == 1 {
            guard !requiresEvenNibbleCount else { return nil }
            hex = "0" + hex
        }

        var bytes: [UInt8] = []
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        return bytes
    }

    /// Formats hex text as byte groups separated by `byteSeparator`.
    public static func groupedHex(_ input: String) -> String {
        groupedHexBytes(input).joined(separator: byteSeparator)
    }

    /// Splits normalized hex text into one- or two-character byte groups.
    public static func groupedHexBytes(_ input: String) -> [String] {
        normalizedHex(input).reduce(into: [String]()) { result, character in
            if let lastIndex = result.indices.last, result[lastIndex].count < 2 {
                result[lastIndex].append(character)
            } else {
                result.append(String(character))
            }
        }
    }

    /// Thin-space separator used when rendering grouped bytes.
    public static let byteSeparator = "\u{2009}"
}

private enum HexKeyboardKeyRole {
    case digit
    case hexLetter
    case zero
    case action
    case submit

    func tint(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark, self == .hexLetter {
            return Color(red: 0.78, green: 0.86, blue: 1)
        }

        return switch self {
            case .digit:
                Color.primary
            case .hexLetter:
                Color.accentColor
            case .zero:
                Color.white
            case .action:
                Color.primary.opacity(0.76)
            case .submit:
                Color.white
        }
    }

    func background(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark, self == .hexLetter {
            return Color(red: 0.15, green: 0.18, blue: 0.25)
        }

        return switch self {
            case .digit:
                Color.primary.opacity(0.08)
            case .hexLetter:
                Color.accentColor.opacity(0.16)
            case .zero:
                Color.accentColor
            case .action:
                Color.secondary.opacity(0.22)
            case .submit:
                Color.accentColor
        }
    }

    func pressedBackground(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark, self == .hexLetter {
            return Color(red: 0.2, green: 0.25, blue: 0.36)
        }

        return switch self {
            case .digit:
                Color.primary.opacity(0.22)
            case .hexLetter:
                Color.accentColor.opacity(0.28)
            case .zero:
                Color.accentColor.opacity(0.78)
            case .action:
                Color.secondary.opacity(0.34)
            case .submit:
                Color.accentColor.opacity(0.78)
        }
    }

    func border(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark, self == .hexLetter {
            return Color(red: 0.42, green: 0.52, blue: 0.7)
        }

        return switch self {
            case .digit:
                Color.primary.opacity(0.06)
            case .hexLetter:
                Color.accentColor.opacity(0.2)
            case .zero:
                Color.accentColor.opacity(0.85)
            case .action:
                Color.secondary.opacity(0.18)
            case .submit:
                Color.accentColor.opacity(0.85)
        }
    }
}

extension HexKeyboardKeyRole: KeypadKeyRole {
    func colors(for colorScheme: ColorScheme) -> KeypadKeyColors {
        KeypadKeyColors(
            foreground: tint(for: colorScheme),
            background: background(for: colorScheme),
            pressedBackground: pressedBackground(for: colorScheme),
            border: border(for: colorScheme)
        )
    }
}

#if canImport(UIKit)
@MainActor
private final class HexKeyboardFeedbackPerformer {

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    init() {
        impactFeedback.prepare()
    }

    func perform() {
        AudioServicesPlaySystemSound(1104)
        impactFeedback.impactOccurred(intensity: 0.75)
        impactFeedback.prepare()
    }
}
#endif

private extension String {

    var isHexLetter: Bool {
        switch self {
            case "A", "B", "C", "D", "E", "F":
                true
            default:
                false
        }
    }
}

private struct HexKeyboardInputPreview: View {
    enum Scenario {
        case empty
        case shortDiagnostic
        case longPayload
        case sendingDisabled
        case oddNibbleBlocked
        case minimumLengthBlocked
        case inlineEditing
    }

    @State private var text: String

    private let scenario: Scenario

    init(_ scenario: Scenario) {
        self.scenario = scenario
        self._text = State(initialValue: Self.initialText(for: scenario))
    }

    var body: some View {
        VStack(spacing: 14) {
            previewState
            Spacer()
            HexKeyboardInput(
                $text,
                placeholder: "Hex message",
                submitSystemImage: submitSystemImage,
                showsSubmitKey: scenario != .inlineEditing,
                autoFocus: scenario != .inlineEditing,
                isSubmitEnabled: scenario != .sendingDisabled,
                minimumNibbleCount: minimumNibbleCount,
                requiresEvenNibbleCount: requiresEvenNibbleCount
            ) {}
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 18)
        .background(Color.gray.opacity(0.12))
    }

    private var previewState: some View {
        VStack(alignment: .leading, spacing: 8) {
            previewRow("Raw Binding", text.isEmpty ? "empty" : text)
            previewRow("Grouped UI", HexKeyboardInput.groupedHex(text).isEmpty ? "empty" : HexKeyboardInput.groupedHex(text))
            previewRow("Bytes", byteSummary)
            previewRow("Can Submit", canSubmit ? "yes" : "no")
        }
        .font(.system(.caption, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func previewRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var canSubmit: Bool {
        let nibbleCount = HexKeyboardInput.normalizedHex(text).count
        return scenario != .sendingDisabled
            && nibbleCount >= minimumNibbleCount
            && (!requiresEvenNibbleCount || nibbleCount.isMultiple(of: 2))
    }

    private var byteSummary: String {
        guard let bytes = HexKeyboardInput.byteArray(from: text, requiresEvenNibbleCount: requiresEvenNibbleCount) else {
            return "invalid"
        }
        return "[" + bytes.map { String(format: "0x%02X", $0) }.joined(separator: ", ") + "]"
    }

    private var minimumNibbleCount: Int {
        switch scenario {
            case .minimumLengthBlocked:
                8
            case .inlineEditing:
                2
            default:
                1
        }
    }

    private var requiresEvenNibbleCount: Bool {
        switch scenario {
            case .oddNibbleBlocked:
                true
            default:
                true
        }
    }

    private static func initialText(for scenario: Scenario) -> String {
        let text = switch scenario {
            case .empty:
                ""
            case .shortDiagnostic:
                "22 F1 90"
            case .longPayload:
                "36 02 00 10 20 30 40 50 60 70 80 90 A0 B0 C0 D0"
            case .sendingDisabled:
                "3E 00"
            case .oddNibbleBlocked:
                "22 F"
            case .minimumLengthBlocked:
                "22 F1"
            case .inlineEditing:
                "7E8"
        }
        return text
    }

    private var submitSystemImage: String {
        switch scenario {
            case .inlineEditing:
                "checkmark"
            default:
                "paperplane.fill"
        }
    }
}

#Preview("Hex Keyboard Empty") {
    HexKeyboardInputPreview(.empty)
}

#Preview("Hex Keyboard Diagnostic Request") {
    HexKeyboardInputPreview(.shortDiagnostic)
}

#Preview("Hex Keyboard Long Payload") {
    HexKeyboardInputPreview(.longPayload)
}

#Preview("Hex Keyboard Sending Disabled") {
    HexKeyboardInputPreview(.sendingDisabled)
}

#Preview("Hex Keyboard Odd Nibble Blocked") {
    HexKeyboardInputPreview(.oddNibbleBlocked)
}

#Preview("Hex Keyboard Minimum Length Blocked") {
    HexKeyboardInputPreview(.minimumLengthBlocked)
}

#Preview("Hex Keyboard Inline Editing") {
    HexKeyboardInputPreview(.inlineEditing)
}
