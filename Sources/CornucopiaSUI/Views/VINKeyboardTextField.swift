//
//  VINKeyboardTextField.swift
//  CornucopiaSUI
//

import SwiftUI

#if canImport(UIKit) && os(iOS)
import UIKit
#endif

/// A styled VIN text field that installs `VINKeyboardInput` as a real iOS input view.
///
/// Use this when the VIN keypad should be positioned and animated by the OS like a
/// regular keyboard. The field is the visible input surface; the hosted
/// `VINKeyboardInput` is the input method and keeps its VIN/WMI/VDS/VIS display.
///
/// - Important: Do not place a `VINKeyboardInput` underneath this field for the same
///   value. That recreates the invalid "field plus fake keyboard in layout" pattern.
///   This type already owns the field, normalization, validation, first-responder
///   state, and custom `inputView`.
public struct VINKeyboardTextField: View {

    @Binding private var text: String

    private let validationState: Binding<VINTextField.ValidationState>?
    private let isFocused: Binding<Bool>?
    private let keyboardLayout: VINKeyboardInput.KeyboardLayout
    private let placeholder: String
    private let submitSystemImage: String
    private let autoFocus: Bool
    private let isSubmitEnabled: Bool
    private let vehicleDecoder: VINVehicleDecoder?
    private let showsCount: Bool
    private let onSubmit: (() -> Void)?

    public init(
        _ text: Binding<String>,
        validationState: Binding<VINTextField.ValidationState>? = nil,
        isFocused: Binding<Bool>? = nil,
        keyboardLayout: VINKeyboardInput.KeyboardLayout = .qwertz,
        placeholder: String = "Enter VIN",
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        vehicleDecoder: VINVehicleDecoder? = nil,
        showsCount: Bool = true,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.validationState = validationState
        self.isFocused = isFocused
        self.keyboardLayout = keyboardLayout
        self.placeholder = placeholder
        self.submitSystemImage = submitSystemImage
        self.autoFocus = autoFocus
        self.isSubmitEnabled = isSubmitEnabled
        self.vehicleDecoder = vehicleDecoder
        self.showsCount = showsCount
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: 10) {
            inputField
                .layoutPriority(1)

            if showsCount {
                Text("\(text.count)/17")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(height: 44)
        .background(fieldBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        }
        .onAppear {
            normalizeAndValidate()
        }
        .onChange(of: text) {
            normalizeAndValidate()
        }
    }

    @ViewBuilder
    private var inputField: some View {
#if canImport(UIKit) && os(iOS)
        UIKitVINKeyboardTextField(
            text: $text,
            validationState: validationState,
            isFocused: isFocused,
            keyboardLayout: keyboardLayout,
            placeholder: placeholder,
            submitSystemImage: submitSystemImage,
            autoFocus: autoFocus,
            isSubmitEnabled: isSubmitEnabled,
            vehicleDecoder: vehicleDecoder,
            onSubmit: onSubmit
        )
        .frame(height: 22)
#else
        TextField(placeholder, text: $text)
            .font(Font.system(.title3, design: .monospaced))
            .onSubmit {
                guard isSubmitEnabled else { return }
                onSubmit?()
            }
#endif
    }

    private var borderColor: Color {
        switch validationState?.wrappedValue ?? validateVIN(text) {
            case .empty:
                Color.primary.opacity(0.16)
            case .valid, .validWithCheckDigitWarning:
                .green.opacity(0.65)
            case .incomplete, .invalidCharacters, .tooLong:
                .orange.opacity(0.65)
        }
    }

    private var fieldBackground: Color {
#if os(iOS) || os(tvOS) || os(watchOS)
        .secondaryBackground
#else
        Color.primary.opacity(0.05)
#endif
    }

    private func normalizeAndValidate() {
        let normalized = VINKeyboardInput.normalizedVIN(text)
        if text != normalized {
            text = normalized
        }
        validationState?.wrappedValue = validateVIN(normalized)
    }
}

#if canImport(UIKit) && os(iOS)
private struct UIKitVINKeyboardTextField: UIViewRepresentable {

    @Binding var text: String

