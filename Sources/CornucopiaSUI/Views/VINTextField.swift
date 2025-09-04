import SwiftUI
import Foundation
import CornucopiaCore

// MARK: - VIN Validation

/// Valid VIN characters (excludes I, O, Q to avoid confusion with 1, 0)
private let validVINCharacters: Set<Character> = Set("ABCDEFGHJKLMNPRSTUVWXYZ0123456789")

/// VIN check digit weights for positions 1-17
private let vinWeights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2]

/// VIN transliteration table for check digit calculation
private let vinTransliteration: [Character: Int] = [
    "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8,
    "J": 1, "K": 2, "L": 3, "M": 4, "N": 5, "P": 7, "R": 9,
    "S": 2, "T": 3, "U": 4, "V": 5, "W": 6, "X": 7, "Y": 8, "Z": 9,
    "0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9
]

/// Model year codes for position 10 (North American standard)
private let modelYearCodes: [Character: String] = [
    "A": "2010", "B": "2011", "C": "2012", "D": "2013", "E": "2014", "F": "2015",
    "G": "2016", "H": "2017", "J": "2018", "K": "2019", "L": "2020", "M": "2021",
    "N": "2022", "P": "2023", "R": "2024", "S": "2025", "T": "2026", "V": "2027",
    "W": "2028", "X": "2029", "Y": "2000", "1": "2001", "2": "2002", "3": "2003",
    "4": "2004", "5": "2005", "6": "2006", "7": "2007", "8": "2008", "9": "2009"
]

/// Returns true if the character is valid for VIN
func isValidVINCharacter(_ char: Character) -> Bool {
    validVINCharacters.contains(char.uppercased().first ?? char)
}

/// Validates VIN length and characters
func validateVIN(_ vin: String) -> VINTextField.ValidationState {
    let trimmed = vin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if trimmed.isEmpty {
        return .empty
    }
    
    // Check length
    if trimmed.count > 17 {
        return .tooLong(trimmed)
    }
    
    // Check for invalid characters
    for char in trimmed {
        if !isValidVINCharacter(char) {
            return .invalidCharacters(trimmed)
        }
    }
    
    if trimmed.count < 17 {
        return .incomplete(trimmed, remaining: 17 - trimmed.count)
    }
    
    // Full VIN - validate check digit
    if isValidCheckDigit(trimmed) {
        let components = parseVINComponents(trimmed)
        return .valid(trimmed, components: components)
    } else {
        return .invalidCheckDigit(trimmed)
    }
}

/// Validates VIN check digit (position 9)
func isValidCheckDigit(_ vin: String) -> Bool {
    guard vin.count == 17 else { return false }
    
    var sum = 0
    for (index, char) in vin.enumerated() {
        guard let value = vinTransliteration[char] else { return false }
        sum += value * vinWeights[index]
    }
    
    let remainder = sum % 11
    let expectedCheckDigit: Character = remainder == 10 ? "X" : Character(String(remainder))
    let actualCheckDigit = vin[vin.index(vin.startIndex, offsetBy: 8)]
    
    if actualCheckDigit != expectedCheckDigit {
        let correctedVIN = String(vin.prefix(8)) + String(expectedCheckDigit) + String(vin.suffix(8))
        let logger = Cornucopia.Core.Logger()
        logger.debug("🚗 VIN check digit validation failed - Original: \(vin), Expected digit: \(expectedCheckDigit) (actual: \(actualCheckDigit)), Suggested corrected VIN: \(correctedVIN)")
        return false
    }
    
    return true
}

/// Parses VIN into its components
func parseVINComponents(_ vin: String) -> VINComponents {
    guard vin.count == 17 else {
        return VINComponents(wmi: "", vds: "", vis: "", modelYear: nil)
    }
    
    let wmi = String(vin.prefix(3))
    let vds = String(vin.dropFirst(3).prefix(6))
    let vis = String(vin.suffix(8))
    
    // Extract model year from position 10
    let modelYearChar = vin[vin.index(vin.startIndex, offsetBy: 9)]
    let modelYear = modelYearCodes[modelYearChar]
    
    return VINComponents(wmi: wmi, vds: vds, vis: vis, modelYear: modelYear)
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

// MARK: - SwiftUI View

public struct VINTextField: View {
    
    public enum ValidationState: Equatable {
        case empty
        case incomplete(String, remaining: Int)
        case invalidCharacters(String)
        case tooLong(String)
        case invalidCheckDigit(String)
        case valid(String, components: VINComponents)
        
        public var inputText: String {
            switch self {
            case .empty: ""
            case .incomplete(let vin, _): vin
            case .invalidCharacters(let vin): vin
            case .tooLong(let vin): vin
            case .invalidCheckDigit(let vin): vin
            case .valid(let vin, _): vin
            }
        }
        
        var inputType: InputType {
            switch self {
            case .empty: .empty
            case .incomplete: .incomplete
            case .invalidCharacters: .invalidCharacters
            case .tooLong: .tooLong
            case .invalidCheckDigit: .invalidCheckDigit
            case .valid: .valid
            }
        }
    }
    
    enum InputType {
        case empty
        case incomplete
        case invalidCharacters
        case tooLong
        case invalidCheckDigit
        case valid
        
        var title: String {
            switch self {
            case .empty: "Empty"
            case .incomplete: "Incomplete VIN"
            case .invalidCharacters: "Invalid Characters"
            case .tooLong: "Too Long"
            case .invalidCheckDigit: "Invalid Check Digit"
            case .valid: "Valid VIN"
            }
        }
        
        var systemImage: String {
            switch self {
            case .empty: "text.cursor"
            case .incomplete: "doc.text"
            case .invalidCharacters: "exclamationmark.triangle"
            case .tooLong: "exclamationmark.circle"
            case .invalidCheckDigit: "checkmark.circle.trianglebadge.exclamationmark"
            case .valid: "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .empty: .secondary
            case .incomplete: .orange
            case .invalidCharacters: .red
            case .tooLong: .red
            case .invalidCheckDigit: .red
            case .valid: .green
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
                .onChange(of: text.wrappedValue) { newValue in
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
            if case .valid(let vin, let components) = validationState {
                VStack(alignment: .leading, spacing: 8) {
                    Text("VIN Breakdown")
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
                            Text("Model Year: \(modelYear)")
                                .font(.footnote)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            } else if case .incomplete(let vin, let remaining) = validationState, !vin.isEmpty {
                // Show partial breakdown for incomplete VIN
                VStack(alignment: .leading, spacing: 8) {
                    Text("Partial VIN (\(remaining) characters remaining)")
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
                    Text("Vehicle Identification Number (VIN) - 17 characters")
                case .incomplete(_, let remaining):
                    Text("Enter \(remaining) more character\(remaining == 1 ? "" : "s") to complete VIN")
                case .invalidCharacters:
                    Text("VIN cannot contain I, O, or Q characters")
                case .tooLong:
                    Text("VIN must be exactly 17 characters")
                case .invalidCheckDigit:
                    Text("Invalid check digit - VIN may contain errors")
                case .valid:
                    Text("Valid VIN with correct check digit")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .onChange(of: validationState) { newState in
            validationStateBinding?.wrappedValue = newState
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
        case .invalidCheckDigit: "Invalid Check Digit"
        case .valid: "Valid VIN"
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
