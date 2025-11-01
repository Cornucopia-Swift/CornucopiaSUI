import SwiftUI
import Foundation
import Network

// MARK: - Network Input Classification


// MARK: - Configuration

public struct NetworkInputOptions: OptionSet {
    public let rawValue: Int
    
    public static let hostname    = NetworkInputOptions(rawValue: 1 << 0)
    public static let ipv4        = NetworkInputOptions(rawValue: 1 << 1)
    public static let ipv6        = NetworkInputOptions(rawValue: 1 << 2)
    public static let macAddress  = NetworkInputOptions(rawValue: 1 << 3)
    
    public static let all: NetworkInputOptions = [.hostname, .ipv4, .ipv6, .macAddress]
    public static let ipAddresses: NetworkInputOptions = [.ipv4, .ipv6]
    public static let ipAndHostname: NetworkInputOptions = [.hostname, .ipv4, .ipv6]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

// MARK: - Validators

/// Returns true if s is a well-formed IPv4 address (dotted-quad, 0–255 each)
/// Strictly requires dotted-quad notation to avoid confusing behavior with single numbers
func isIPv4(_ s: String) -> Bool {
    // Quick reject
    if s.isEmpty || s.contains(":") { return false }
    // Require at least one dot to avoid single numbers being treated as IPs
    if !s.contains(".") { return false }
    let parts = s.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 4 else { return false }
    for p in parts {
        // disallow empty components like "1..1.1"
        if p.isEmpty || p.count > 3 { return false }
        // only digits
        if p.contains(where: { !$0.isNumber }) { return false }
        // no leading zeros unless single "0"
        if p.count > 1 && p.first == "0" { return false }
        guard let n = Int(p), n >= 0 && n <= 255 else { return false }
    }
    return true
}

/// Returns true if s is a valid textual IPv6 address (including compressed forms).
/// Uses inet_pton which correctly handles the grammar. Accepts optional "%scope".
func isIPv6(_ s: String) -> Bool {
    if s.isEmpty { return false }
    // Strip zone/scope id (e.g., "fe80::1%en0")
    let core = s.split(separator: "%", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? s
    var buf = in6_addr()
    return core.withCString { cstr in inet_pton(AF_INET6, cstr, &buf) == 1 }
}

/// Returns true if s is a valid MAC address (supports colon, dash, and dot notations)
/// Returns the format type if valid, nil otherwise
func isMACAddress(_ s: String) -> String? {
    if s.isEmpty { return nil }
    
    let uppercase = s.uppercased()
    
    // Try colon notation (AA:BB:CC:DD:EE:FF)
    if uppercase.contains(":") {
        let parts = uppercase.split(separator: ":", omittingEmptySubsequences: false)
        if parts.count == 6 {
            let isValid = parts.allSatisfy { part in
                part.count == 2 && part.allSatisfy { ch in
                    (ch >= "0" && ch <= "9") || (ch >= "A" && ch <= "F")
                }
            }
            if isValid { return "IEEE 802" }  // Colon notation
        }
    }
    
    // Try dash notation (AA-BB-CC-DD-EE-FF)
    if uppercase.contains("-") {
        let parts = uppercase.split(separator: "-", omittingEmptySubsequences: false)
        if parts.count == 6 {
            let isValid = parts.allSatisfy { part in
                part.count == 2 && part.allSatisfy { ch in
                    (ch >= "0" && ch <= "9") || (ch >= "A" && ch <= "F")
                }
            }
            if isValid { return "Windows" }  // Dash notation
        }
    }
    
    // Try dot notation (AABB.CCDD.EEFF)
    if uppercase.contains(".") {
        let parts = uppercase.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count == 3 {
            let isValid = parts.allSatisfy { part in
                part.count == 4 && part.allSatisfy { ch in
                    (ch >= "0" && ch <= "9") || (ch >= "A" && ch <= "F")
                }
            }
            if isValid { return "Cisco" }  // Dot notation
        }
    }
    
    // Try no delimiter notation (AABBCCDDEEFF)
    if uppercase.count == 12 {
        let isValid = uppercase.allSatisfy { ch in
            (ch >= "0" && ch <= "9") || (ch >= "A" && ch <= "F")
        }
        if isValid { return "Compact" }  // No delimiter notation
    }
    
    return nil
}

/// Basic syntactic check for potential hostname (RFC LDH rule), but does not guarantee resolvability.
/// This is used as a first-pass filter before attempting DNS resolution.
func couldBeHostname(_ s: String) -> Bool {
    if s.isEmpty { return false }
    // cannot be an IP or MAC
    if isIPv4(s) || isIPv6(s) || isMACAddress(s) != nil { return false }
    // reject single characters/digits (like "1", "a") - not meaningful hostnames
    if s.count == 1 { return false }
    // reject pure numbers (like "26510") - DNS resolvers may interpret as 32-bit IP addresses
    if s.allSatisfy({ $0.isNumber }) { return false }
    // whitespace or illegal chars quick reject
    let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._")
    if s.unicodeScalars.contains(where: { !allowed.contains($0) }) { return false }
    if s.count > 253 { return false }
    let labels = s.split(separator: ".", omittingEmptySubsequences: false)
    // no empty labels at ends like ".example." or consecutive dots
    if labels.isEmpty || labels.contains(where: { $0.isEmpty }) { return false }
    for label in labels {
        if label.count < 1 || label.count > 63 { return false }
        if label.first == "-" || label.last == "-" { return false }
        let ok = label.allSatisfy { ch in
            (ch.isLetter || ch.isNumber || ch == "-")
        }
        if !ok { return false }
    }
    return true
}

func classifyNetworkInputSync(_ s: String, allowedTypes: NetworkInputOptions) -> (NetworkAwareTextField.InputType, String?) {
    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return (.empty, nil) }
    
    if allowedTypes.contains(.ipv4) && isIPv4(trimmed) { return (.ipv4, nil) }
    if allowedTypes.contains(.ipv6) && isIPv6(trimmed) { return (.ipv6, nil) }
    if allowedTypes.contains(.macAddress), let format = isMACAddress(trimmed) { return (.macAddress, format) }
    if allowedTypes.contains(.hostname) && couldBeHostname(trimmed) { return (.checking, nil) }
    
    return (.invalid, nil)
}

// MARK: - DNS Resolution

@MainActor
public class NetworkInputValidator: ObservableObject {
    @Published public var validationState: NetworkAwareTextField.ValidationState = .empty
    @Published var inputType: NetworkAwareTextField.InputType = .empty
    @Published var resolvedIPs: [String] = []
    @Published var resolvedHostname: String = ""
    @Published var lastCheckedInput: String = ""
    @Published var macFormat: String? = nil
    public let allowedTypes: NetworkInputOptions
    private var debounceTask: Task<Void, Never>?
    
