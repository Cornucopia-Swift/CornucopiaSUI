//
//  VINKeyboardDemoView.swift
//  InputMethodsDemo
//

import CornucopiaSUI
import SwiftUI

struct VINKeyboardDemoView: View {

    @State private var vin = ProcessInfo.processInfo.environment["DEMO_VIN"] ?? ""
    @State private var validationState: VINTextField.ValidationState = .empty
    @State private var layout: VINKeyboardInput.KeyboardLayout = .qwertz
    @State private var submitted: [String] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
                Divider()
                VINKeyboardInput(
                    $vin,
                    validationState: $validationState,
                    keyboardLayout: layout,
                    placeholder: "Enter VIN",
                    autoFocus: true
                ) {
                    submit()
                }
            }
            .navigationTitle("VIN Keyboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Layout", selection: $layout) {
                        Text("QWERTZ").tag(VINKeyboardInput.KeyboardLayout.qwertz)
                        Text("QWERTY").tag(VINKeyboardInput.KeyboardLayout.qwerty)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var content: some View {
        List {
            Section("Presets") {
                HStack {
                    presetButton("Empty", "")
                    presetButton("Check digit", "WVWZZZ1K")
                    presetButton("Full", "1HGCM82633A123456")
                }
            }

            Section("Live State") {
                labeledRow("VIN", vin.isEmpty ? "—" : vin)
                labeledRow("Length", "\(vin.count)/17")
                labeledRow("Validation", validationDescription)
            }

            Section("Submitted VINs") {
                if submitted.isEmpty {
                    Text("Enter 17 characters, then tap submit.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(submitted.enumerated()), id: \.offset) { _, entry in
                        Text(entry)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
        }
    }

    private func presetButton(_ title: String, _ value: String) -> some View {
        Button(title) {
            vin = value
        }
        .buttonStyle(.bordered)
        .font(.caption)
        .frame(maxWidth: .infinity)
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .multilineTextAlignment(.trailing)
        }
    }

    private var validationDescription: String {
        switch validationState {
            case .empty: "empty"
            case .incomplete: "incomplete"
            case .valid: "valid"
            case .validWithCheckDigitWarning: "check-digit warning"
            case .invalidCharacters: "invalid characters"
            case .tooLong: "too long"
        }
    }

    private func submit() {
        guard !vin.isEmpty else { return }
        submitted.insert(vin, at: 0)
        vin = ""
    }
}

#Preview {
    VINKeyboardDemoView()
}
