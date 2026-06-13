import SwiftUI
import Foundation
import CornucopiaCore
import VIN

// MARK: - VIN Validation (backed by the VIN package)

/// Returns true if the character is valid for a VIN (excludes I, O, Q).
func isValidVINCharacter(_ char: Character) -> Bool {
    guard let scalar = String(char).uppercased().unicodeScalars.first else { return false }
    return VIN.AllowedCharacters.contains(scalar)
}

/// Whether a VIN's 9th position is a mandatory ISO 3779 check digit.
///
/// Thin SwiftUI-facing adapter over `VIN.requiresCheckDigit`: only North American VINs
/// carry a mandatory check digit, so input controls must not require a digit/`X` at
/// position 9 — nor flag it — for VINs from other regions (e.g. the `Z` filler in VW
/// VINs). The region classification itself lives in the `VIN` package.
func vinRequiresCheckDigit(_ vin: String) -> Bool {
    VIN(content: vin).requiresCheckDigit
}

/// Validates VIN length and characters, producing a UI-oriented validation state.
///
/// A complete VIN with a mismatching check digit is reported as
/// `.validWithCheckDigitWarning` rather than invalid, because checksum
/// verification is not mandatory in every region (notably parts of Asia and
/// Europe) — the VIN is still structurally usable.
func validateVIN(_ vin: String) -> VINTextField.ValidationState {
    let trimmed = vin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if trimmed.isEmpty {
        return .empty
    }
    if trimmed.count > 17 {
        return .tooLong(trimmed)
    }
    for char in trimmed where !isValidVINCharacter(char) {
        return .invalidCharacters(trimmed)
    }
    if trimmed.count < 17 {
        return .incomplete(trimmed, remaining: 17 - trimmed.count)
    }

    let model = VIN(content: trimmed)
    let components = parseVINComponents(trimmed)
    if model.isChecksumValid {
        return .valid(trimmed, components: components)
    }
    return .validWithCheckDigitWarning(trimmed, components: components, expectedCheckDigit: model.expectedCheckDigit ?? "?")
}

/// Parses a full VIN into its display components via the VIN package.
func parseVINComponents(_ vin: String) -> VINComponents {
    guard vin.count == 17 else {
        return VINComponents(wmi: "", vds: "", vis: "", modelYear: nil)
    }
    let model = VIN(content: vin)
    return VINComponents(
        wmi: model.wmi,
        vds: model.vds,
        vis: model.vis,
        modelYear: model.modelYear.map(String.init)
    )
}

// MARK: - VIN Components

public struct VINComponents: Equatable {
    public let wmi: String      // World Manufacturer Identifier (positions 1-3)
    public let vds: String      // Vehicle Descriptor Section (positions 4-9)
    public let vis: String      // Vehicle Identifier Section (positions 10-17)
    public let modelYear: String?
    
    public init(wmi: String, vds: String, vis: String, modelYear: String?) {
        self.wmi = wmi
        self.vds = vds
        self.vis = vis
        self.modelYear = modelYear
    }
}

// MARK: - Model Year

extension VINTextField {
    /// Model year decoded from a (partial) VIN, disambiguated by position 7.
    ///
    /// Prefer this over ``modelYear(forPosition10:)`` whenever the surrounding VIN
    /// characters are available: it reads position 7 to pick the correct 30-year window.
    public static func modelYear(for vin: String) -> String? {
        VIN(content: vin).modelYear.map(String.init)
    }

    /// Model year guessed from position 10 alone, assuming a position-7-letter
    /// (2010–2039) VIN. Ambiguous by nature — use ``modelYear(for:)`` when the full VIN
    /// prefix is known so the 30-year cycle can be resolved via position 7.
    public static func modelYear(forPosition10 character: Character) -> String? {
        VIN(content: String(repeating: "A", count: 9) + String(character)).modelYear.map(String.init)
    }
}

// MARK: - SwiftUI View