    private func updateValidationState() {
        let newState: NetworkAwareTextField.ValidationState = switch inputType {
            case .empty:
                .empty
            case .ipv4:
                .ipv4(lastCheckedInput, hostname: resolvedHostname.isEmpty ? nil : resolvedHostname)
            case .ipv6:
                .ipv6(lastCheckedInput, hostname: resolvedHostname.isEmpty ? nil : resolvedHostname)
            case .macAddress:
                .macAddress(lastCheckedInput, format: macFormat ?? "Unknown")
            case .hostname:
                .hostname(lastCheckedInput, resolvedIPs: resolvedIPs)
            case .checking:
                .checking(lastCheckedInput)
            case .invalid:
                .invalid(lastCheckedInput)
        }
        print("🔄 Updating validation state from \(validationState) to \(newState)")
        validationState = newState
    }
    
    public init(allowedTypes: NetworkInputOptions = .all) {
        self.allowedTypes = allowedTypes
    }
    
    public func validate(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        print("⚡ Validating: '\(trimmed)' (last was: '\(lastCheckedInput)')")
        guard trimmed != lastCheckedInput else { 
            print("⚡ Skipping validation - same as last input")
            return 
        }
        
        // Cancel previous debounce task
        debounceTask?.cancel()
        
        lastCheckedInput = trimmed
        
        // First do synchronous classification
        let (syncType, format) = classifyNetworkInputSync(trimmed, allowedTypes: allowedTypes)
        inputType = syncType
        macFormat = format
        updateValidationState()
        
        // Handle different input types
        if syncType == .checking {
            // Potential hostname - verify with DNS (debounced)
            debounceTask = Task {
                // Debounce for 500ms to avoid excessive DNS lookups
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                
                let ips = await performDNSLookup(hostname: trimmed)
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    if trimmed == self.lastCheckedInput {
                        if ips.isEmpty {
                            self.inputType = .invalid
                            self.resolvedIPs = []
                            self.resolvedHostname = ""
                        } else {
                            self.inputType = .hostname
                            self.resolvedIPs = ips
                            self.resolvedHostname = ""
                        }
                        self.updateValidationState()
                    }
                }
            }
        } else if syncType == .ipv4 || syncType == .ipv6 {
            // IP address - perform reverse DNS lookup (debounced)
            debounceTask = Task {
                // Debounce for 500ms
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                
                let hostname = await performReverseDNSLookup(ip: trimmed)
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    if trimmed == self.lastCheckedInput {
                        self.resolvedHostname = hostname
                        self.resolvedIPs = []
                        self.updateValidationState()
                    }
                }
            }
        } else {
            resolvedIPs = []
            resolvedHostname = ""
        }
    }
    
    public func clear() {
        inputType = .empty
        resolvedIPs = []
        resolvedHostname = ""
        lastCheckedInput = ""
        macFormat = nil
        debounceTask?.cancel()
        updateValidationState()
    }
    
    private func performDNSLookup(hostname: String) async -> [String] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: UnsafeMutablePointer<addrinfo>?
                var hints = addrinfo()
                hints.ai_family = AF_UNSPEC // Allow both IPv4 and IPv6
                hints.ai_socktype = SOCK_STREAM
                
                let status = getaddrinfo(hostname, nil, &hints, &result)
                defer { freeaddrinfo(result) }
                
                guard status == 0, let result = result else {
                    continuation.resume(returning: [])
                    return
                }
                
                var ips: [String] = []
                var current: UnsafeMutablePointer<addrinfo>? = result
                
                while let currentPtr = current {
                    guard let addr = currentPtr.pointee.ai_addr else {
                        current = currentPtr.pointee.ai_next
                        continue
                    }
                    let family = currentPtr.pointee.ai_family
                    
                    if family == AF_INET {
                        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                        let sockAddr = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0 }
                        if inet_ntop(AF_INET, &sockAddr.pointee.sin_addr, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil {
                            ips.append(String(cString: buffer))
                        }
                    } else if family == AF_INET6 {
                        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                        let sockAddr = addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0 }
                        if inet_ntop(AF_INET6, &sockAddr.pointee.sin6_addr, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil {
                            ips.append(String(cString: buffer))
                        }
                    }
                    
                    current = currentPtr.pointee.ai_next
                }
                
                continuation.resume(returning: ips)
            }
        }
    }
    
    private func performReverseDNSLookup(ip: String) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var sockAddr: sockaddr_storage = sockaddr_storage()
                var result: UnsafeMutablePointer<CChar>?
                let bufferSize = Int(NI_MAXHOST)
                
                // Convert IP string to sockaddr
                if ip.contains(":") {
                    // IPv6
                    var addr6 = sockaddr_in6()
                    addr6.sin6_family = sa_family_t(AF_INET6)
                    let success = ip.withCString { cstr in
                        inet_pton(AF_INET6, cstr, &addr6.sin6_addr) == 1
                    }
                    if success {
                        withUnsafeBytes(of: addr6) { bytes in
                            withUnsafeMutableBytes(of: &sockAddr) { sockAddrBytes in
                                sockAddrBytes.copyBytes(from: bytes.prefix(MemoryLayout<sockaddr_in6>.size))
                            }
                        }
                    } else {
                        continuation.resume(returning: "")
                        return
                    }
                } else {
                    // IPv4
                    var addr4 = sockaddr_in()
                    addr4.sin_family = sa_family_t(AF_INET)
                    let success = ip.withCString { cstr in
                        inet_pton(AF_INET, cstr, &addr4.sin_addr) == 1
                    }
                    if success {
                        withUnsafeBytes(of: addr4) { bytes in
                            withUnsafeMutableBytes(of: &sockAddr) { sockAddrBytes in
                                sockAddrBytes.copyBytes(from: bytes.prefix(MemoryLayout<sockaddr_in>.size))
                            }
                        }
                    } else {
                        continuation.resume(returning: "")
                        return
                    }
                }
                
                // Perform reverse DNS lookup
                result = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize)
                defer { result?.deallocate() }
                
                let status = withUnsafeBytes(of: &sockAddr) { sockAddrBytes in
                    let sockAddrPtr = sockAddrBytes.bindMemory(to: sockaddr.self).baseAddress!
                    let socklen = ip.contains(":") ? socklen_t(MemoryLayout<sockaddr_in6>.size) : socklen_t(MemoryLayout<sockaddr_in>.size)
                    return getnameinfo(sockAddrPtr, socklen, result, socklen_t(bufferSize), nil, 0, 0)
                }
                
                if status == 0, let result = result {
                    let hostname = String(cString: result)
                    // Don't return the IP itself if reverse lookup just returns the same IP
                    continuation.resume(returning: hostname == ip ? "" : hostname)
                } else {
                    continuation.resume(returning: "")
                }
            }
        }
    }
}