    let validationState: Binding<VINTextField.ValidationState>?
    let isFocused: Binding<Bool>?
    let keyboardLayout: VINKeyboardInput.KeyboardLayout
    let placeholder: String
    let submitSystemImage: String
    let autoFocus: Bool
    let isSubmitEnabled: Bool
    let vehicleDecoder: VINVehicleDecoder?
    let onSubmit: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.font = .monospacedSystemFont(ofSize: 20, weight: .regular)
        textField.adjustsFontForContentSizeCategory = true
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 14
        textField.placeholder = placeholder
        textField.autocapitalizationType = .allCharacters
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartInsertDeleteType = .no
        textField.smartQuotesType = .no
        textField.returnKeyType = .done
        textField.clearButtonMode = .never
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.heightAnchor.constraint(equalToConstant: 22).isActive = true
        textField.inputView = context.coordinator.inputView
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        context.coordinator.textField = textField
        context.coordinator.update(with: self)
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.textField = textField
        context.coordinator.update(with: self)
        context.coordinator.applyText(text, to: textField)

        if autoFocus, !context.coordinator.didAutoFocus {
            context.coordinator.didAutoFocus = true
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        }

        if isFocused?.wrappedValue == true, !textField.isFirstResponder {
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        } else if isFocused?.wrappedValue == false, textField.isFirstResponder {
            DispatchQueue.main.async {
                textField.resignFirstResponder()
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, UITextFieldDelegate {

        private static let inputViewHeight: CGFloat = 342

        let inputView = VINKeyboardInputMethodInputView(
            frame: CGRect(x: 0, y: 0, width: 0, height: inputViewHeight),
            inputViewStyle: .keyboard
        )

        weak var textField: UITextField?
        var didAutoFocus = false

        private let keyboardModel = VINKeyboardInputMethodModel()
        private var text: Binding<String>?
        private var validationState: Binding<VINTextField.ValidationState>?
        private var isFocused: Binding<Bool>?
        private var keyboardLayout: VINKeyboardInput.KeyboardLayout = .qwertz
        private var placeholder = "Enter VIN"
        private var submitSystemImage = "checkmark"
        private var isSubmitEnabled = true
        private var vehicleDecoder: VINVehicleDecoder?
        private var onSubmit: (() -> Void)?
        private var hostingController: UIHostingController<AnyView>?
        private var heightConstraint: NSLayoutConstraint?
        private var keyboardConfiguration: KeyboardConfiguration?

        override init() {
            super.init()
            inputView.backgroundColor = .clear
            heightConstraint = inputView.heightAnchor.constraint(equalToConstant: Self.inputViewHeight)
            heightConstraint?.priority = .defaultHigh
            heightConstraint?.isActive = true
        }

        func update(with configuration: UIKitVINKeyboardTextField) {
            text = configuration.$text
            validationState = configuration.validationState
            isFocused = configuration.isFocused
            keyboardLayout = configuration.keyboardLayout
            placeholder = configuration.placeholder
            submitSystemImage = configuration.submitSystemImage
            isSubmitEnabled = configuration.isSubmitEnabled
            vehicleDecoder = configuration.vehicleDecoder
            onSubmit = configuration.onSubmit
            syncModelText(configuration.text)
            updateKeyboardIfNeeded(
                KeyboardConfiguration(
                    keyboardLayout: configuration.keyboardLayout,
                    placeholder: configuration.placeholder,
                    submitSystemImage: configuration.submitSystemImage,
                    isSubmitEnabled: configuration.isSubmitEnabled,
                    hasVehicleDecoder: configuration.vehicleDecoder != nil
                )
            )
        }

        func applyText(_ value: String, to textField: UITextField) {
            let normalized = VINKeyboardInput.normalizedVIN(value)
            if textField.text != normalized {
                textField.text = normalized
            }
            syncModelText(normalized)
        }

        @objc func editingChanged(_ sender: UITextField) {
            setText(sender.text ?? "", in: sender)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused?.wrappedValue = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isFocused?.wrappedValue = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            guard isSubmitEnabled, textField.text?.count == 17 else { return false }
            onSubmit?()
            textField.resignFirstResponder()
            return false
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let current = textField.text ?? ""
            guard let range = Range(range, in: current) else { return false }
            let proposed = current.replacingCharacters(in: range, with: string)
            setText(proposed, in: textField)
            return false
        }

        private func updateKeyboardIfNeeded(_ configuration: KeyboardConfiguration) {
            guard text != nil else { return }
            guard hostingController == nil || keyboardConfiguration != configuration else { return }
            keyboardConfiguration = configuration

            let keyboard = VINKeyboardInputMethodHost(
                model: keyboardModel,
                validationState: validationState,
                keyboardLayout: configuration.keyboardLayout,
                placeholder: configuration.placeholder,
                submitSystemImage: configuration.submitSystemImage,
                isSubmitEnabled: configuration.isSubmitEnabled,
                vehicleDecoder: vehicleDecoder,
                onTextChange: { [weak self] newValue in
                    self?.mirrorModelText(newValue)
                },
                onSubmit: { [weak self] in
                    guard let self else { return }
                    onSubmit?()
                    textField?.resignFirstResponder()
                }
            )

            installHostingControllerIfNeeded()
            hostingController?.rootView = AnyView(keyboard)
        }

        private func installHostingControllerIfNeeded() {
            guard hostingController == nil else { return }

            let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
            hostingController.view.backgroundColor = .clear
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            inputView.addSubview(hostingController.view)
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: inputView.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: inputView.bottomAnchor)
            ])
            self.hostingController = hostingController
        }

