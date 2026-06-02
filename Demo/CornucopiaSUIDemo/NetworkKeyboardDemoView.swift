//
//  NetworkKeyboardDemoView.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import SwiftUI

struct NetworkKeyboardDemoView: View {

    enum InputKind: String, CaseIterable, Identifiable {
        case ipv4
        case mac

        var id: String { rawValue }

        var title: String {
            switch self {
                case .ipv4: "IPv4"
                case .mac: "MAC"
            }
        }
    }

    @State private var inputKind: InputKind = .ipv4
    @State private var selectedIPv4Preset: IPv4Preset = .empty
    @State private var selectedMACPreset: MACPreset = .empty
    @State private var ipv4 = ""
    @State private var mac = ""
    @State private var macSeparator: MACKeyboardInput.SeparatorStyle = .colon
    @State private var ipv4ValidationState: NetworkAwareTextField.ValidationState = .empty
    @State private var macValidationState: NetworkAwareTextField.ValidationState = .empty
    @State private var submitted: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            content
            Divider()
            keyboard
        }
    }

    private var content: some View {
        List {
            Section("Presets") {
                if inputKind == .ipv4 {
                    Picker("IPv4", selection: $selectedIPv4Preset) {
                        ForEach(IPv4Preset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedIPv4Preset) { _, preset in
                        ipv4 = preset.value
                    }
                } else {
                    Picker("MAC", selection: $selectedMACPreset) {
                        ForEach(MACPreset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedMACPreset) { _, preset in
                        mac = MACKeyboardInput.formattedMAC(preset.value, separatorStyle: macSeparator)
                    }
                }
            }

            Section("Options") {
                Picker("Keyboard Type", selection: $inputKind) {
                    ForEach(InputKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.menu)

                if inputKind == .mac {
                    Picker("Separator", selection: $macSeparator) {
                        Text("Colon").tag(MACKeyboardInput.SeparatorStyle.colon)
                        Text("Dash").tag(MACKeyboardInput.SeparatorStyle.dash)
                        Text("Dot").tag(MACKeyboardInput.SeparatorStyle.dot)
                        Text("Compact").tag(MACKeyboardInput.SeparatorStyle.compact)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: macSeparator) { _, separator in
                        mac = MACKeyboardInput.formattedMAC(mac, separatorStyle: separator)
                    }
                }
            }

            Section("Live State") {
                labeledRow("Value", currentValue.isEmpty ? "—" : currentValue)
                labeledRow("Validation", validationDescription)
                if inputKind == .mac {
                    labeledRow("Raw hex", MACKeyboardInput.normalizedMACHex(mac).isEmpty ? "—" : MACKeyboardInput.normalizedMACHex(mac))
                }
            }

            Section("Submitted") {
                if submitted.isEmpty {
                    Text("Complete an address, then tap submit.")
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

    @ViewBuilder
    private var keyboard: some View {
        switch inputKind {
            case .ipv4:
                IPv4KeyboardInput(
                    $ipv4,
                    validationState: $ipv4ValidationState,
                    autoFocus: true
                ) {
                    submitIPv4()
                }
            case .mac:
                MACKeyboardInput(
                    $mac,
                    validationState: $macValidationState,
                    separatorStyle: macSeparator,
                    autoFocus: true
                ) {
                    submitMAC()
                }
        }
    }

    private var currentValue: String {
        switch inputKind {
            case .ipv4: ipv4
            case .mac: mac
        }
    }

    private var currentValidationState: NetworkAwareTextField.ValidationState {
        switch inputKind {
            case .ipv4: ipv4ValidationState
            case .mac: macValidationState
        }
    }

    private var validationDescription: String {
        switch currentValidationState {
            case .empty: "empty"
            case .ipv4: "valid IPv4"
            case .ipv6: "valid IPv6"
            case .macAddress(_, let format): "valid MAC (\(format))"
            case .hostname: "hostname"
            case .checking: "checking"
            case .invalid: "invalid"
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

    private func submitIPv4() {
        guard !ipv4.isEmpty else { return }
        submitted.insert("IPv4 \(ipv4)", at: 0)
        ipv4 = ""
    }

    private func submitMAC() {
        guard !mac.isEmpty else { return }
        submitted.insert("MAC \(mac)", at: 0)
        mac = ""
    }

    private enum IPv4Preset: String, CaseIterable, Identifiable {
        case empty
        case router
        case localhost
        case dns
        case adapter

        var id: String { rawValue }

        var title: String {
            switch self {
                case .empty: "Empty"
                case .router: "Router"
                case .localhost: "Localhost"
                case .dns: "DNS"
                case .adapter: "Adapter"
            }
        }

        var value: String {
            switch self {
                case .empty: ""
                case .router: "192.168.0.1"
                case .localhost: "127.0.0.1"
                case .dns: "8.8.8.8"
                case .adapter: "169.254.12.44"
            }
        }
    }

    private enum MACPreset: String, CaseIterable, Identifiable {
        case empty
        case apple
        case local
        case broadcast

        var id: String { rawValue }

        var title: String {
            switch self {
                case .empty: "Empty"
                case .apple: "Apple"
                case .local: "Local"
                case .broadcast: "Broadcast"
            }
        }

        var value: String {
            switch self {
                case .empty: ""
                case .apple: "A4:C1:38:2F:90:01"
                case .local: "02:00:00:00:00:01"
                case .broadcast: "FF:FF:FF:FF:FF:FF"
            }
        }
    }
}

#Preview {
    NetworkKeyboardDemoView()
}
