//
//  VINKeyboardDemoView.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import SwiftUI

struct VINKeyboardDemoView: View {

    @State private var vin = ProcessInfo.processInfo.environment["DEMO_VIN"] ?? ""
    @State private var validationState: VINTextField.ValidationState = .empty
    @State private var layout: VINKeyboardInput.KeyboardLayout = .qwertz
    @State private var selectedPreset: VINPreset = .empty
    @State private var decodeVehicleDetails = true
    @State private var submitted: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            content
            Divider()
            VINKeyboardInput(
                $vin,
                validationState: $validationState,
                keyboardLayout: layout,
                placeholder: "Enter VIN",
                autoFocus: true,
                vehicleDecoder: decodeVehicleDetails ? .nhtsa : nil
            ) {
                submit()
            }
        }
    }

    private var content: some View {
        List {
            Section("Presets") {
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

            Section("Options") {
                Picker("Keyboard Type", selection: $layout) {
                    Text("QWERTZ").tag(VINKeyboardInput.KeyboardLayout.qwertz)
                    Text("QWERTY").tag(VINKeyboardInput.KeyboardLayout.qwerty)
                    Text("AZERTY").tag(VINKeyboardInput.KeyboardLayout.azerty)
                }
                .pickerStyle(.menu)

                Toggle("Decode vehicle details (NHTSA)", isOn: $decodeVehicleDetails)
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
    VINKeyboardDemoView()
}
