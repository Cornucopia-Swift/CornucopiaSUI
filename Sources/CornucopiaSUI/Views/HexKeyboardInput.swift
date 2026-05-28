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

    private let placeholder: String
    private let submitSystemImage: String
    private let isSubmitEnabled: Bool
    private let onSubmit: (() -> Void)?

    public init(
        _ text: Binding<String>,
        placeholder: String = "Hex payload",
        submitSystemImage: String = "paperplane.fill",
        isSubmitEnabled: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.submitSystemImage = submitSystemImage
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
    }

    private var display: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(displayText)
                    .font(.body.monospaced())
                    .foregroundStyle(text.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                submit()
            } label: {
                Image(systemName: submitSystemImage)
                    .frame(width: 44, height: 40)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)
            .accessibilityLabel("Send hex payload")
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
                hexKey("0")
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
                hexKey(key)
            }
        }
    }

    private func hexKey(_ key: String) -> some View {
        Button {
            append(key)
        } label: {
            Text(key)
                .font(.title3.monospaced().weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(HexKeyboardKeyStyle())
        .accessibilityLabel("Hex \(key)")
    }

    private func actionKey(_ systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(HexKeyboardKeyStyle(tint: .secondary))
        .accessibilityLabel(accessibilityLabel)
    }

    private var displayText: String {
        text.isEmpty ? placeholder : text
    }

    private var canSubmit: Bool {
        isSubmitEnabled && !Self.normalizedHex(text).isEmpty && onSubmit != nil
    }

    private func append(_ nibble: String) {
        var hex = Self.normalizedHex(text)
        hex.append(nibble)
        text = Self.groupedHex(hex)
        feedback()
    }

    private func deleteLastNibble() {
        var hex = Self.normalizedHex(text)
        guard !hex.isEmpty else { return }
        hex.removeLast()
        text = Self.groupedHex(hex)
        feedback()
    }

    private func clear() {
        guard !text.isEmpty else { return }
        text = ""
        feedback()
    }

    private func submit() {
        guard canSubmit else { return }
        onSubmit?()
        feedback()
    }

    private func feedback() {
#if canImport(UIKit)
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
        let hex = normalizedHex(input)
        return hex.enumerated().reduce(into: "") { result, pair in
            if pair.offset > 0 && pair.offset.isMultiple(of: 2) {
                result.append(" ")
            }
            result.append(pair.element)
        }
    }
}

private struct HexKeyboardKeyStyle: ButtonStyle {

    var tint: Color = .primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tint)
            .background(keyBackground(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }

    private func keyBackground(isPressed: Bool) -> some ShapeStyle {
        isPressed ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.quaternary)
    }
}

private struct HexKeyboardInputPreview: View {
    enum Scenario {
        case empty
        case shortDiagnostic
        case longPayload
        case sendingDisabled
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
                isSubmitEnabled: scenario != .sendingDisabled
            ) {}
        }
        .background(Color.gray.opacity(0.12))
    }

    private static func initialText(for scenario: Scenario) -> String {
        switch scenario {
            case .empty:
                ""
            case .shortDiagnostic:
                "22 F1 90"
            case .longPayload:
                "36 02 00 10 20 30 40 50 60 70 80 90 A0 B0 C0 D0"
            case .sendingDisabled:
                "3E 00"
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
