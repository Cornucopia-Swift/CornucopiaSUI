//
//  ScannerKeyboardTextField.swift
//  CornucopiaSUI
//

import SwiftUI

#if canImport(UIKit) && canImport(VisionKit) && canImport(Vision) && os(iOS)
import UIKit
import Vision
import VisionKit

/// A text field whose keyboard is a live code scanner.
///
/// Focusing the field slides a camera up from below exactly where the keyboard
/// would be, and a recognized code fills the field. This keeps scanning inside
/// the form rather than behind a modal: the field stays visible, the value
/// appears in place, and typing or pasting remains available through the
/// keyboard-switch button.
///
/// - Important: `DataScannerViewController` does not run in the Simulator.
///   There, and on unsupported devices, the input view explains itself and the
///   system keyboard takes over, so the field is never a dead end.
public struct ScannerKeyboardTextField: View {

    @Binding private var text: String
    private let placeholder: String
    private let symbologies: [VNBarcodeSymbology]
    private let autoFocus: Bool
    private let onScan: ((String) -> Void)?

    public init(
        _ text: Binding<String>,
        placeholder: String = "",
        symbologies: [VNBarcodeSymbology] = [.qr],
        autoFocus: Bool = false,
        onScan: ((String) -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.symbologies = symbologies
        self.autoFocus = autoFocus
        self.onScan = onScan
    }

    public var body: some View {
        Representable(
            text: $text,
            placeholder: placeholder,
            symbologies: symbologies,
            autoFocus: autoFocus,
            onScan: onScan
        )
        .frame(height: 24)
    }

    // MARK: - UIKit bridge

    private struct Representable: UIViewRepresentable {

        @Binding var text: String
        let placeholder: String
        let symbologies: [VNBarcodeSymbology]
        let autoFocus: Bool
        let onScan: ((String) -> Void)?

        func makeUIView(context: Context) -> UITextField {
            let textField = UITextField()
            textField.placeholder = placeholder
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            textField.spellCheckingType = .no
            textField.clearButtonMode = .whileEditing
            textField.delegate = context.coordinator
            textField.addTarget(
                context.coordinator,
                action: #selector(Coordinator.editingChanged(_:)),
                for: .editingChanged
            )
            // Only take over the keyboard where scanning can actually happen.
            if CodeScannerView.isAvailable {
                textField.inputView = context.coordinator.inputView
            }
            context.coordinator.textField = textField
            context.coordinator.install(symbologies: symbologies)
            return textField
        }

        func updateUIView(_ textField: UITextField, context: Context) {
            context.coordinator.textField = textField
            context.coordinator.text = $text
            context.coordinator.onScan = onScan
            if textField.text != text { textField.text = text }

            if autoFocus, !context.coordinator.didAutoFocus {
                context.coordinator.didAutoFocus = true
                DispatchQueue.main.async { textField.becomeFirstResponder() }
            }
        }

        func makeCoordinator() -> Coordinator { Coordinator() }
    }

    @MainActor
    final class Coordinator: NSObject, UITextFieldDelegate {

        /// Tall enough to aim the camera at a screen held in the other hand;
        /// a keyboard-height strip is not enough to frame a code reliably.
        private static let inputViewHeight: CGFloat = 320

        let inputView = ScannerInputView(
            frame: CGRect(x: 0, y: 0, width: 0, height: inputViewHeight),
            inputViewStyle: .keyboard
        )

        weak var textField: UITextField?
        var text: Binding<String>?
        var onScan: ((String) -> Void)?
        var didAutoFocus = false

        private var hostingController: UIHostingController<AnyView>?

        override init() {
            super.init()
            inputView.backgroundColor = .clear
            let height = inputView.heightAnchor.constraint(equalToConstant: Self.inputViewHeight)
            height.priority = .defaultHigh
            height.isActive = true
        }

        func install(symbologies: [VNBarcodeSymbology]) {
            guard hostingController == nil, CodeScannerView.isAvailable else { return }

            let controller = UIHostingController(rootView: AnyView(EmptyView()))
            controller.view.backgroundColor = .clear
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            inputView.addSubview(controller.view)
            NSLayoutConstraint.activate([
                controller.view.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
                controller.view.topAnchor.constraint(equalTo: inputView.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: inputView.bottomAnchor),
            ])
            hostingController = controller

            controller.rootView = AnyView(
                CodeScannerView(symbologies: symbologies) { [weak self] payload in
                    self?.accept(payload)
                }
            )
        }

        /// Fills the field and dismisses the scanner, because a code that has
        /// been read is a completed input — leaving the camera up invites a
        /// second, conflicting scan.
        private func accept(_ payload: String) {
            guard let textField else { return }
            textField.text = payload
            text?.wrappedValue = payload
            onScan?(payload)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            textField.resignFirstResponder()
        }

        @objc func editingChanged(_ sender: UITextField) {
            text?.wrappedValue = sender.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }

    /// `UIInputView` rather than a plain view, so the system treats it as a
    /// keyboard: correct background, safe-area handling, and dismissal.
    public final class ScannerInputView: UIInputView {}
}
#endif
