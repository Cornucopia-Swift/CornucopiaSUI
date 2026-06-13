//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI
#if os(iOS)
import AudioToolbox
import UIKit
#endif

public struct TextFieldStepperConfiguration {
    public var unit: String
    public var label: String
    public var step: Double
    public var range: ClosedRange<Double>
    public var minimumFractionDigits: Int
    public var maximumFractionDigits: Int
    public var buttonSize: CGFloat
    public var valueColor: Color
    public var labelColor: Color
    public var controlColor: Color
    public var disabledControlColor: Color
    public var repeatDelay: Duration
    public var repeatInterval: Duration
    public var feedback: TextFieldStepperFeedback

    public init(
        unit: String = "",
        label: String = "",
        step: Double = 1,
        range: ClosedRange<Double> = 0...100,
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int = 8,
        buttonSize: CGFloat = 34,
        valueColor: Color = .primary,
        labelColor: Color = .secondary,
        controlColor: Color = .accentColor,
        disabledControlColor: Color = .secondary.opacity(0.35),
        repeatDelay: Duration = .milliseconds(350),
        repeatInterval: Duration = .milliseconds(85),
        feedback: TextFieldStepperFeedback = .default
    ) {
        self.unit = unit
        self.label = label
        self.step = step
        self.range = range
        self.minimumFractionDigits = minimumFractionDigits
        self.maximumFractionDigits = maximumFractionDigits
        self.buttonSize = buttonSize
        self.valueColor = valueColor
        self.labelColor = labelColor
        self.controlColor = controlColor
        self.disabledControlColor = disabledControlColor
        self.repeatDelay = repeatDelay
        self.repeatInterval = repeatInterval
        self.feedback = feedback
    }
}

public struct TextFieldStepperFeedback: OptionSet, Sendable {
    public let rawValue: Int

