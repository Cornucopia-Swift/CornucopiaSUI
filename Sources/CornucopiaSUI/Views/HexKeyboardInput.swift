//
//  HexKeyboardInput.swift
//  CornucopiaSUI
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct HexKeyboardInput: View {

    @Binding private var text: String
    @FocusState private var isInputFocused: Bool
    @State private var isCaretVisible = true

    private let placeholder: String
    private let submitSystemImage: String
    private let isSubmitEnabled: Bool
    private let minimumNibbleCount: Int
    private let requiresEvenNibbleCount: Bool
    private let onSubmit: (() -> Void)?

    public init(
        _ text: Binding<String>,
        placeholder: String = "Hex payload",
        submitSystemImage: String = "paperplane.fill",
        isSubmitEnabled: Bool = true,
        minimumNibbleCount: Int = 1,
        requiresEvenNibbleCount: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.submitSystemImage = submitSystemImage
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
            isInputFocused = true
        }
        .hardwareKeyboardInput(
            isFocused: $isInputFocused,
            handleKeyPress: handleKeyPress,
            handleDelete: deleteLastNibble,
            handleSubmit: submit
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
                submit()
            } label: {
                Image(systemName: submitSystemImage)
                    .font(.callout.weight(.bold))
                    .frame(width: 44, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HexKeyboardSubmitButtonStyle())
            .disabled(!canSubmit)
            .accessibilityLabel("Send hex payload")
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
            .fill(Color.accentColor)
            .frame(width: 2, height: 20)
            .opacity(isCaretVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    isCaretVisible.toggle()
                }
            }
    }

    private var keypad: some View {
        VStack(spacing: 6) {
            keypadRow(["1", "2", "3", "A", "B", "C"])
            keypadRow(["4", "5", "6", "D", "E", "F"])
            HStack(spacing: 6) {
                hexKey("7")
                hexKey("8")
                hexKey("9")
                hexKey("0", role: .zero)
                actionKey("delete.left", accessibilityLabel: "Delete") {
                    deleteLastNibble()
                }
                actionKey("xmark", accessibilityLabel: "Clear") {
                    clear()
                }
            }
        }
    }

    private func keypadRow(_ keys: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                hexKey(key, role: key.isHexLetter ? .hexLetter : .digit)
            }
        }
    }

    private func hexKey(_ key: String, role: HexKeyboardKeyRole = .digit) -> some View {
        Button {
            append(key)
        } label: {
            Text(key)
                .font(.title3.monospaced().weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(HexKeyboardKeyStyle(role: role))
        .accessibilityLabel("Hex \(key)")
    }

    private func actionKey(_ systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(HexKeyboardKeyStyle(role: .action))
        .accessibilityLabel(accessibilityLabel)
    }

    private var canSubmit: Bool {
        isSubmitEnabled
            && normalizedNibbleCount >= minimumNibbleCount
            && (!requiresEvenNibbleCount || normalizedNibbleCount.isMultiple(of: 2))
            && onSubmit != nil
    }

    private var normalizedNibbleCount: Int {
        Self.normalizedHex(text).count
    }

    private func append(_ nibble: String) {
        var hex = Self.normalizedHex(text)
        hex.append(nibble)
        text = Self.groupedHex(hex)
        isInputFocused = true
        feedback()
    }

    private func deleteLastNibble() {
        var hex = Self.normalizedHex(text)
        guard !hex.isEmpty else { return }
        hex.removeLast()
        text = Self.groupedHex(hex)
        isInputFocused = true
        feedback()
    }

    private func clear() {
        guard !text.isEmpty else { return }
        text = ""
        isInputFocused = true
        feedback()
    }

    private func submit() {
        guard canSubmit else { return }
        onSubmit?()
        isInputFocused = true
        feedback()
    }

    private func handleKeyPress(_ characters: String) -> Bool {
        for character in characters {
            if character.isHexDigit {
                append(String(character).uppercased())
            }
        }
        return characters.contains(where: \.isHexDigit)
    }

    private func feedback() {
#if canImport(UIKit)
        UIDevice.current.playInputClick()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
    }

    public static func normalizedHex(_ input: String) -> String {
        input
            .replacingOccurrences(of: "0x", with: "", options: .caseInsensitive)
            .filter(\.isHexDigit)
            .uppercased()
    }

    public static func groupedHex(_ input: String) -> String {
        groupedHexBytes(input).joined(separator: byteSeparator)
    }

    public static func groupedHexBytes(_ input: String) -> [String] {
        normalizedHex(input).reduce(into: [String]()) { result, character in
            if let lastIndex = result.indices.last, result[lastIndex].count < 2 {
                result[lastIndex].append(character)
            } else {
                result.append(String(character))
            }
        }
    }

    public static let byteSeparator = "\u{2009}"
}

private enum HexKeyboardKeyRole {
    case digit
    case hexLetter
    case zero
    case action

    var tint: Color {
        switch self {
            case .digit:
                .primary
            case .hexLetter:
                .accentColor
            case .zero:
                .white
            case .action:
                .primary.opacity(0.76)
        }
    }

    var background: Color {
        switch self {
            case .digit:
                Color.primary.opacity(0.08)
            case .hexLetter:
                Color.accentColor.opacity(0.16)
            case .zero:
                Color.accentColor
            case .action:
                Color.secondary.opacity(0.22)
        }
    }

    var pressedBackground: Color {
        switch self {
            case .digit:
                Color.primary.opacity(0.22)
            case .hexLetter:
                Color.accentColor.opacity(0.28)
            case .zero:
                Color.accentColor.opacity(0.78)
            case .action:
                Color.secondary.opacity(0.34)
        }
    }

    var border: Color {
        switch self {
            case .digit:
                Color.primary.opacity(0.06)
            case .hexLetter:
                Color.accentColor.opacity(0.2)
            case .zero:
                Color.accentColor.opacity(0.85)
            case .action:
                Color.secondary.opacity(0.18)
        }
    }
}

private struct HexKeyboardKeyStyle: ButtonStyle {

    var role: HexKeyboardKeyRole = .digit

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(role.tint)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(keyBackground(isPressed: configuration.isPressed))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(keyBorder(isPressed: configuration.isPressed), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }

    private func keyBackground(isPressed: Bool) -> Color {
        isPressed ? role.pressedBackground : role.background
    }

    private func keyBorder(isPressed: Bool) -> Color {
        isPressed ? Color.accentColor.opacity(0.65) : role.border
    }
}

private struct HexKeyboardSubmitButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .opacity(configuration.isPressed ? 0.68 : 1)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }

    private var foreground: Color {
        isEnabled ? .accentColor : .secondary.opacity(0.55)
    }
}

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

