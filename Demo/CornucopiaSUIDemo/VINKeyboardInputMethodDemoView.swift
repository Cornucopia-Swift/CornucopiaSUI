//
//  VINKeyboardInputMethodDemoView.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import SwiftUI

struct VINKeyboardInputMethodDemoView: View {

    @State private var vin = ProcessInfo.processInfo.environment["DEMO_VIN"] ?? ""
    @State private var validationState: VINTextField.ValidationState = .empty
    @State private var layout: VINKeyboardInput.KeyboardLayout = .qwertz
    @State private var selectedPreset: VINPreset = .empty
    @State private var decodeVehicleDetails = true
    @State private var isFocused = false
    @State private var submitted: [String] = []

    var body: some View {
        DemoScroll {
            DemoPanel("Input Method", subtitle: "A regular text field whose inputView is backed by VINKeyboardInput.") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("VIN")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VINKeyboardTextField(
                        $vin,
                        validationState: $validationState,
                        isFocused: $isFocused,
                        keyboardLayout: layout,
                        placeholder: "Enter VIN",
                        autoFocus: true,
                        vehicleDecoder: decodeVehicleDetails ? .nhtsa : nil
                    ) {
                        submit()
                    }
                }
            }

            DemoPanel("Presets") {
                Picker("VIN", selection: $selectedPreset) {
                    ForEach(VINPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedPreset) { _, preset in
                    vin = preset.value
                }
            }

            DemoPanel("Options") {
                Picker("Keyboard Type", selection: $layout) {
                    Text("QWERTZ").tag(VINKeyboardInput.KeyboardLayout.qwertz)
                    Text("QWERTY").tag(VINKeyboardInput.KeyboardLayout.qwerty)
                    Text("AZERTY").tag(VINKeyboardInput.KeyboardLayout.azerty)
                }
                .pickerStyle(.segmented)

                Toggle("Decode vehicle details (NHTSA)", isOn: $decodeVehicleDetails)
            }

            DemoPanel("Live State") {
                HStack(spacing: 10) {
                    DemoMetric(title: "VIN", value: vin.isEmpty ? "-" : vin)
                    DemoMetric(title: "Length", value: "\(vin.count)/17")
                }
                DemoMetric(title: "Validation", value: validationDescription)
            }

            DemoPanel("Submitted VINs") {
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
        .navigationTitle("VIN Input Method")
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

    private enum VINPreset: String, CaseIterable, Identifiable {
        case empty
        case usHonda
        case usTesla
        case usFord
        case germanVW

        var id: String { rawValue }

        var title: String {
            switch self {
                case .empty: "Empty"
                case .usHonda: "US Honda"
                case .usTesla: "US Tesla"
                case .usFord: "US Ford"
                case .germanVW: "German VW"
            }
        }

        var value: String {
            switch self {
                case .empty: ""
                case .usHonda: "1HGCM82633A123456"
                case .usTesla: "5YJ3E1EA7JF000316"
                case .usFord: "1FTFW1ET5DFC10312"
                case .germanVW: "WVWZZZ1KZ9W000001"
            }
        }
    }
}

#Preview {
    NavigationStack {
        VINKeyboardInputMethodDemoView()
    }
}
