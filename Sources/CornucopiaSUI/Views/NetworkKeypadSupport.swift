//
//  NetworkKeypadSupport.swift
//  CornucopiaSUI
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum NetworkKeyboardKeyRole {
    case digit
    case zero
    case hexLetter
    case separator
    case action
    case submit

    func foreground(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .digit:
                Color.primary
            case .zero:
                Color.white
            case .hexLetter:
                colorScheme == .dark ? Color(red: 0.78, green: 1, blue: 0.86) : Color.green
            case .separator:
                colorScheme == .dark ? Color(red: 0.78, green: 0.9, blue: 1) : Color.blue
            case .action:
                Color.primary.opacity(0.76)
            case .submit:
                Color.white
        }
    }

    func background(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .digit:
                Color.primary.opacity(0.08)
            case .zero:
                Color.accentColor
            case .hexLetter:
                colorScheme == .dark ? Color.green.opacity(0.2) : Color.green.opacity(0.14)
            case .separator:
                colorScheme == .dark ? Color.blue.opacity(0.22) : Color.blue.opacity(0.14)
            case .action:
                Color.secondary.opacity(0.22)
            case .submit:
                Color.accentColor
        }
    }

    func pressedBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .digit:
                Color.primary.opacity(0.22)
            case .zero:
                Color.accentColor.opacity(0.78)
            case .hexLetter:
                colorScheme == .dark ? Color.green.opacity(0.32) : Color.green.opacity(0.26)
            case .separator:
                colorScheme == .dark ? Color.blue.opacity(0.34) : Color.blue.opacity(0.26)
            case .action:
                Color.secondary.opacity(0.34)
            case .submit:
                Color.accentColor.opacity(0.78)
        }
    }

    func border(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .digit:
                Color.primary.opacity(0.06)
            case .zero:
                Color.accentColor.opacity(0.85)
            case .hexLetter:
                Color.green.opacity(colorScheme == .dark ? 0.6 : 0.25)
            case .separator:
                Color.blue.opacity(colorScheme == .dark ? 0.6 : 0.25)
            case .action:
                Color.secondary.opacity(0.18)
            case .submit:
                Color.accentColor.opacity(0.85)
        }
    }
}

extension NetworkKeyboardKeyRole: KeypadKeyRole {
    func colors(for colorScheme: ColorScheme) -> KeypadKeyColors {
        KeypadKeyColors(
            foreground: foreground(for: colorScheme),
            background: background(for: colorScheme),
            pressedBackground: pressedBackground(for: colorScheme),
            border: border(for: colorScheme)
        )
    }
}

extension String {
    func chunked(every size: Int) -> [String] {
        guard size > 0 else { return [self] }
        var chunks: [String] = []
        var index = startIndex
        while index < endIndex {
            let next = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[index..<next]))
            index = next
        }
        return chunks
    }
}

extension Int {
    var isOdd: Bool {
        !isMultiple(of: 2)
    }
}

private struct NetworkKeyboardInputPreview: View {

    enum Scenario {
        case ipv4Empty
        case ipv4Partial
        case ipv4Complete
        case macEmpty
        case macPartial
        case macComplete
        case dark
    }

    @State private var value: String

    private let scenario: Scenario

    init(_ scenario: Scenario) {
        self.scenario = scenario
        self._value = State(initialValue: Self.initialValue(for: scenario))
    }

    var body: some View {
        VStack(spacing: 16) {
            previewHeader
            Spacer()

            switch scenario {
                case .ipv4Empty, .ipv4Partial, .ipv4Complete:
                    IPv4KeyboardInput($value) {}
                case .macEmpty, .macPartial, .macComplete:
                    MACKeyboardInput($value) {}
                case .dark:
                    MACKeyboardInput($value, separatorStyle: .dash) {}
            }
        }
        .padding()
        .frame(width: 390, height: 560)
        .background(Color.gray.opacity(0.12))
        .preferredColorScheme(scenario == .dark ? .dark : nil)
    }

    private var previewHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(value.isEmpty ? "Empty" : value)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: String {
        switch scenario {
            case .ipv4Empty:
                "IPv4 Keyboard"
            case .ipv4Partial:
                "IPv4 Partial"
            case .ipv4Complete:
                "IPv4 Complete"
            case .macEmpty:
                "MAC Keyboard"
            case .macPartial:
                "MAC Partial"
            case .macComplete:
                "MAC Complete"
            case .dark:
                "MAC Keyboard Dark"
        }
    }

    private static func initialValue(for scenario: Scenario) -> String {
        switch scenario {
            case .ipv4Empty:
                ""
            case .ipv4Partial:
                "192.168"
            case .ipv4Complete:
                "192.168.4.42"
            case .macEmpty:
                ""
            case .macPartial:
                "A4:C1:38"
            case .macComplete:
                "A4:C1:38:2F:90:01"
            case .dark:
                "A4-C1-38"
        }
    }
}

#Preview("IPv4 Keyboard Empty") {
    NetworkKeyboardInputPreview(.ipv4Empty)
}

#Preview("IPv4 Keyboard Partial") {
    NetworkKeyboardInputPreview(.ipv4Partial)
}

#Preview("IPv4 Keyboard Complete") {
    NetworkKeyboardInputPreview(.ipv4Complete)
}

#Preview("MAC Keyboard Empty") {
    NetworkKeyboardInputPreview(.macEmpty)
}

#Preview("MAC Keyboard Partial") {
    NetworkKeyboardInputPreview(.macPartial)
}

#Preview("MAC Keyboard Complete") {
    NetworkKeyboardInputPreview(.macComplete)
}

#Preview("MAC Keyboard Dark") {
    NetworkKeyboardInputPreview(.dark)
}