    public static let haptics = TextFieldStepperFeedback(rawValue: 1 << 0)
    public static let audibleClicks = TextFieldStepperFeedback(rawValue: 1 << 1)
    public static let `default`: TextFieldStepperFeedback = [.haptics, .audibleClicks]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct TextFieldStepper: View {
    @Binding private var value: Double
    @FocusState private var isEditing: Bool
    @State private var draftText: String
    @State private var fallbackValue: Double
    @State private var isCompletingExplicitEdit = false

    private let configuration: TextFieldStepperConfiguration

    public init(
        value: Binding<Double>,
        unit: String? = nil,
        label: String? = nil,
        step: Double? = nil,
        range: ClosedRange<Double>? = nil,
        minimumFractionDigits: Int? = nil,
        maximumFractionDigits: Int? = nil,
        configuration: TextFieldStepperConfiguration = TextFieldStepperConfiguration()
    ) {
        var configuration = configuration
        configuration.unit = unit ?? configuration.unit
        configuration.label = label ?? configuration.label
        configuration.step = step ?? configuration.step
        configuration.range = range ?? configuration.range
        configuration.minimumFractionDigits = minimumFractionDigits ?? configuration.minimumFractionDigits
        configuration.maximumFractionDigits = maximumFractionDigits ?? configuration.maximumFractionDigits

        let clampedValue = TextFieldStepperValueFormatter.clamped(value.wrappedValue, in: configuration.range)
        self._value = value
        self.configuration = configuration
        self._draftText = State(initialValue: TextFieldStepperValueFormatter.displayText(for: clampedValue, configuration: configuration))
        self._fallbackValue = State(initialValue: clampedValue)
    }

    public var body: some View {
        HStack(spacing: 12) {
            leadingControl

            VStack(spacing: 2) {
                TextField("", text: $draftText)
                    .focused($isEditing)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(configuration.valueColor)
                    .multilineTextAlignment(.center)
                    .monospacedDigit()
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .onSubmit {
                        commitDraft()
                    }
                    .accessibilityLabel(configuration.label.isEmpty ? "Value" : configuration.label)
                    .accessibilityValue(TextFieldStepperValueFormatter.displayText(for: value, configuration: configuration))

                if !configuration.label.isEmpty {
                    Text(configuration.label)
                        .font(.footnote)
                        .foregroundStyle(configuration.labelColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(minWidth: 84)

            trailingControl
        }
        .onAppear {
            normalizeBoundValue()
        }
        .textFieldStepperChangeHandlers(
            isEditing: isEditing,
            value: value,
            onEditingChanged: handleEditingChanged,
            onValueChanged: handleValueChanged
        )
        .accessibilityElement(children: .contain)
    }

    private var leadingControl: some View {
        ZStack {
            StepperRepeatButton(
                systemName: "minus.circle.fill",
                accessibilityLabel: "Decrease value",
                size: configuration.buttonSize,
                tint: configuration.controlColor,
                disabledTint: configuration.disabledControlColor,
                isDisabled: !canStep(.decrement),
                repeatDelay: configuration.repeatDelay,
                repeatInterval: configuration.repeatInterval
            ) {
                applyStep(.decrement)
            }
            .opacity(isEditing ? 0 : 1)

            editActionButton(systemName: "xmark.circle.fill", tint: .red, accessibilityLabel: "Cancel edit") {
                cancelDraft()
            }
            .opacity(isEditing ? 1 : 0)
        }
        .frame(width: configuration.buttonSize, height: configuration.buttonSize)
    }

    private var trailingControl: some View {
        ZStack {
            StepperRepeatButton(
                systemName: "plus.circle.fill",
                accessibilityLabel: "Increase value",
                size: configuration.buttonSize,
                tint: configuration.controlColor,
                disabledTint: configuration.disabledControlColor,
                isDisabled: !canStep(.increment),
                repeatDelay: configuration.repeatDelay,
                repeatInterval: configuration.repeatInterval
            ) {
                applyStep(.increment)
            }
            .opacity(isEditing ? 0 : 1)

            editActionButton(systemName: "checkmark.circle.fill", tint: .green, accessibilityLabel: "Confirm edit") {
                commitDraft()
            }
            .opacity(isEditing ? 1 : 0)
        }
        .frame(width: configuration.buttonSize, height: configuration.buttonSize)
    }

    private func editActionButton(
        systemName: String,
        tint: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: configuration.buttonSize, height: configuration.buttonSize)
                .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .allowsHitTesting(isEditing)
    }

    private func normalizeBoundValue() {
        let clampedValue = TextFieldStepperValueFormatter.clamped(value, in: configuration.range)
        if clampedValue != value {
            value = clampedValue
        }
        draftText = TextFieldStepperValueFormatter.displayText(for: clampedValue, configuration: configuration)
        fallbackValue = clampedValue
    }

    private func handleEditingChanged(_ isEditing: Bool) {
        if isEditing {
            fallbackValue = value
            draftText = TextFieldStepperValueFormatter.editText(for: value, configuration: configuration)
        } else {
            guard !isCompletingExplicitEdit else {
                isCompletingExplicitEdit = false
                return
            }
            commitDraft(playsFeedback: false)
        }
    }

    private func handleValueChanged(_ newValue: Double) {
        let clampedValue = TextFieldStepperValueFormatter.clamped(newValue, in: configuration.range)
        if clampedValue != newValue {
            value = clampedValue
            return
        }

        if !isEditing {
            draftText = TextFieldStepperValueFormatter.displayText(for: clampedValue, configuration: configuration)
            fallbackValue = clampedValue
        }
    }

    private func canStep(_ direction: TextFieldStepperStepDirection) -> Bool {
        let clampedValue = TextFieldStepperValueFormatter.clamped(value, in: configuration.range)
        switch direction {
            case .decrement:
                return clampedValue > configuration.range.lowerBound
            case .increment:
                return clampedValue < configuration.range.upperBound
        }
    }

    private func applyStep(_ direction: TextFieldStepperStepDirection) {
        guard canStep(direction) else { return }
        let delta = abs(configuration.step) * direction.multiplier
        let nextValue = TextFieldStepperValueFormatter.roundedForStorage(value + delta)
        value = TextFieldStepperValueFormatter.clamped(nextValue, in: configuration.range)
        draftText = TextFieldStepperValueFormatter.displayText(for: value, configuration: configuration)
        fallbackValue = value
        TextFieldStepperFeedbackPerformer.selection(configuration.feedback)
    }

    private func commitDraft(playsFeedback: Bool = true) {
        let resolvedValue = TextFieldStepperValueFormatter.resolvedValue(
            from: draftText,
            fallback: fallbackValue,
            configuration: configuration
        )
        value = resolvedValue
        draftText = TextFieldStepperValueFormatter.displayText(for: resolvedValue, configuration: configuration)
        fallbackValue = resolvedValue
        isCompletingExplicitEdit = isEditing
        isEditing = false
        if playsFeedback {
            TextFieldStepperFeedbackPerformer.success(configuration.feedback)
        }
    }

    private func cancelDraft() {
        value = fallbackValue
        draftText = TextFieldStepperValueFormatter.displayText(for: fallbackValue, configuration: configuration)
        isCompletingExplicitEdit = isEditing
        isEditing = false
        TextFieldStepperFeedbackPerformer.warning(configuration.feedback)
    }
}

private extension View {
    @ViewBuilder
    func textFieldStepperChangeHandlers(
        isEditing: Bool,
        value: Double,
        onEditingChanged: @escaping (Bool) -> Void,
        onValueChanged: @escaping (Double) -> Void
    ) -> some View {
        self
            .onChange(of: isEditing) { _, newValue in
                onEditingChanged(newValue)
            }
            .onChange(of: value) { _, newValue in
                onValueChanged(newValue)
            }
    }
}

private struct StepperRepeatButton: View {
    let systemName: String
    let accessibilityLabel: String
    let size: CGFloat
    let tint: Color
    let disabledTint: Color
    let isDisabled: Bool
    let repeatDelay: Duration
    let repeatInterval: Duration
    let action: () -> Void

    @State private var repeatTask: Task<Void, Never>?

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(isDisabled ? disabledTint : tint)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel)
        .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 24) {
        } onPressingChanged: { isPressing in
            if isPressing {
                startRepeating()
            } else {
                stopRepeating()
            }
        }
        .onDisappear(perform: stopRepeating)
    }

