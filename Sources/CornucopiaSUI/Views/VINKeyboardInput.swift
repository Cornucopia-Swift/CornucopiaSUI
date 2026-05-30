//
//  VINKeyboardInput.swift
//  CornucopiaSUI
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A VIN input control with a domain-specific, QWERTZ/QWERTY-oriented keypad.
///
/// `VINKeyboardInput` keeps the bound value normalized to uppercase VIN
/// characters, omits the invalid `I`, `O`, and `Q` keys, groups the value as
/// WMI/VDS/VIS, and highlights the check-digit position while typing.
public struct VINKeyboardInput: View {

    public enum KeyboardLayout {
        case qwertz
        case qwerty
    }

    @State private var internalText = ""
    @State private var validationState: VINTextField.ValidationState = .empty
    @State private var isActiveSlotPulsing = false
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isInputFocused: Bool

    private let externalTextBinding: Binding<String>?
    private let focusedBinding: FocusState<Bool>.Binding?
    private let validationStateBinding: Binding<VINTextField.ValidationState>?
    private let keyboardLayout: KeyboardLayout
    private let placeholder: String
    private let submitSystemImage: String
    private let autoFocus: Bool
    private let isSubmitEnabled: Bool
    private let onSubmit: (() -> Void)?

    private var text: Binding<String> {
        externalTextBinding ?? $internalText
    }

    /// Creates a VIN input with a custom VIN keypad.
    ///
    /// - Parameters:
    ///   - text: Optional external VIN binding. The value is normalized to uppercase
    ///     VIN characters and truncated to 17 characters.
    ///   - focused: Optional focus binding for parent-managed focus.
    ///   - validationState: Optional validation state binding.
    ///   - keyboardLayout: Letter layout used by the custom keypad.
    ///   - placeholder: Placeholder shown while the VIN is empty.
    ///   - submitSystemImage: SF Symbol used for the submit key.
    ///   - autoFocus: When `true`, the control claims focus when it appears.
    ///   - isSubmitEnabled: External enablement flag for submit.
    ///   - onSubmit: Called when the submit key is tapped or Return is pressed.
    public init(
        text: Binding<String>? = nil,
        focused: FocusState<Bool>.Binding? = nil,
        validationState: Binding<VINTextField.ValidationState>? = nil,
        keyboardLayout: KeyboardLayout = .qwertz,
        placeholder: String = "Enter VIN",
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) {
        self.externalTextBinding = text
        self.focusedBinding = focused
        self.validationStateBinding = validationState
        self.keyboardLayout = keyboardLayout
        self.placeholder = placeholder
        self.submitSystemImage = submitSystemImage
        self.autoFocus = autoFocus
        self.isSubmitEnabled = isSubmitEnabled
        self.onSubmit = onSubmit
    }

    /// Convenience initializer for binding to a VIN string.
    public init(
        _ text: Binding<String>,
        keyboardLayout: KeyboardLayout = .qwertz,
        placeholder: String = "Enter VIN",
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) {
        self.init(
            text: text,
            keyboardLayout: keyboardLayout,
            placeholder: placeholder,
            submitSystemImage: submitSystemImage,
            autoFocus: autoFocus,
            isSubmitEnabled: isSubmitEnabled,
            onSubmit: onSubmit
        )
    }

    /// Convenience initializer with focus binding.
    public init(
        _ text: Binding<String>,
        focused: FocusState<Bool>.Binding,
        keyboardLayout: KeyboardLayout = .qwertz,
        placeholder: String = "Enter VIN",
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) {
        self.init(
            text: text,
            focused: focused,
            keyboardLayout: keyboardLayout,
            placeholder: placeholder,
            submitSystemImage: submitSystemImage,
            autoFocus: autoFocus,
            isSubmitEnabled: isSubmitEnabled,
            onSubmit: onSubmit
        )
    }

    /// Convenience initializer with validation state binding.
    public init(
        _ text: Binding<String>,
        validationState: Binding<VINTextField.ValidationState>,
        keyboardLayout: KeyboardLayout = .qwertz,
        placeholder: String = "Enter VIN",
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) {
        self.init(
            text: text,
            validationState: validationState,
            keyboardLayout: keyboardLayout,
            placeholder: placeholder,
            submitSystemImage: submitSystemImage,
            autoFocus: autoFocus,
            isSubmitEnabled: isSubmitEnabled,
            onSubmit: onSubmit
        )
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
        .onChange(of: text.wrappedValue) { _ in
            normalizeBoundText()
        }
        .onChange(of: validationState) { newState in
            validationStateBinding?.wrappedValue = newState
        }
        .vinHardwareKeyboardInput(
            internalFocus: $isInputFocused,
            externalFocus: focusedBinding,
            handleKeyPress: handleKeyPress,
            handleDelete: deleteLastCharacter,
            handleSubmit: submit
        )
    }