// MARK: - SwiftUI View

public struct NetworkAwareTextField: View {
    
    public enum ValidationState: Equatable {
        case empty
        case ipv4(String, hostname: String?)
        case ipv6(String, hostname: String?)
        case macAddress(String, format: String)
        case hostname(String, resolvedIPs: [String])
        case checking(String)
        case invalid(String)
        
        public var inputText: String {
            switch self {
                case .empty: ""
                case .ipv4(let ip, _): ip
                case .ipv6(let ip, _): ip
                case .macAddress(let mac, _): mac
                case .hostname(let hostname, _): hostname
                case .checking(let input): input
                case .invalid(let input): input
            }
        }
    }
    
    enum InputType {
        case empty
        case ipv4
        case ipv6
        case macAddress
        case hostname
        case checking
        case invalid
        
        var title: String {
            switch self {
                case .empty:      "Empty"
                case .ipv4:       "IPv4 address"
                case .ipv6:       "IPv6 address"
                case .macAddress: "MAC address"
                case .hostname:   "Hostname"
                case .checking:   "Checking…"
                case .invalid:    "Invalid"
            }
        }
        
        /// SF Symbols that ship with iOS
        var systemImage: String {
            switch self {
                case .ipv4:       "number"
                case .ipv6:       "number.circle"
                case .macAddress: "rectangle.connected.to.line.below"
                case .hostname:   "globe"
                case .checking:   "magnifyingglass"
                case .empty:      "text.cursor"
                case .invalid:    "exclamationmark.triangle"
            }
        }
        