/// A free-text VIN field with validation feedback.
///
/// Use this when VIN entry should behave like a normal text field and let the
/// operating system position the keyboard. Do not place `VINKeyboardInput` next to
/// this field for the same binding. `VINKeyboardInput` is a complete domain input on
/// its own, not a decorative keyboard companion for `VINTextField`.
public struct VINTextField: View {
    
    public enum ValidationState: Equatable {
        case empty
        case incomplete(String, remaining: Int)
        case invalidCharacters(String)
        case tooLong(String)
        case valid(String, components: VINComponents)
        case validWithCheckDigitWarning(String, components: VINComponents, expectedCheckDigit: Character)
        
        public var inputText: String {
            switch self {
            case .empty: ""
            case .incomplete(let vin, _): vin
            case .invalidCharacters(let vin): vin
            case .tooLong(let vin): vin
            case .valid(let vin, _): vin
            case .validWithCheckDigitWarning(let vin, _, _): vin
            }
        }
        
        var inputType: InputType {
            switch self {
            case .empty: .empty
            case .incomplete: .incomplete
            case .invalidCharacters: .invalidCharacters
            case .tooLong: .tooLong
            case .valid: .valid
            case .validWithCheckDigitWarning: .validWithCheckDigitWarning
            }
        }
    }
    
    enum InputType {
        case empty
        case incomplete
        case invalidCharacters
        case tooLong
        case valid
        case validWithCheckDigitWarning
        
        var title: String {
            switch self {
            case .empty: CC_localized("Empty")
            case .incomplete: CC_localized("Incomplete VIN")
            case .invalidCharacters: CC_localized("Invalid Characters")
            case .tooLong: CC_localized("Too Long")
            case .valid: CC_localized("Valid VIN")
            case .validWithCheckDigitWarning: CC_localized("Valid VIN")
            }
        }
        
        var systemImage: String {
            switch self {
            case .empty: "text.cursor"
            case .incomplete: "doc.text"
            case .invalidCharacters: "exclamationmark.triangle"
            case .tooLong: "exclamationmark.circle"
            case .valid: "checkmark.circle"
            case .validWithCheckDigitWarning: "checkmark.circle.trianglebadge.exclamationmark"
            }
        }
        
        var color: Color {
            switch self {
            case .empty: .secondary
            case .incomplete: .orange
            case .invalidCharacters: .red
            case .tooLong: .red
            case .valid: .green
            case .validWithCheckDigitWarning: .yellow
            }
        }
    }
    
    @State private var internalText: String = ""
    @State private var validationState: ValidationState = .empty
    
    private let externalTextBinding: Binding<String>?
    private let focusedBinding: FocusState<Bool>.Binding?
    private let validationStateBinding: Binding<ValidationState>?
    
    private var text: Binding<String> {
        externalTextBinding ?? $internalText
    }
    
    public init(text: Binding<String>? = nil, focused: FocusState<Bool>.Binding? = nil, validationState: Binding<ValidationState>? = nil) {
        self.externalTextBinding = text
        self.focusedBinding = focused
        self.validationStateBinding = validationState
    }
    
    /// Convenience initializer for binding to a string
    public init(_ text: Binding<String>) {
        self.init(text: text)
    }
    
    /// Convenience initializer with focus binding
    public init(_ text: Binding<String>, focused: FocusState<Bool>.Binding) {
        self.init(text: text, focused: focused)
    }
    
    /// Convenience initializer with validation state binding
    public init(_ text: Binding<String>, validationState: Binding<ValidationState>) {
        self.init(text: text, validationState: validationState)
    }
    
    /// Full convenience initializer
    public init(_ text: Binding<String>, focused: FocusState<Bool>.Binding, validationState: Binding<ValidationState>) {
        self.init(text: text, focused: focused, validationState: validationState)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: validationState.inputType.systemImage)
                    .foregroundStyle(validationState.inputType.color)
                