    private var display: some View {
        HStack(spacing: 0) {
            slotMatrix
                .frame(maxWidth: .infinity, alignment: .leading)
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
            .buttonStyle(VINInlineButtonStyle(isEnabled: !text.wrappedValue.isEmpty))
            .disabled(text.wrappedValue.isEmpty)
            .accessibilityLabel("Clear VIN")
        }
        .background(displayBackground)
    }

    /// Lays out 17 fixed character slots so every typed character sits directly on
    /// top of its slot marker, with static WMI/VDS/VIS group labels above.
    private var slotMatrix: some View {
        GeometryReader { geometry in
            let cellSpacing: CGFloat = 3
            let groupSpacing: CGFloat = 14
            let available = geometry.size.width - cellSpacing * 14 - groupSpacing * 2
            let cellWidth = max(1, available / 17)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    groupLabel("WMI", count: 3, color: .blue, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer().frame(width: groupSpacing)
                    groupLabel("VDS", count: 6, color: .orange, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer().frame(width: groupSpacing)
                    groupLabel("VIS", count: 8, color: .green, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer(minLength: 0)
                }

                HStack(spacing: 0) {
                    slotGroup(0..<3, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer().frame(width: groupSpacing)
                    slotGroup(3..<9, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer().frame(width: groupSpacing)
                    slotGroup(9..<17, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: 54)
    }

    private func groupLabel(_ label: String, count: Int, color: Color, cellWidth: CGFloat, cellSpacing: CGFloat) -> some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .frame(width: cellWidth * CGFloat(count) + cellSpacing * CGFloat(count - 1), alignment: .leading)
    }

    private func slotGroup(_ range: Range<Int>, cellWidth: CGFloat, cellSpacing: CGFloat) -> some View {
        HStack(spacing: cellSpacing) {
            ForEach(range, id: \.self) { index in
                slotCell(at: index, width: cellWidth)
            }
        }
    }

    private func slotCell(at index: Int, width: CGFloat) -> some View {
        VStack(spacing: 5) {
            Text(character(at: index))
                .font(.system(.callout, design: .monospaced).weight(.medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)

            Capsule(style: .continuous)
                .fill(slotColor(at: index))
                .frame(height: 4)
                .overlay {
                    if index == activeIndex {
                        Capsule(style: .continuous)
                            .fill(activeMarkerColor(at: index))
                            .opacity(isActiveSlotPulsing ? 0.9 : 0.2)
                            .animation(
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                value: isActiveSlotPulsing
                            )
                    }
                }
        }
        .frame(width: width)
        .accessibilityHidden(true)
    }

    /// The slot index awaiting the next character, or `nil` when the VIN is full.
    private var activeIndex: Int? {
        let count = text.wrappedValue.count
        return count < 17 ? count : nil
    }

    private func activeMarkerColor(at index: Int) -> Color {
        index == 8 ? .orange : .accentColor
    }

    /// Semantic group color for a slot position (WMI / VDS / VIS).
    private func groupColor(at index: Int) -> Color {
        switch index {
            case 0..<3:
                .blue
            case 3..<9:
                .orange
            default:
                .green
        }
    }

    private func character(at index: Int) -> String {
        let value = text.wrappedValue
        guard index < value.count else { return " " }
        return String(value[value.index(value.startIndex, offsetBy: index)])
    }

    private func slotColor(at index: Int) -> Color {
        let count = text.wrappedValue.count

        // Filled slots reflect validity; the check-digit position stays orange.
        if count > index {
            return index == 8 ? .orange : validationState.inputType.color
        }

        // Empty and active baseline: a subtle tint in the slot's group color.
        // The active slot's emphasis is layered on top by the pulsing overlay.
        return groupColor(at: index).opacity(colorScheme == .dark ? 0.32 : 0.22)
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
        switch validationState {
            case .empty:
                Color.primary.opacity(0.16)
            case .incomplete:
                Color.primary.opacity(0.22)
            case .valid:
                Color.green.opacity(0.65)
            case .validWithCheckDigitWarning:
                Color.orange.opacity(0.75)
            case .invalidCharacters, .tooLong:
                Color.red.opacity(0.75)
        }
    }

    private var keypad: some View {
        VStack(spacing: 6) {
            keypadRow(numberKeys)

            ForEach(Array(letterRows.enumerated()), id: \.offset) { _, row in
                keypadRow(row)
            }

            HStack(spacing: 6) {
                identityPreview
                Spacer(minLength: 0)
                deleteKey
                submitKey
            }
            .animation(.easeInOut(duration: 0.25), value: previewIdentity)
        }
    }

    /// Decoded country/manufacturer for the current input, or `nil` when not yet
    /// identifiable. Used both for rendering and as the animation trigger.
    private var previewIdentity: VINIdentity? {
        VINIdentity.decoding(text.wrappedValue)
    }

    @ViewBuilder
    private var identityPreview: some View {
        if let identity = previewIdentity {
            HStack(spacing: 8) {
                Text(identity.flag)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 1) {
                    MarqueeText(identity.countryName, startDelay: 2)
                        .font(.caption.weight(.medium))
                        .frame(width: Self.identityColumnWidth)

                    if let manufacturer = identity.manufacturer {
                        MarqueeText(manufacturer, startDelay: 2)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: Self.identityColumnWidth)
                    }
                }
            }
            .padding(.leading, 4)
            .transition(.opacity.combined(with: .move(edge: .leading)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(identityAccessibilityLabel(identity))
        }
    }

    private func identityAccessibilityLabel(_ identity: VINIdentity) -> String {
        if let manufacturer = identity.manufacturer {
            return "\(identity.countryName), \(manufacturer)"
        }
        return identity.countryName
    }

    private static let identityColumnWidth: CGFloat = 150

    private func keypadRow(_ keys: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                vinKey(key)
            }
        }
    }

    private func vinKey(_ key: String) -> some View {
        Button {
            append(key)
        } label: {
            Text(key)
                .font(.title3.monospaced().weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(VINKeyboardKeyStyle(role: keyRole(for: key)))
        .disabled(!isKeyEnabled(key))
        .accessibilityLabel("VIN \(key)")
    }

    /// At each position only the characters valid there stay enabled. The check-digit
    /// position (9th) accepts digits and `X` only, so letters other than `X` are
    /// disabled. A full VIN disables every key.
    private func isKeyEnabled(_ key: String) -> Bool {
        guard text.wrappedValue.count < 17 else { return false }
        guard isCheckDigitPosition else { return true }
        return key == "X" || key.allSatisfy(\.isNumber)
    }

    private var deleteKey: some View {
        Button {
            deleteLastCharacter()
        } label: {
            Image(systemName: "delete.left")
                .font(.title3.weight(.semibold))
                .frame(width: 58, height: 42)
        }
        .buttonStyle(VINKeyboardKeyStyle(role: .action))
        .disabled(text.wrappedValue.isEmpty)
        .accessibilityLabel("Delete")
    }

    private var submitKey: some View {
        Button {
            submit()
        } label: {
            Image(systemName: submitSystemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 58, height: 42)
        }
        .buttonStyle(VINKeyboardKeyStyle(role: canSubmit ? .submit : .action))
        .disabled(!canSubmit)
        .accessibilityLabel("Submit VIN")
    }

    private var numberKeys: [String] {
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    }

    private var letterRows: [[String]] {
        switch keyboardLayout {
            case .qwertz:
                [
                    ["W", "E", "R", "T", "Z", "U", "P"],
                    ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
                    ["Y", "X", "C", "V", "B", "N", "M"]
                ]
            case .qwerty:
                [
                    ["W", "E", "R", "T", "Y", "U", "P"],
                    ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
                    ["Z", "X", "C", "V", "B", "N", "M"]
                ]
        }
    }

    private func keyRole(for key: String) -> VINKeyboardKeyRole {
        if isCheckDigitPosition && (key == "X" || key.allSatisfy(\.isNumber)) {
            return .checkDigit
        }

        return key.allSatisfy(\.isNumber) ? .digit : .letter
    }

    private var isCheckDigitPosition: Bool {
        text.wrappedValue.count == 8
    }

    private var canSubmit: Bool {
        isSubmitEnabled && text.wrappedValue.count == 17
    }

    private func append(_ character: String) {
        guard text.wrappedValue.count < 17 else { return }
        guard let first = character.first, isValidVINCharacter(first) else { return }
        text.wrappedValue.append(String(first).uppercased())
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func deleteLastCharacter() {
        guard !text.wrappedValue.isEmpty else { return }
        text.wrappedValue.removeLast()
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func clear() {
        guard !text.wrappedValue.isEmpty else { return }
        text.wrappedValue = ""
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
        var didHandle = false
        for character in characters {
            let normalized = String(character).uppercased()
            guard let first = normalized.first, isValidVINCharacter(first) else { continue }
            append(String(first))
            didHandle = true
        }
        return didHandle
    }

    private func normalizeBoundText() {
        let normalized = Self.normalizedVIN(text.wrappedValue)
        if text.wrappedValue != normalized {
            text.wrappedValue = normalized
        }
        updateValidationState()
    }

    private func updateValidationState() {
        validationState = validateVIN(text.wrappedValue)
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

    /// Returns uppercase VIN characters only, truncated to 17 characters.
    public static func normalizedVIN(_ input: String) -> String {
        String(input.uppercased().filter { isValidVINCharacter($0) }.prefix(17))
    }
}

private enum VINKeyboardKeyRole {
    case letter
    case digit
    case checkDigit
    case action
    case submit

    func foreground(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .letter:
                Color.primary
            case .digit:
                Color.primary
            case .checkDigit:
                colorScheme == .dark ? Color(red: 1, green: 0.86, blue: 0.58) : Color.orange
            case .action:
                Color.primary.opacity(0.76)
            case .submit:
                Color.white
        }
    }

    func background(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .letter:
                Color.primary.opacity(0.08)
            case .digit:
                Color.secondary.opacity(0.16)
            case .checkDigit:
                colorScheme == .dark ? Color.orange.opacity(0.24) : Color.orange.opacity(0.16)
            case .action:
                Color.secondary.opacity(0.22)
            case .submit:
                Color.accentColor
        }
    }

    func pressedBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .letter:
                Color.primary.opacity(0.22)
            case .digit:
                Color.secondary.opacity(0.3)
            case .checkDigit:
                colorScheme == .dark ? Color.orange.opacity(0.34) : Color.orange.opacity(0.28)
            case .action:
                Color.secondary.opacity(0.34)
            case .submit:
                Color.accentColor.opacity(0.78)
        }
    }

    func border(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .letter:
                Color.primary.opacity(0.06)
            case .digit:
                Color.secondary.opacity(0.14)
            case .checkDigit:
                Color.orange.opacity(colorScheme == .dark ? 0.64 : 0.35)
            case .action:
                Color.secondary.opacity(0.18)
            case .submit:
                Color.accentColor.opacity(0.85)
        }
    }
}

private struct VINKeyboardKeyStyle: ButtonStyle {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    let role: VINKeyboardKeyRole

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

private struct VINInlineButtonStyle: ButtonStyle {

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
    func vinHardwareKeyboardInput(
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
                    .vinKeyPressHandler(
                        handleKeyPress: handleKeyPress,
                        handleDelete: handleDelete,
                        handleSubmit: handleSubmit
                    )
            } else {
                self
                    .focusable()
                    .focused(internalFocus)
                    .vinKeyPressHandler(
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
    func vinKeyPressHandler(
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

private struct VINKeyboardInputPreview: View {

    enum Scenario {
        case empty
        case partial
        case checkDigit
        case complete
        case dark
    }

    @State private var vin: String

    private let scenario: Scenario

    init(_ scenario: Scenario) {
        self.scenario = scenario
        self._vin = State(initialValue: Self.initialVIN(for: scenario))
    }

    var body: some View {
        VStack(spacing: 16) {
            previewHeader
            Spacer()
            VINKeyboardInput(
                $vin,
                keyboardLayout: keyboardLayout,
                autoFocus: false
            ) {}
        }
        .padding()
        .frame(width: 390, height: 620)
        .background(Color.gray.opacity(0.12))
        .preferredColorScheme(scenario == .dark ? .dark : nil)
    }

    private var previewHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(previewTitle)
                .font(.headline)
            Text(vin.isEmpty ? "Empty VIN" : vin)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var keyboardLayout: VINKeyboardInput.KeyboardLayout {
        switch scenario {
            case .complete:
                .qwerty
            default:
                .qwertz
        }
    }

    private static func initialVIN(for scenario: Scenario) -> String {
        switch scenario {
            case .empty:
                ""
            case .partial:
                "WVWZZZ"
            case .checkDigit:
                "WVWZZZ1K"
            case .complete:
                "1HGCM82633A123456"
            case .dark:
                "WVWZZZ1KZ"
        }
    }

    private var previewTitle: String {
        switch scenario {
            case .empty:
                "QWERTZ VIN Keyboard"
            case .partial:
                "Partial VIN"
            case .checkDigit:
                "Check Digit Position"
            case .complete:
                "QWERTY Complete VIN"
            case .dark:
                "Dark Terminal VIN Keyboard"
        }
    }
}

#Preview("VIN Keyboard Empty") {
    VINKeyboardInputPreview(.empty)
}

#Preview("VIN Keyboard Partial") {
    VINKeyboardInputPreview(.partial)
}

#Preview("VIN Keyboard Check Digit") {
    VINKeyboardInputPreview(.checkDigit)
}

#Preview("VIN Keyboard QWERTY Complete") {
    VINKeyboardInputPreview(.complete)
}

#Preview("VIN Keyboard Dark") {
    VINKeyboardInputPreview(.dark)
}