        private func setText(_ value: String, in textField: UITextField?) {
            let normalized = VINKeyboardInput.normalizedVIN(value)
            syncModelText(normalized)
            mirrorModelText(normalized, textField: textField)
        }

        private func syncModelText(_ value: String) {
            let normalized = VINKeyboardInput.normalizedVIN(value)
            if keyboardModel.text != normalized {
                keyboardModel.text = normalized
            }
            updateValidationState(normalized)
        }

        private func mirrorModelText(_ value: String, textField: UITextField? = nil) {
            let normalized = VINKeyboardInput.normalizedVIN(value)
            if self.text?.wrappedValue != normalized {
                self.text?.wrappedValue = normalized
            }
            let targetTextField = textField ?? self.textField
            if targetTextField?.text != normalized {
                targetTextField?.text = normalized
            }
            updateValidationState(normalized)
        }

        private func updateValidationState(_ value: String) {
            validationState?.wrappedValue = validateVIN(value)
        }

        private struct KeyboardConfiguration: Equatable {
            let keyboardLayout: VINKeyboardInput.KeyboardLayout
            let placeholder: String
            let submitSystemImage: String
            let isSubmitEnabled: Bool
            let hasVehicleDecoder: Bool
        }
    }

    @MainActor
    private final class VINKeyboardInputMethodModel: ObservableObject {
        @Published var text = ""
    }

    private struct VINKeyboardInputMethodHost: View {
        @ObservedObject var model: VINKeyboardInputMethodModel

        let validationState: Binding<VINTextField.ValidationState>?
        let keyboardLayout: VINKeyboardInput.KeyboardLayout
        let placeholder: String
        let submitSystemImage: String
        let isSubmitEnabled: Bool
        let vehicleDecoder: VINVehicleDecoder?
        let onTextChange: (String) -> Void
        let onSubmit: () -> Void

        var body: some View {
            VINKeyboardInput(
                text: $model.text,
                validationState: validationState,
                keyboardLayout: keyboardLayout,
                placeholder: placeholder,
                submitSystemImage: submitSystemImage,
                autoFocus: false,
                isSubmitEnabled: isSubmitEnabled,
                showsDisplay: true,
                usesInternalFocus: false,
                vehicleDecoder: vehicleDecoder,
                onSubmit: onSubmit
            )
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity, alignment: .center)
            .onChange(of: model.text) { _, newValue in
                onTextChange(newValue)
            }
        }
    }

    final class VINKeyboardInputMethodInputView: UIInputView, UIInputViewAudioFeedback {
        var enableInputClicksWhenVisible: Bool { true }
    }
}
#endif

#Preview("VINKeyboardTextField") {
    @Previewable @State var vin = "WBA3A5C50CF256736"
    @Previewable @State var validationState = VINTextField.ValidationState.empty

    VStack(alignment: .leading, spacing: 16) {
        VINKeyboardTextField($vin, validationState: $validationState, autoFocus: true)

        LabeledContent("State", value: String(describing: validationState))
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
    }
    .padding()
}
