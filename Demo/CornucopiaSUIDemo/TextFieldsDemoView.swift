//
//  TextFieldsDemoView.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import SwiftUI

struct TextFieldsDemoView: View {
    @State private var username = "service-tech"
    @State private var password = "secret"
    @State private var email = "diagnostics@example.com"
    @State private var endpoint = "192.168.0.10"
    @State private var vin = "1HGCM82633A004352"
    @State private var networkState: NetworkAwareTextField.ValidationState = .empty
    @State private var vinState: VINTextField.ValidationState = .empty

    var body: some View {
        DemoScroll {
            DemoPanel("StyledTextField", subtitle: "Small branded fields for sign-in and configuration forms.") {
                VStack(spacing: 14) {
                    StyledTextField.username(text: $username)
                        .demoID("textfield.username")
                    StyledTextField.password(text: $password)
                        .demoID("textfield.password")
                    StyledTextField.email(text: $email)
                        .demoID("textfield.email")
                }
            }

            DemoPanel("NetworkAwareTextField", subtitle: "Validates hostnames, IP addresses and MAC addresses as the value changes.") {
                VStack(spacing: 12) {
                    NetworkAwareTextField($endpoint, allowedTypes: .all, validationState: $networkState)
                        .demoID("textfield.network")
                    HStack {
                        Button("Router") { endpoint = "192.168.0.1" }
                        Button("Hostname") { endpoint = "example.local" }
                        Button("MAC") { endpoint = "A4:C1:38:2F:90:01" }
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    DemoMetric(title: "State", value: networkStateDescription)
                }
            }

            DemoPanel("VINTextField", subtitle: "Free-text VIN entry with normalization, grouping and check-digit state.") {
                VStack(spacing: 12) {
                    VINTextField($vin, validationState: $vinState)
                        .demoID("textfield.vin")
                    HStack {
                        Button("Valid") { vin = "1HGCM82633A004352" }
                        Button("Warning") { vin = "5YJ3E1EA7JF005252" }
                        Button("Partial") { vin = "WBA3A5C50C" }
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    DemoMetric(title: "State", value: vinStateDescription)
                }
            }
        }
    }

    private var networkStateDescription: String {
        switch networkState {
            case .empty: "empty"
            case .ipv4(let value, _): "IPv4 \(value)"
            case .ipv6(let value, _): "IPv6 \(value)"
            case .macAddress(let value, let format): "MAC \(value) (\(format))"
            case .hostname(let value, let ips): ips.isEmpty ? "host \(value)" : "host \(value) -> \(ips.joined(separator: ", "))"
            case .checking(let value): "checking \(value)"
            case .invalid(let value): "invalid \(value)"
        }
    }

    private var vinStateDescription: String {
        switch vinState {
            case .empty: "empty"
            case .incomplete(_, let remaining): "incomplete, \(remaining) left"
            case .invalidCharacters: "invalid characters"
            case .tooLong: "too long"
            case .valid(_, let components): "valid \(components.wmi)-\(components.vds)-\(components.vis)"
            case .validWithCheckDigitWarning(_, _, let expected): "valid, expected \(expected)"
        }
    }
}

#Preview {
    NavigationStack {
        TextFieldsDemoView()
    }
}