private extension View {

    @ViewBuilder
    func hardwareKeyboardInput(
        isFocused: FocusState<Bool>.Binding,
        handleKeyPress: @escaping (String) -> Bool,
        handleDelete: @escaping () -> Void,
        handleSubmit: @escaping () -> Void
    ) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            self
                .focusable()
                .focused(isFocused)
                .onKeyPress(phases: .down) { press in
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

private struct HexKeyboardInputPreview: View {
    enum Scenario {
        case empty
        case shortDiagnostic
        case longPayload
        case sendingDisabled
        case oddNibbleBlocked
        case minimumLengthBlocked
    }

    @State private var text: String

    private let scenario: Scenario

    init(_ scenario: Scenario) {
        self.scenario = scenario
        self._text = State(initialValue: Self.initialText(for: scenario))
    }

    var body: some View {
        VStack {
            Spacer()
            HexKeyboardInput(
                $text,
                placeholder: "Hex message",
                isSubmitEnabled: scenario != .sendingDisabled,
                minimumNibbleCount: minimumNibbleCount,
                requiresEvenNibbleCount: requiresEvenNibbleCount
            ) {}
        }
        .background(Color.gray.opacity(0.12))
    }

    private var minimumNibbleCount: Int {
        switch scenario {
            case .minimumLengthBlocked:
                8
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
        }
        return HexKeyboardInput.groupedHex(text)
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