                Text(validationState.inputType.title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(validationState.inputType.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(validationState.inputType.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                Spacer()
                
                // Show character count
                if !text.wrappedValue.isEmpty {
                    Text("\(text.wrappedValue.count)/17")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            
            HStack {
                Group {
                    if let focusedBinding = focusedBinding {
                        TextField("Enter 17-character VIN", text: text)
                            .focused(focusedBinding)
                    } else {
                        TextField("Enter 17-character VIN", text: text)
                    }
                }
                #if os(iOS)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .keyboardType(.asciiCapable)
                #endif
                .font(.system(.body, design: .monospaced))
                .onChange(of: text.wrappedValue) { _, newValue in
                    let filtered = String(newValue.uppercased().prefix(17).filter { isValidVINCharacter($0) })
                    if filtered != newValue {
                        text.wrappedValue = filtered
                    }
                    updateValidationState(filtered)
                }
                
                // Clear button
                if !text.wrappedValue.isEmpty {
                    Button {
                        text.wrappedValue = ""
                        updateValidationState("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(validationState.inputType.color.opacity(validationState.inputType == .empty ? 0.3 : 0.8), lineWidth: 1.5)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(validationState.inputType.color.opacity(0.05))
            )
            .animation(.easeInOut(duration: 0.15), value: validationState.inputType)
            
            // VIN breakdown with spacing
            if case .valid(_, let components) = validationState {
                VStack(alignment: .leading, spacing: 8) {
                    Text(CC_localized("VIN Breakdown"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        VINComponentView(label: "WMI", value: components.wmi, color: .blue)
                        VINComponentView(label: "VDS", value: components.vds, color: .purple)
                        VINComponentView(label: "VIS", value: components.vis, color: .green)
                    }

                    if let modelYear = components.modelYear {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(CC_localized("Model Year: \(modelYear)"))
                                .font(.footnote)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            } else if case .validWithCheckDigitWarning(_, let components, let expectedCheckDigit) = validationState {
                VStack(alignment: .leading, spacing: 8) {
                    Text(CC_localized("VIN Breakdown"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        VINComponentView(label: "WMI", value: components.wmi, color: .blue)
                        VINComponentView(label: "VDS", value: components.vds, color: .purple)
                        VINComponentView(label: "VIS", value: components.vis, color: .green)
                    }

                    if let modelYear = components.modelYear {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(CC_localized("Model Year: \(modelYear)"))
                                .font(.footnote)
                                .foregroundStyle(.primary)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text(CC_localized("Check digit mismatch (expected: \(String(expectedCheckDigit)))"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            } else if case .incomplete(let vin, let remaining) = validationState, !vin.isEmpty {
                // Show partial breakdown for incomplete VIN
                VStack(alignment: .leading, spacing: 8) {
                    Text(CC_localized("Partial VIN (\(remaining) characters remaining)"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        if vin.count >= 3 {
                            VINComponentView(label: "WMI", value: String(vin.prefix(3)), color: .blue)
                        }
                        if vin.count > 3 {
                            let vdsLength = min(6, vin.count - 3)
                            let vds = String(vin.dropFirst(3).prefix(vdsLength))
                            VINComponentView(label: "VDS", value: vds, color: .purple, isPartial: vdsLength < 6)
                        }
                        if vin.count > 9 {
                            let vis = String(vin.dropFirst(9))
                            VINComponentView(label: "VIS", value: vis, color: .green, isPartial: vis.count < 8)
                        }
                    }
                }
            }
            
            // Status messages
            Group {
                switch validationState {
                case .empty:
                    Text(CC_localized("Vehicle Identification Number (VIN) - 17 characters"))
                case .incomplete(_, let remaining):
                    Text(CC_localized("Enter \(remaining) more characters to complete VIN"))
                case .invalidCharacters:
                    Text(CC_localized("VIN cannot contain I, O, or Q characters"))
                case .tooLong:
                    Text(CC_localized("VIN must be exactly 17 characters"))
                case .valid:
                    Text(CC_localized("Valid VIN with correct check digit"))
                case .validWithCheckDigitWarning:
                    Text(CC_localized("Check digit validation is optional in some regions"))
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .onChange(of: validationState) { _, newState in
            validationStateBinding?.wrappedValue = newState
        }
        .task {
            // Validate any pre-populated value so the status reflects the initial
            // text instead of staying `.empty` until the first edit.
            updateValidationState(text.wrappedValue)
        }
    }

    private func updateValidationState(_ vin: String) {
        validationState = validateVIN(vin)
    }
}

// MARK: - VIN Component View

private struct VINComponentView: View {
    let label: String
    let value: String
    let color: Color
    var isPartial: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(color)
                if isPartial {
                    Image(systemName: "ellipsis")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(value.isEmpty ? "—" : formatVINComponent(value, label: label))
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }
    
    private func formatVINComponent(_ value: String, label: String) -> String {
        switch label {
        case "WMI":
            return value
        case "VDS":
            // Add space before check digit (position 6 in VDS, position 9 overall)
            if value.count >= 6 {
                let prefix = String(value.prefix(5))
                let checkDigit = String(value.suffix(1))
                return "\(prefix) \(checkDigit)"
            }
            return value
        case "VIS":
            // Add spaces for better readability: year-plant-serial (1-1-6)
            if value.count >= 8 {
                let year = String(value.prefix(1))
                let plant = String(value.dropFirst(1).prefix(1))
                let serial = String(value.suffix(6))
                return "\(year) \(plant) \(serial)"
            } else if value.count >= 2 {
                let year = String(value.prefix(1))
                let rest = String(value.dropFirst(1))
                return "\(year) \(rest)"
            }
            return value
        default:
            return value
        }
    }
}

// MARK: - Preview

struct VINTextField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Demo 1: Basic usage
                VStack(alignment: .leading) {
                    Text("Basic VIN Entry:")
                        .font(.headline)
                    BasicVINDemo()
                        .padding()
                }
                
                // Demo 2: With validation state binding
                VStack(alignment: .leading) {
                    Text("With Validation State Monitoring:")
                        .font(.headline)
                    ValidationStateDemo()
                        .padding()
                }
                
                // Demo 3: Test various VIN states
                VStack(alignment: .leading) {
                    Text("Various VIN Examples:")
                        .font(.headline)
                    VINExamplesDemo()
                        .padding()
                }
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Preview Demos

struct BasicVINDemo: View {
    @State private var vin = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VINTextField($vin, focused: $isFocused)
            
            HStack {
                Button("Clear") {
                    vin = ""
                }
                .disabled(vin.isEmpty)
                
                Button("Sample VIN") {
                    vin = "1HGCM82633A123456"
                }
                
                Button("Focus") {
                    isFocused = true
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

struct ValidationStateDemo: View {
    @State private var vin = ""
    @State private var validationState: VINTextField.ValidationState = .empty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VINTextField($vin, validationState: $validationState)
            
            Text("Current State: \(stateDescription)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }
    
    private var stateDescription: String {
        switch validationState {
        case .empty: "Empty"
        case .incomplete(_, let remaining): "Incomplete (\(remaining) remaining)"
        case .invalidCharacters: "Invalid Characters"
        case .tooLong: "Too Long"
        case .valid: "Valid VIN"
        case .validWithCheckDigitWarning(_, _, let expectedCheckDigit): "Valid VIN (check digit warning: expected \(expectedCheckDigit))"
        }
    }
}

struct VINExamplesDemo: View {
    @State private var vinExamples: [String] = [
        "",
        "1HGC",
        "1HGCM82633A123456",
        "INVALIDCHARSIOQ123",
        "1HGCM82633A1234567890"
    ]
    @State private var selectedExample = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Different VIN States:")
                .font(.caption.weight(.medium))
            
            Picker("VIN Example", selection: $selectedExample) {
                Text("Empty").tag(0)
                Text("Incomplete (4 chars)").tag(1)
                Text("Valid VIN").tag(2)
                Text("Invalid characters").tag(3)
                Text("Too long").tag(4)
            }
            .pickerStyle(.segmented)
            
            VINTextField(Binding(
                get: { vinExamples[selectedExample] },
                set: { vinExamples[selectedExample] = $0 }
            ))
        }
    }
}
