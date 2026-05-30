//
//  HexKeyboardDemoView.swift
//  InputMethodsDemo
//

import CornucopiaSUI
import SwiftUI

struct HexKeyboardDemoView: View {

    @State private var payload = ""
    @State private var sent: [String] = []
    @State private var returnKey: ReturnKeyOption = .send

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
                Divider()
                HexKeyboardInput(
                    $payload,
                    placeholder: "Hex payload",
                    returnKey: returnKey.value,
                    autoFocus: true,
                    minimumNibbleCount: 1,
                    requiresEvenNibbleCount: true
                ) {
                    send()
                }
            }
            .navigationTitle("Hex Keyboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Return key", selection: $returnKey) {
                        ForEach(ReturnKeyOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    private var content: some View {
        List {
            Section("Live State") {
                labeledRow("Raw binding", payload.isEmpty ? "—" : payload)
                labeledRow("Grouped", HexKeyboardInput.groupedHex(payload).isEmpty ? "—" : HexKeyboardInput.groupedHex(payload))
                labeledRow("Bytes", byteSummary)
            }

            Section("Sent Payloads") {
                if sent.isEmpty {
                    Text("Tap the send key to log a payload.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(sent.enumerated()), id: \.offset) { _, entry in
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

    private var byteSummary: String {
        guard let bytes = HexKeyboardInput.byteArray(from: payload) else { return "—" }
        return "[" + bytes.map { String(format: "%02X", $0) }.joined(separator: " ") + "]"
    }

    private func send() {
        let grouped = HexKeyboardInput.groupedHex(payload)
        guard !grouped.isEmpty else { return }
        sent.insert(grouped, at: 0)
        payload = ""
    }

    enum ReturnKeyOption: String, CaseIterable, Identifiable {
        case send
        case next
        case done
        case hidden

        var id: String { rawValue }

        var title: String {
            switch self {
                case .send: "Send"
                case .next: "Next"
                case .done: "Done"
                case .hidden: "Hidden"
            }
        }

        var value: HexKeyboardInput.ReturnKey {
            switch self {
                case .send: .send
                case .next: .next
                case .done: .done
                case .hidden: .hidden
            }
        }
    }
}

#Preview {
    HexKeyboardDemoView()
}