    private func startRepeating() {
        guard !isDisabled, repeatTask == nil else { return }
        repeatTask = Task {
            try? await Task.sleep(for: repeatDelay)
            while !Task.isCancelled {
                await MainActor.run {
                    action()
                }
                try? await Task.sleep(for: repeatInterval)
            }
        }
    }

    private func stopRepeating() {
        repeatTask?.cancel()
        repeatTask = nil
    }
}

private enum TextFieldStepperStepDirection {
    case decrement
    case increment

    var multiplier: Double {
        switch self {
            case .decrement: -1
            case .increment: 1
        }
    }
}

enum TextFieldStepperValueFormatter {
    static let unitSeparator = "\u{202F}"

    static func displayText(for value: Double, configuration: TextFieldStepperConfiguration) -> String {
        let numericText = editText(for: value, configuration: configuration)
        guard !configuration.unit.isEmpty else {
            return numericText
        }
        return numericText + unitSeparator + configuration.unit
    }

    static func editText(for value: Double, configuration: TextFieldStepperConfiguration) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = max(0, configuration.minimumFractionDigits)
        formatter.maximumFractionDigits = max(formatter.minimumFractionDigits, min(8, configuration.maximumFractionDigits))
        formatter.roundingMode = .down
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false

        let decimal = NSDecimalNumber(value: roundedForStorage(value))
        return formatter.string(from: decimal) ?? String(roundedForStorage(value))
    }

    static func resolvedValue(
        from text: String,
        fallback: Double,
        configuration: TextFieldStepperConfiguration
    ) -> Double {
        let sanitizedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: configuration.unit, with: "")
            .replacingOccurrences(of: unitSeparator, with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")

        guard let parsedValue = Double(sanitizedText), parsedValue.isFinite else {
            return clamped(fallback, in: configuration.range)
        }

        return clamped(roundedForStorage(parsedValue), in: configuration.range)
    }

    static func clamped(_ value: Double, in range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    static func roundedForStorage(_ value: Double) -> Double {
        (value * 1_000_000_000).rounded() / 1_000_000_000
    }
}

private enum TextFieldStepperFeedbackPerformer {
    static func selection(_ feedback: TextFieldStepperFeedback) {
        #if os(iOS)
        guard !ProcessInfo.processInfo.isiOSAppOnMac else { return }
        if feedback.contains(.haptics) {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        if feedback.contains(.audibleClicks) {
            AudioServicesPlaySystemSound(1104)
        }
        #endif
    }

    static func success(_ feedback: TextFieldStepperFeedback) {
        #if os(iOS)
        guard !ProcessInfo.processInfo.isiOSAppOnMac else { return }
        if feedback.contains(.haptics) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if feedback.contains(.audibleClicks) {
            AudioServicesPlaySystemSound(1104)
        }
        #endif
    }

    static func warning(_ feedback: TextFieldStepperFeedback) {
        #if os(iOS)
        guard !ProcessInfo.processInfo.isiOSAppOnMac else { return }
        if feedback.contains(.haptics) {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        if feedback.contains(.audibleClicks) {
            AudioServicesPlaySystemSound(1104)
        }
        #endif
    }
}

#if DEBUG
#Preview("TextFieldStepper") {
    struct TextFieldStepperPreview: View {
        @State private var temperature = 21.5
        @State private var voltage = 12.2

        var body: some View {
            VStack(spacing: 24) {
                TextFieldStepper(value: $temperature, unit: "°C", label: "Cabin", step: 0.5, range: -20...60, minimumFractionDigits: 1, maximumFractionDigits: 1)
                TextFieldStepper(value: $voltage, unit: "V", label: "Battery", step: 0.1, range: 0...24, minimumFractionDigits: 1, maximumFractionDigits: 2)
            }
            .padding()
        }
    }

    return TextFieldStepperPreview()
}
#endif