        var color: Color {
            switch self {
                case .ipv4:       .blue
                case .ipv6:       .teal
                case .macAddress: .green
                case .hostname:   .purple
                case .checking:   .secondary
                case .empty:      .secondary
                case .invalid:    .orange
            }
        }
    }
    @State private var internalText: String = ""
    @StateObject public var validator: NetworkInputValidator
    let allowedTypes: NetworkInputOptions
    let placeholder: String
    let externalTextBinding: Binding<String>?
    let focusedBinding: FocusState<Bool>.Binding?
    let validationStateBinding: Binding<ValidationState>?
    
    // Text computed property that uses external binding if available
    private var text: Binding<String> {
        externalTextBinding ?? $internalText
    }
    
    public init(allowedTypes: NetworkInputOptions = .all, text: Binding<String>? = nil, focused: FocusState<Bool>.Binding? = nil, validationState: Binding<ValidationState>? = nil) {
        self.allowedTypes = allowedTypes
        self.externalTextBinding = text
        self.focusedBinding = focused
        self.validationStateBinding = validationState
        self._validator = StateObject(wrappedValue: NetworkInputValidator(allowedTypes: allowedTypes))
        
        // Generate placeholder based on allowed types
        var placeholderParts: [String] = []
        if allowedTypes.contains(.hostname) { placeholderParts.append("Hostname") }
        if allowedTypes.contains(.ipv4) { placeholderParts.append("IPv4") }
        if allowedTypes.contains(.ipv6) { placeholderParts.append("IPv6") }
        if allowedTypes.contains(.macAddress) { placeholderParts.append("MAC") }
        
        if placeholderParts.isEmpty {
            self.placeholder = "Enter address"
        } else if placeholderParts.count == 1 {
            self.placeholder = placeholderParts[0]
        } else {
            let last = placeholderParts.removeLast()
            self.placeholder = placeholderParts.joined(separator: ", ") + " or " + last
        }
    }
    
    /// Convenience initializer for binding to a string with default settings
    public init(_ text: Binding<String>, allowedTypes: NetworkInputOptions = .all) {
        self.init(allowedTypes: allowedTypes, text: text)
    }
    
    /// Convenience initializer with focus binding
    public init(_ text: Binding<String>, allowedTypes: NetworkInputOptions = .all, focused: FocusState<Bool>.Binding) {
        self.init(allowedTypes: allowedTypes, text: text, focused: focused)
    }
    
    /// Convenience initializer with validation state binding
    public init(_ text: Binding<String>, allowedTypes: NetworkInputOptions = .all, validationState: Binding<ValidationState>) {
        self.init(allowedTypes: allowedTypes, text: text, validationState: validationState)
    }
    
    /// Full convenience initializer
    public init(_ text: Binding<String>, allowedTypes: NetworkInputOptions = .all, focused: FocusState<Bool>.Binding, validationState: Binding<ValidationState>) {
        self.init(allowedTypes: allowedTypes, text: text, focused: focused, validationState: validationState)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Group {
                    if validator.inputType == .checking {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: validator.inputType.systemImage)
                    }
                }
                .foregroundStyle(validator.inputType.color)
                
                Text(validator.inputType.title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(validator.inputType.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(validator.inputType.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                Spacer()
            }
            
            HStack {
                Group {
                    if let focusedBinding = focusedBinding {
                        TextField(placeholder, text: text)
                            .focused(focusedBinding)
                    } else {
                        TextField(placeholder, text: text)
                    }
                }
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.URL)
                #endif
                .font(.system(.body, design: .monospaced))
                
                // Clear button inside text field
                if !text.wrappedValue.isEmpty {
                    Button {
                        text.wrappedValue = ""
                        validator.clear()
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
                    .strokeBorder(validator.inputType.color.opacity(validator.inputType == .empty ? 0.3 : 0.8), lineWidth: 1.5)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(validator.inputType.color.opacity(0.05))
            )
            .animation(.easeInOut(duration: 0.15), value: validator.inputType)
            
            // Show resolved info under classification
            Group {
                if validator.inputType == .hostname, let firstIP = validator.resolvedIPs.first {
                    HStack(spacing: 6) {
                        Image(systemName: isIPv6(firstIP) ? "number.circle" : "number")
                            .foregroundStyle(isIPv6(firstIP) ? .teal : .blue)
                            .font(.caption)
                        Text(firstIP)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.primary)
                        if validator.resolvedIPs.count > 1 {
                            Text("+\(validator.resolvedIPs.count - 1) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if (validator.inputType == .ipv4 || validator.inputType == .ipv6) && !validator.resolvedHostname.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text(validator.resolvedHostname)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            // Additional resolved IPs (if more than one)
            if validator.inputType == .hostname && validator.resolvedIPs.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All resolved addresses:")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    ForEach(validator.resolvedIPs, id: \.self) { ip in
                        HStack(spacing: 6) {
                            Image(systemName: isIPv6(ip) ? "number.circle" : "number")
                                .foregroundStyle(isIPv6(ip) ? .teal : .blue)
                                .font(.caption)
                            Text(ip)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            
            // Optional: helpful hints
            Group {
                switch validator.inputType {
                case .ipv4:
                    Text("Valid IPv4 address.")
                case .ipv6:
                    Text("Valid IPv6 address. Scope identifiers like %en0 are supported.")
                case .macAddress:
                    if let format = validator.macFormat {
                        Text("Valid MAC address (\(format) format).")
                    } else {
                        Text("Valid MAC address.")
                    }
                case .hostname:
                    Text("Hostname resolved successfully via DNS.")
                case .checking:
                    Text("Checking if hostname can be resolved via DNS…")
                case .invalid:
                    Text(generateInvalidMessage())
                case .empty:
                    EmptyView()
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .onChange(of: text.wrappedValue) { newValue in
            print("🔄 Text changed to: '\(newValue)'")
            validator.validate(newValue)
        }
        .onChange(of: validator.validationState) { newState in
            validationStateBinding?.wrappedValue = newState
        }
    }
    
    private func generateInvalidMessage() -> String {
        var types: [String] = []
        if allowedTypes.contains(.hostname) { types.append("hostname") }
        if allowedTypes.contains(.ipv4) { types.append("IPv4") }
        if allowedTypes.contains(.ipv6) { types.append("IPv6") }
        if allowedTypes.contains(.macAddress) { types.append("MAC address") }
        
        if types.isEmpty {
            return "Invalid input."
        } else if types.count == 1 {
            if allowedTypes.contains(.hostname) {
                return "Not a valid \(types[0]) or cannot be resolved."
            } else {
                return "Not a valid \(types[0])."
            }
        } else {
            let last = types.removeLast()
            let joined = types.joined(separator: ", ")
            if allowedTypes.contains(.hostname) {
                return "Not a valid \(joined) or \(last), or hostname cannot be resolved."
            } else {
                return "Not a valid \(joined) or \(last)."
            }
        }
    }
}

// MARK: - Preview

struct NetworkAwareTextField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Demo 1: Drop-in TextField replacement
                VStack(alignment: .leading) {
                    Text("Drop-in TextField replacement:")
                        .font(.headline)
                    TextFieldReplacementDemo()
                        .padding()
                }
                
                // Demo 2: Type filtering
                VStack(alignment: .leading) {
                    Text("Input type filtering:")
                        .font(.headline)
                    TypeFilteringDemo()
                        .padding()
                }
                
                // Demo 3: Observing validation state
                VStack(alignment: .leading) {
                    Text("Observing validation state:")
                        .font(.headline)
                    AppConfigDemo()
                        .padding()
                }
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Preview Demos

struct TextFieldReplacementDemo: View {
    @State private var oldTextField = ""
    @State private var newTextField = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Before: Regular TextField")
                    .font(.caption.weight(.medium))
                TextField("Server address", text: $oldTextField)
#if os(iOS) || os(macOS)
                    .textFieldStyle(.roundedBorder)
#endif
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("After: NetworkAwareTextField")
                    .font(.caption.weight(.medium))
                NetworkAwareTextField($newTextField)
            }
            
            if !newTextField.isEmpty {
                Text("✓ Auto-validation, DNS lookup, visual feedback")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}

struct AppConfigDemo: View {
    @State private var serverHost = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Server Host:")
                .font(.caption.weight(.medium))
            
            let textField = NetworkAwareTextField($serverHost, allowedTypes: .ipAndHostname)
            textField
                .onAppear {
                    print("🔍 Initial validation state: \(textField.validator.validationState)")
                }
                .onChange(of: textField.validator.validationState) { state in
                    print("🔍 Validation state changed: \(state)")
                }
            
            Text("Check console for validation state changes")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }
}

struct TypeFilteringDemo: View {
    @State private var anyType = ""
    @State private var ipOnly = ""
    @State private var macOnly = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All types (default):")
                .font(.caption.weight(.medium))
            NetworkAwareTextField($anyType)
            
            Text("IP addresses only:")
                .font(.caption.weight(.medium))
            NetworkAwareTextField($ipOnly, allowedTypes: .ipAddresses)
            
            Text("MAC addresses only:")
                .font(.caption.weight(.medium))
            NetworkAwareTextField($macOnly, allowedTypes: .macAddress)
        }
    }
}
