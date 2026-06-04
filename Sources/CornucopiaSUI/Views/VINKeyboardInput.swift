//
//  VINKeyboardInput.swift
//  CornucopiaSUI
//

import SwiftUI
#if canImport(UIKit)
import AudioToolbox
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// A VIN input control with a domain-specific, QWERTZ/QWERTY-oriented keypad.
///
/// `VINKeyboardInput` keeps the bound value normalized to uppercase VIN
/// characters, omits the invalid `I`, `O`, and `Q` keys, groups the value as
/// WMI/VDS/VIS, and highlights the check-digit position while typing.
///
/// - Important: Do not pair this control with `VINTextField` or any other field that
///   mirrors the same VIN value. A `*KeyboardInput` is already the visible value
///   display, focus target, normalization boundary, keypad, hardware-keyboard bridge,
///   scanner entry point, and submit surface. Rendering a matching field above it
///   creates two competing input controls for one value, breaks the mental model, and
///   usually leaves the keypad floating in the middle of unrelated layout. If an app
///   needs an OS-positioned VIN keyboard, use `VINKeyboardTextField`, which installs
///   this keypad as the field's real `inputView`; do not compose `VINTextField` and
///   `VINKeyboardInput` side by side or one above the other.
public struct VINKeyboardInput: View {

    public enum KeyboardLayout {
        case qwertz
        case qwerty
        case azerty
    }

    @State private var internalText = ""
    @State private var validationState: VINTextField.ValidationState = .empty
    @State private var vehicleDetails: VINVehicleDetails?
    @State private var isDecodingVehicle = false
    @State private var isScanningVIN = false
#if canImport(UIKit)
    @State private var feedbackPerformer = VINKeyboardFeedbackPerformer()
#endif
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isInputFocused: Bool

    private let externalTextBinding: Binding<String>?
    private let focusedBinding: FocusState<Bool>.Binding?
    private let validationStateBinding: Binding<VINTextField.ValidationState>?
    private let keyboardLayout: KeyboardLayout
    private let placeholder: String
    private let submitSystemImage: String
    private let autoFocus: Bool
    private let isSubmitEnabled: Bool
    private let showsDisplay: Bool
    private let usesInternalFocus: Bool
    private let vehicleDecoder: VINVehicleDecoder?
    private let onSubmit: (() -> Void)?

    private var text: Binding<String> {
        externalTextBinding ?? $internalText
    }

    /// Creates a VIN input with a custom VIN keypad.
    ///
    /// - Parameters:
    ///   - text: Optional external VIN binding. The value is normalized to uppercase
    ///     VIN characters and truncated to 17 characters.
    ///   - focused: Optional focus binding for parent-managed focus.
    ///   - validationState: Optional validation state binding.
    ///   - keyboardLayout: Letter layout used by the custom keypad.
    ///   - placeholder: Placeholder shown while the VIN is empty.
    ///   - submitSystemImage: SF Symbol used for the submit key.
    ///   - autoFocus: When `true`, the control claims focus when it appears.
    ///   - isSubmitEnabled: External enablement flag for submit.
    ///   - showsDisplay: Whether the control renders its own VIN/WMI/VDS/VIS display.
    ///     Keep this enabled for the standalone control and for input-method hosting
    ///     when the domain breakdown belongs to the keyboard surface.
    ///   - usesInternalFocus: Whether the control owns focus and installs its SwiftUI
    ///     hardware-keyboard bridge. Disable this only when hosting the control as a
    ///     real UIKit `inputView`, where the attached text field must remain first
    ///     responder.
    ///   - onSubmit: Called when the submit key is tapped or Return is pressed.
    public init(
        text: Binding<String>? = nil,
        focused: FocusState<Bool>.Binding? = nil,
        validationState: Binding<VINTextField.ValidationState>? = nil,
        keyboardLayout: KeyboardLayout = .qwertz,
        placeholder: String = "Enter VIN",
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        showsDisplay: Bool = true,
        usesInternalFocus: Bool = true,
        vehicleDecoder: VINVehicleDecoder? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.externalTextBinding = text
        self.focusedBinding = focused
        self.validationStateBinding = validationState
        self.keyboardLayout = keyboardLayout
        self.placeholder = placeholder
        self.submitSystemImage = submitSystemImage
        self.autoFocus = autoFocus
        self.isSubmitEnabled = isSubmitEnabled
        self.showsDisplay = showsDisplay
        self.usesInternalFocus = usesInternalFocus
        self.vehicleDecoder = vehicleDecoder
        self.onSubmit = onSubmit
    }

    /// Convenience initializer for binding to a VIN string.
    public init(
        _ text: Binding<String>,
        keyboardLayout: KeyboardLayout = .qwertz,
        placeholder: String = "Enter VIN",
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        showsDisplay: Bool = true,
        usesInternalFocus: Bool = true,
        vehicleDecoder: VINVehicleDecoder? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.init(
            text: text,
            keyboardLayout: keyboardLayout,
            placeholder: placeholder,
            submitSystemImage: submitSystemImage,
            autoFocus: autoFocus,
            isSubmitEnabled: isSubmitEnabled,
            showsDisplay: showsDisplay,
            usesInternalFocus: usesInternalFocus,
            vehicleDecoder: vehicleDecoder,
            onSubmit: onSubmit
        )
    }

    /// Convenience initializer with focus binding.
    public init(
        _ text: Binding<String>,
        focused: FocusState<Bool>.Binding,
        keyboardLayout: KeyboardLayout = .qwertz,
        placeholder: String = "Enter VIN",
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        showsDisplay: Bool = true,
        usesInternalFocus: Bool = true,
        vehicleDecoder: VINVehicleDecoder? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.init(
            text: text,
            focused: focused,
            keyboardLayout: keyboardLayout,
            placeholder: placeholder,
            submitSystemImage: submitSystemImage,
            autoFocus: autoFocus,
            isSubmitEnabled: isSubmitEnabled,
            showsDisplay: showsDisplay,
            usesInternalFocus: usesInternalFocus,
            vehicleDecoder: vehicleDecoder,
            onSubmit: onSubmit
        )
    }

    /// Convenience initializer with validation state binding.
    public init(
        _ text: Binding<String>,
        validationState: Binding<VINTextField.ValidationState>,
        keyboardLayout: KeyboardLayout = .qwertz,
        placeholder: String = "Enter VIN",
        submitSystemImage: String = "checkmark",
        autoFocus: Bool = false,
        isSubmitEnabled: Bool = true,
        showsDisplay: Bool = true,
        usesInternalFocus: Bool = true,
        vehicleDecoder: VINVehicleDecoder? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.init(
            text: text,
            validationState: validationState,
            keyboardLayout: keyboardLayout,
            placeholder: placeholder,
            submitSystemImage: submitSystemImage,
            autoFocus: autoFocus,
            isSubmitEnabled: isSubmitEnabled,
            showsDisplay: showsDisplay,
            usesInternalFocus: usesInternalFocus,
            vehicleDecoder: vehicleDecoder,
            onSubmit: onSubmit
        )
    }

    public var body: some View {
        if usesInternalFocus {
            content
                .CC_keypadHardwareInput(
                    internalFocus: $isInputFocused,
                    externalFocus: focusedBinding,
                    handleKeyPress: handleKeyPress,
                    handleDelete: deleteLastCharacter,
                    handleSubmit: submit,
                    handlePaste: paste
                )
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 8) {
            if showsDisplay {
                display
            }
            keypad
        }
        .padding(10)
        .background(.bar)
        .contentShape(Rectangle())
        .onTapGesture {
            requestFocus()
        }
        .task {
            if autoFocus, usesInternalFocus {
                requestFocus()
            }
            normalizeBoundText()
        }
        .task(id: decodeKey) {
            await decodeVehicleDetails()
        }
        .onChange(of: text.wrappedValue) { _ in
            normalizeBoundText()
        }
        .onChange(of: validationState) { newState in
            validationStateBinding?.wrappedValue = newState
        }
    }

    private var display: some View {
        HStack(spacing: 0) {
            slotMatrix
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .padding(.vertical, 10)

            Button {
                clear()
            } label: {
                Image(systemName: "xmark")
                    .font(.callout.weight(.bold))
                    .frame(width: 44, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(KeypadInlineButtonStyle(isEnabled: !text.wrappedValue.isEmpty))
            .disabled(text.wrappedValue.isEmpty)
            .accessibilityLabel(CC_localized("Clear VIN"))
        }
        .background(displayBackground)
    }

    /// Lays out 17 fixed character slots so every typed character sits directly on
    /// top of its slot marker, with static WMI/VDS/VIS group labels above.
    private var slotMatrix: some View {
        GeometryReader { geometry in
            let cellSpacing: CGFloat = 3
            let groupSpacing: CGFloat = 14
            let available = geometry.size.width - cellSpacing * 14 - groupSpacing * 2
            let cellWidth = max(1, available / 17)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    groupLabel("WMI", count: 3, color: .blue, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer().frame(width: groupSpacing)
                    groupLabel("VDS", count: 6, color: .orange, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer().frame(width: groupSpacing)
                    groupLabel("VIS", count: 8, color: .green, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer(minLength: 0)
                }

                HStack(spacing: 0) {
                    slotGroup(0..<3, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer().frame(width: groupSpacing)
                    slotGroup(3..<9, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer().frame(width: groupSpacing)
                    slotGroup(9..<17, cellWidth: cellWidth, cellSpacing: cellSpacing)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: 54)
        // The individual slots are accessibilityHidden; surface the value as one element
        // that reads the entered characters (spelled out) so VoiceOver users hear the VIN.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CC_localized("VIN"))
        .accessibilityValue(vinAccessibilityValue)
    }

    /// The entered VIN spelled character-by-character for VoiceOver (so "WV…" is read as
    /// letters, not as a word), or a spoken "empty" placeholder.
    private var vinAccessibilityValue: String {
        let vin = text.wrappedValue
        guard !vin.isEmpty else { return CC_localized("empty") }
        return vin.map(String.init).joined(separator: " ")
    }

    private func groupLabel(_ label: String, count: Int, color: Color, cellWidth: CGFloat, cellSpacing: CGFloat) -> some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .frame(width: cellWidth * CGFloat(count) + cellSpacing * CGFloat(count - 1), alignment: .leading)
    }

    private func slotGroup(_ range: Range<Int>, cellWidth: CGFloat, cellSpacing: CGFloat) -> some View {
        HStack(spacing: cellSpacing) {
            ForEach(range, id: \.self) { index in
                slotCell(at: index, width: cellWidth)
            }
        }
    }

    private func slotCell(at index: Int, width: CGFloat) -> some View {
        VStack(spacing: 5) {
            Text(character(at: index))
                .font(.system(.callout, design: .monospaced).weight(.medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)

            Capsule(style: .continuous)
                .fill(slotColor(at: index))
                .frame(height: 4)
                .overlay {
                    if index == activeIndex {
                        TimelineView(.animation) { context in
                            Capsule(style: .continuous)
                                .fill(activeMarkerColor)
                                .opacity(activeMarkerOpacity(at: context.date))
                        }
                    }
                }
        }
        .frame(width: width)
        .accessibilityHidden(true)
    }

    /// The slot index awaiting the next character, or `nil` when the VIN is full.
    private var activeIndex: Int? {
        let count = text.wrappedValue.count
        return count < 17 ? count : nil
    }

    private var activeMarkerColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private func activeMarkerOpacity(at date: Date) -> Double {
        let phase = (sin(date.timeIntervalSinceReferenceDate * .pi * 0.95) + 1) / 2
        return 0.24 + phase * 0.68
    }

    /// Semantic group color for a slot position (WMI / VDS / VIS).
    private func groupColor(at index: Int) -> Color {
        switch index {
            case 0..<3:
                .blue
            case 3..<9:
                .orange
            default:
                .green
        }
    }

    private func character(at index: Int) -> String {
        let value = text.wrappedValue
        guard index < value.count else { return " " }
        return String(value[value.index(value.startIndex, offsetBy: index)])
    }

    private func slotColor(at index: Int) -> Color {
        let count = text.wrappedValue.count
        let group = groupColor(at: index)

        // Empty baseline: a faint tint of the slot's own group color so the WMI/VDS/VIS
        // sections read as such before anything is typed. The active slot's emphasis is
        // layered on top by the pulsing overlay.
        guard count > index else {
            return group.opacity(colorScheme == .dark ? 0.30 : 0.22)
        }

        // Filled slot. Error states recolor the whole field so the warning is
        // unambiguous; an accepted character instead wears its own group color so the
        // three sections stay distinguishable rather than collapsing into one validation
        // color (previously every typed character turned the incomplete-orange, which
        // read as "everything is VDS").
        switch validationState.inputType {
            case .invalidCharacters, .tooLong:
                return .red
            case .validWithCheckDigitWarning where index == 8:
                return .yellow
            default:
                return slotForeground(group)
        }
    }

    /// A valid character's underscore in its group color. Brightened slightly in dark
    /// mode and deepened in light mode so the accepted character always sits a notch
    /// stronger than the faint empty placeholder, against either background.
    private func slotForeground(_ group: Color) -> Color {
        colorScheme == .dark
            ? group.opacity(0.95)
            : group.opacity(0.85)
    }

    private var displayBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(displayBorderColor, lineWidth: 1)
            }
    }

    private var displayBorderColor: Color {
        switch validationState {
            case .empty:
                Color.primary.opacity(0.16)
            case .incomplete:
                Color.primary.opacity(0.22)
            case .valid:
                Color.green.opacity(0.65)
            case .validWithCheckDigitWarning:
                Color.orange.opacity(0.75)
            case .invalidCharacters, .tooLong:
                Color.red.opacity(0.75)
        }
    }

    /// The keyboard and the camera live on opposite faces of a single card that flips
    /// about its vertical axis. Both faces stay mounted and the height is pinned, so the
    /// swap never inserts, removes, or re-lays-out a view — only the rotation and the
    /// mid-flip back-face cull animate. Keeping the rotation a persistent modifier rather
    /// than a `.transition` also means the live camera's transform is never torn down at
    /// the end of the animation, which previously snapped the preview into place.
    private var keypad: some View {
        KeypadFlipCard(
            flipProgress: isScanningVIN ? 1 : 0,
            front: keypadKeys,
            back: scannerPane
        )
        .frame(height: Self.keypadFlipHeight)
        .animation(.easeInOut(duration: 0.42), value: isScanningVIN)
    }

    /// Height shared by both faces. Matches the keypad's intrinsic height (five 42-pt key
    /// rows plus four 6-pt gaps) so the card never resizes as it flips.
    private static let keypadFlipHeight: CGFloat = 234

    private var keypadKeys: some View {
        VStack(spacing: 6) {
            keypadRow(numberKeys)

            ForEach(Array(letterRows.enumerated()), id: \.offset) { _, row in
                keypadRow(row)
            }

            HStack(spacing: 6) {
                analysisPreview
                Spacer(minLength: 0)
                cameraKey
                deleteKey
                submitKey
            }
            .animation(.easeInOut(duration: 0.25), value: previewIdentity)
            .animation(.easeInOut(duration: 0.25), value: vehicleDetails)
            .animation(.easeInOut(duration: 0.25), value: isDecodingVehicle)
            .animation(.easeInOut(duration: 0.25), value: offlineModelYear)
        }
    }

    private var scannerPane: some View {
        ZStack(alignment: .topTrailing) {
            // Solid backing so the back face reads as a deliberate dark panel before the
            // camera delivers its first frames and while it flips away after a scan.
            Color.black

            scannerPreview

            Button {
                stopScanning()
            } label: {
                Image(systemName: "xmark")
                    .font(.callout.weight(.bold))
                    .frame(width: 40, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(KeypadKeyStyle(role: VINKeyboardKeyRole.action))
            .padding(8)
            .accessibilityLabel(CC_localized("Stop VIN scan"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.45), lineWidth: 1)
        }
    }

    /// The camera face is always part of the flip card, but the capture session must run
    /// only while it is actually shown — so the scanner is mounted strictly while
    /// `isScanningVIN`, leaving just the dark backing behind the hidden face otherwise.
    @ViewBuilder
    private var scannerPreview: some View {
#if canImport(VisionKit) && os(iOS)
        if #available(iOS 16.0, *) {
            if isScanningVIN {
                VINScannerView { vin in
                    acceptScannedVIN(vin)
                }
                .overlay(alignment: .bottomLeading) {
                    scannerCaption
                }
            }
        } else if isScanningVIN {
            scannerUnavailable
        }
#else
        if isScanningVIN {
            scannerUnavailable
        }
#endif
    }

    private var scannerCaption: some View {
        Label(CC_localized("Scan VIN"), systemImage: "viewfinder")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.black.opacity(0.55), in: Capsule(style: .continuous))
            .padding(10)
    }

    private var scannerUnavailable: some View {
        VStack(spacing: 8) {
            Image(systemName: "camera.slash")
                .font(.title2)
            Text(CC_localized("Camera scanner unavailable"))
                .font(.caption.weight(.semibold))
            Text(CC_localized("Enter the VIN with the keypad."))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.12))
    }

    /// Decoded country/manufacturer for the current input, or `nil` when not yet
    /// identifiable. Used both for rendering and as the animation trigger.
    private var previewIdentity: VINIdentity? {
        VINIdentity.decoding(text.wrappedValue)
    }

    /// The shared analysis column left of the delete/return keys. The offline identity
    /// (country, manufacturer, model year) builds up additively as the VIN is typed and
    /// stays put — including while the online lookup is running. Only once the decoder has
    /// actually identified the vehicle do the richer make/model facts supersede and replace
    /// it; a sparse or failed lookup leaves the country/manufacturer untouched.
    @ViewBuilder
    private var analysisPreview: some View {
        if hasOnlineVehicleDecode {
            vehiclePreview
        } else if let identity = previewIdentity {
            identityColumn(identity)
        } else if isDecodingVehicle {
            vehiclePreview
        }
    }

    /// True once the online decoder has actually identified the vehicle (a non-empty
    /// make). Only then do the make/model details replace the offline country/manufacturer
    /// preview — an empty or failed lookup (e.g. a manufacturer NHTSA doesn't know) keeps
    /// the identity visible instead of collapsing the column to a bare model year.
    private var hasOnlineVehicleDecode: Bool {
        guard let make = vehicleDetails?.make else { return false }
        return !make.isEmpty
    }

    private func identityColumn(_ identity: VINIdentity) -> some View {
        HStack(spacing: 8) {
            Text(identity.flag)
                .font(.title2)

            VStack(alignment: .leading, spacing: 1) {
                MarqueeText(identity.countryName, startDelay: 2)
                    .font(.caption.weight(.medium))
                    .frame(width: Self.identityColumnWidth)

                if let detail = identitySubline(identity) {
                    MarqueeText(detail, startDelay: 2)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: Self.identityColumnWidth)
                } else if isDecodingVehicle {
                    vehicleLookupIndicator
                }
            }
        }
        .padding(.leading, 4)
        .transition(.opacity.combined(with: .move(edge: .leading)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(identityAccessibilityLabel(identity))
    }

    /// Manufacturer and offline model year shown beneath the country, so the identity
    /// grows additively as more of the VIN is typed rather than being replaced by a bare
    /// year once the model-year position is reached.
    private func identitySubline(_ identity: VINIdentity) -> String? {
        let parts = [identity.manufacturer, offlineModelYear]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func identityAccessibilityLabel(_ identity: VINIdentity) -> String {
        [identity.countryName, identitySubline(identity)]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private static let identityColumnWidth: CGFloat = 150

    private static var showsDecorativeVehicleIcon: Bool {
#if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
#else
        true
#endif
    }

    /// The vehicle widget that occupies the shared analysis column once enough of the
    /// VIN is present to decode. It shows the offline-derived model year and make
    /// immediately, marks the online lookup in progress, and enriches with the model and
    /// vehicle type once NHTSA responds (long values scroll via `MarqueeText`).
    @ViewBuilder
    private var vehiclePreview: some View {
        HStack(spacing: 8) {
            // The icon is purely decorative; the cramped iPhone field cannot spare the
            // width for it, so it is shown only where there is room (iPad, macOS, …).
            if Self.showsDecorativeVehicleIcon {
                Image(systemName: "car.side")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            vehiclePreviewContent
                .frame(width: Self.identityColumnWidth, alignment: .leading)
        }
        .padding(.leading, 4)
        .transition(.opacity.combined(with: .move(edge: .leading)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(vehicleAccessibilityLabel)
    }

    @ViewBuilder
    private var vehiclePreviewContent: some View {
        if let headline = vehicleHeadline {
            VStack(alignment: .leading, spacing: 1) {
                MarqueeText(headline, startDelay: 2)
                    .font(.caption.weight(.semibold))
                    .frame(width: Self.identityColumnWidth)

                if let subline = vehicleSubline {
                    MarqueeText(subline, startDelay: 2)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: Self.identityColumnWidth)
                } else if isDecodingVehicle {
                    vehicleLookupIndicator
                }
            }
        } else if isDecodingVehicle {
            vehicleLookupIndicator
        } else {
            Text(CC_localized("No vehicle details"))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var vehicleLookupIndicator: some View {
        HStack(spacing: 4) {
            ProgressView()
                .controlSize(.mini)
            Text(CC_localized("Looking up…"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// Year/make/model headline, combining the offline VIN-derived year and manufacturer
    /// with the richer online make and model once they arrive.
    private var vehicleHeadline: String? {
        let year = vehicleDetails?.modelYear ?? offlineModelYear
        let make = vehicleDetails?.make?.capitalized ?? previewIdentity?.manufacturer
        let parts = [year, make, vehicleDetails?.model]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    /// Vehicle type and body class, available only from the online decode.
    private var vehicleSubline: String? {
        guard let details = vehicleDetails else { return nil }
        let parts = [details.vehicleType?.capitalized, details.bodyClass]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Model year derived offline from VIN position 10, available as soon as ten
    /// characters are present and used as a fallback when the online decode omits it.
    private var offlineModelYear: String? {
        let vin = text.wrappedValue
        guard vin.count >= 10 else { return nil }
        let character = vin[vin.index(vin.startIndex, offsetBy: 9)]
        return VINTextField.modelYear(forPosition10: character)
    }

    private var vehicleAccessibilityLabel: String {
        guard let headline = vehicleHeadline else {
            return isDecodingVehicle ? CC_localized("Looking up vehicle") : ""
        }
        if let subline = vehicleSubline {
            return "\(headline), \(subline)"
        }
        return headline
    }

    private func keypadRow(_ keys: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                vinKey(key)
            }
        }
    }

    private func vinKey(_ key: String) -> some View {
        KeypadKey(title: key, role: keyRole(for: key), isEnabled: isKeyEnabled(key), accessibilityLabel: CC_localized("VIN \(key)")) {
            append(key)
        }
    }

    /// At each position only the characters valid there stay enabled. For North American
    /// VINs the 9th position is a check digit and accepts digits and `X` only; a full VIN
    /// disables every key.
    private func isKeyEnabled(_ key: String) -> Bool {
        guard text.wrappedValue.count < 17 else { return false }
        guard isCheckDigitPosition, enforcesCheckDigit else { return true }
        return key == "X" || key.allSatisfy(\.isNumber)
    }

    private var deleteKey: some View {
        Button {
            deleteLastCharacter()
        } label: {
            Image(systemName: "delete.left")
                .font(.title3.weight(.semibold))
                .frame(width: 58, height: 42)
        }
        .buttonStyle(KeypadKeyStyle(role: VINKeyboardKeyRole.action))
        .disabled(text.wrappedValue.isEmpty)
        .accessibilityLabel(CC_localized("Delete"))
    }

    @ViewBuilder
    private var cameraKey: some View {
        if Self.isVINCameraScanningSupported {
            Button {
                startScanning()
            } label: {
                Image(systemName: "camera.viewfinder")
                    .font(.title3.weight(.semibold))
                    .frame(width: 58, height: 42)
            }
            .buttonStyle(KeypadKeyStyle(role: VINKeyboardKeyRole.action))
            .accessibilityLabel(CC_localized("Scan VIN with camera"))
        }
    }

    private var submitKey: some View {
        Button {
            submit()
        } label: {
            Image(systemName: submitSystemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 58, height: 42)
        }
        .buttonStyle(KeypadKeyStyle(role: canSubmit ? VINKeyboardKeyRole.submit : .action))
        .disabled(!canSubmit)
        .accessibilityLabel(CC_localized("Submit VIN"))
    }

    private var numberKeys: [String] {
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    }

    private var letterRows: [[String]] {
        switch keyboardLayout {
            case .qwertz:
                [
                    ["W", "E", "R", "T", "Z", "U", "P"],
                    ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
                    ["Y", "X", "C", "V", "B", "N", "M"]
                ]
            case .qwerty:
                [
                    ["W", "E", "R", "T", "Y", "U", "P"],
                    ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
                    ["Z", "X", "C", "V", "B", "N", "M"]
                ]
            case .azerty:
                [
                    ["A", "Z", "E", "R", "T", "Y", "U", "P"],
                    ["S", "D", "F", "G", "H", "J", "K", "L", "M"],
                    ["W", "X", "C", "V", "B", "N"]
                ]
        }
    }

    private func keyRole(for key: String) -> VINKeyboardKeyRole {
        if isCheckDigitPosition && enforcesCheckDigit && (key == "X" || key.allSatisfy(\.isNumber)) {
            return .checkDigit
        }

        return key.allSatisfy(\.isNumber) ? .digit : .letter
    }

    private var isCheckDigitPosition: Bool {
        text.wrappedValue.count == 8
    }

    /// Whether the 9th position should be gated and flagged as a check digit. True only
    /// for North American VINs; elsewhere that position holds free-form characters (e.g.
    /// the `Z` filler in VW VINs), which the keypad must not block.
    private var enforcesCheckDigit: Bool {
        vinRequiresCheckDigit(text.wrappedValue)
    }

    private var canSubmit: Bool {
        isSubmitEnabled && text.wrappedValue.count == 17
    }

    private func append(_ character: String) {
        guard text.wrappedValue.count < 17 else { return }
        guard let first = character.first, isValidVINCharacter(first) else { return }
        text.wrappedValue.append(String(first).uppercased())
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func deleteLastCharacter() {
        guard !text.wrappedValue.isEmpty else { return }
        text.wrappedValue.removeLast()
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func clear() {
        guard !text.wrappedValue.isEmpty else { return }
        text.wrappedValue = ""
        updateValidationState()
        requestFocus()
        feedback()
    }

    private func submit() {
        guard canSubmit else { return }
        onSubmit?()
        isScanningVIN = false
        isInputFocused = false
        focusedBinding?.wrappedValue = false
        feedback()
    }

    private func startScanning() {
        isScanningVIN = true
        isInputFocused = false
        focusedBinding?.wrappedValue = false
        feedback()
    }

    private func stopScanning() {
        isScanningVIN = false
        requestFocus()
        feedback()
    }

    private func acceptScannedVIN(_ vin: String) {
        text.wrappedValue = vin
        updateValidationState()
        isScanningVIN = false
        requestFocus()
        scanSuccessFeedback()
    }

    private func handleKeyPress(_ characters: String) -> Bool {
        var didHandle = false
        for character in characters {
            let normalized = String(character).uppercased()
            guard let first = normalized.first, isValidVINCharacter(first) else { continue }
            append(String(first))
            didHandle = true
        }
        return didHandle
    }

    /// Replaces the value with the normalized clipboard contents. Pasting overwrites rather
    /// than appends, matching how a full VIN is usually transferred from another source.
    private func paste() -> Bool {
        guard let pasted = keypadPasteboardString, !pasted.isEmpty else { return false }
        let normalized = Self.normalizedVIN(pasted)
        guard !normalized.isEmpty else { return false }
        text.wrappedValue = normalized
        updateValidationState()
        requestFocus()
        feedback()
        return true
    }

    private func normalizeBoundText() {
        let normalized = Self.normalizedVIN(text.wrappedValue)
        if text.wrappedValue != normalized {
            text.wrappedValue = normalized
        }
        updateValidationState()
    }

    private func updateValidationState() {
        let previous = validationState.inputType
        validationState = validateVIN(text.wrappedValue)
        let current = validationState.inputType
        // Announce only when the state meaningfully changes, so VoiceOver users hear
        // "Valid VIN" / a warning / an error without a remark on every keystroke.
        if current != previous, let phrase = validationAnnouncement(for: current) {
            announce(phrase)
        }
    }

    private func validationAnnouncement(for type: VINTextField.InputType) -> String? {
        switch type {
            case .valid:
                CC_localized("Valid VIN")
            case .validWithCheckDigitWarning:
                CC_localized("Valid VIN, check digit warning")
            case .invalidCharacters:
                CC_localized("Invalid characters")
            case .tooLong:
                CC_localized("VIN too long")
            case .empty, .incomplete:
                nil
        }
    }

    /// Posts a VoiceOver announcement (no-op where UIKit accessibility is unavailable).
    private func announce(_ message: String) {
        guard !message.isEmpty else { return }
#if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
#endif
    }

    /// The VIN prefix that determines the vehicle, or `nil` when enrichment is off or too
    /// few characters are present. Make, model descriptor and model year occupy positions
    /// 1–10; positions 11–17 are the plant and serial number and never change the decode.
    /// Keying off only the first ten characters means deleting the serial number leaves the
    /// key — and the displayed vehicle — untouched, so we never re-query the backend for an
    /// answer we already have. Editing within 1–10 does change the key, which is correct:
    /// the vehicle identity genuinely changed. Driving `.task(id:)` with this also cancels
    /// stale lookups and debounces edits for free.
    private var decodeKey: String? {
        guard vehicleDecoder != nil else { return nil }
        let vin = text.wrappedValue
        return vin.count >= 10 ? String(vin.prefix(10)) : nil
    }

    private func decodeVehicleDetails() async {
        guard let vin = decodeKey, let vehicleDecoder else {
            // Below the decode threshold (or disabled): drop back to the offline identity.
            vehicleDetails = nil
            return
        }
        // Keep any previous details on screen while re-decoding so editing the decode-
        // relevant part shows a spinner over the old value instead of flickering to empty.
        try? await Task.sleep(nanoseconds: 600_000_000)
        guard !Task.isCancelled else { return }
        isDecodingVehicle = true
        defer { isDecodingVehicle = false }
        let details = try? await vehicleDecoder(vin)
        guard !Task.isCancelled else { return }
        vehicleDetails = details
        // Once the online lookup actually identifies the vehicle, speak it — it appears
        // silently otherwise and VoiceOver users would miss the enrichment.
        if let details, !(details.make ?? "").isEmpty, let headline = vehicleHeadline {
            announce(headline)
        }
    }

    private func requestFocus() {
        guard usesInternalFocus else { return }
        isInputFocused = true
        focusedBinding?.wrappedValue = true
    }

    private func feedback() {
#if canImport(UIKit)
        feedbackPerformer.perform(usesSystemInputClick: !usesInternalFocus)
#endif
    }

    private func scanSuccessFeedback() {
#if canImport(UIKit)
        feedbackPerformer.performScanSuccess()
#endif
    }

    /// Returns uppercase VIN characters only, truncated to 17 characters.
    public static func normalizedVIN(_ input: String) -> String {
        String(input.uppercased().filter { isValidVINCharacter($0) }.prefix(17))
    }
}

#if canImport(UIKit)
@MainActor
private final class VINKeyboardFeedbackPerformer {

    init() {}

    func perform(usesSystemInputClick: Bool) {
        if usesSystemInputClick {
            UIDevice.current.playInputClick()
        } else {
            AudioServicesPlaySystemSound(1104)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            impactFeedback.impactOccurred(intensity: 0.75)
        }
    }

    func performScanSuccess() {
        AudioServicesPlaySystemSound(1057)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.9)
    }
}
#endif

/// A card whose two faces share the same footprint and flip about the vertical axis.
///
/// `flipProgress` runs `0` (front) → `1` (back); conforming to `Animatable` on it makes
/// SwiftUI re-evaluate the body at every interpolated step, so the back-face cull lands
/// exactly at the geometric midpoint (90°) and only one face is ever visible — no
/// ghosting of one face through the other. The rotation is a persistent modifier rather
/// than a transition, so neither face's layer is added or torn down mid-flip; a live
/// camera hosted on the back face therefore settles without the projection snapping off
/// when the animation ends.
private struct KeypadFlipCard<Front: View, Back: View>: View, Animatable {

    var flipProgress: Double
    let front: Front
    let back: Back

    var animatableData: Double {
        get { flipProgress }
        set { flipProgress = newValue }
    }

    private var angle: Double { flipProgress * 180 }
    private var showsBack: Bool { angle >= 90 }

    var body: some View {
        ZStack {
            front
                .opacity(showsBack ? 0 : 1)
                .accessibilityHidden(showsBack)

            // Pre-rotated a half turn so it reads upright once the card lands at 180°.
            back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showsBack ? 1 : 0)
                .accessibilityHidden(!showsBack)
        }
        .rotation3DEffect(
            .degrees(angle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.6
        )
    }
}

private enum VINKeyboardKeyRole {
    case letter
    case digit
    case checkDigit
    case action
    case submit

    func foreground(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .letter:
                Color.primary
            case .digit:
                Color.primary
            case .checkDigit:
                colorScheme == .dark ? Color(red: 1, green: 0.86, blue: 0.58) : Color.orange
            case .action:
                Color.primary.opacity(0.76)
            case .submit:
                Color.white
        }
    }

    func background(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .letter:
                Color.primary.opacity(0.08)
            case .digit:
                Color.secondary.opacity(0.16)
            case .checkDigit:
                colorScheme == .dark ? Color.orange.opacity(0.24) : Color.orange.opacity(0.16)
            case .action:
                Color.secondary.opacity(0.22)
            case .submit:
                Color.accentColor
        }
    }

    func pressedBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .letter:
                Color.primary.opacity(0.22)
            case .digit:
                Color.secondary.opacity(0.3)
            case .checkDigit:
                colorScheme == .dark ? Color.orange.opacity(0.34) : Color.orange.opacity(0.28)
            case .action:
                Color.secondary.opacity(0.34)
            case .submit:
                Color.accentColor.opacity(0.78)
        }
    }

    func border(for colorScheme: ColorScheme) -> Color {
        switch self {
            case .letter:
                Color.primary.opacity(0.06)
            case .digit:
                Color.secondary.opacity(0.14)
            case .checkDigit:
                Color.orange.opacity(colorScheme == .dark ? 0.64 : 0.35)
            case .action:
                Color.secondary.opacity(0.18)
            case .submit:
                Color.accentColor.opacity(0.85)
        }
    }
}

extension VINKeyboardKeyRole: KeypadKeyRole {
    func colors(for colorScheme: ColorScheme) -> KeypadKeyColors {
        KeypadKeyColors(
            foreground: foreground(for: colorScheme),
            background: background(for: colorScheme),
            pressedBackground: pressedBackground(for: colorScheme),
            border: border(for: colorScheme)
        )
    }
}

private struct VINKeyboardInputPreview: View {

    enum Scenario {
        case empty
        case partial
        case checkDigit
        case complete
        case dark
    }

    @State private var vin: String

    private let scenario: Scenario

    init(_ scenario: Scenario) {
        self.scenario = scenario
        self._vin = State(initialValue: Self.initialVIN(for: scenario))
    }

    var body: some View {
        VStack(spacing: 16) {
            previewHeader
            Spacer()
            VINKeyboardInput(
                $vin,
                keyboardLayout: keyboardLayout,
                autoFocus: false
            ) {}
        }
        .padding()
        .frame(width: 390, height: 620)
        .background(Color.gray.opacity(0.12))
        .preferredColorScheme(scenario == .dark ? .dark : nil)
    }

    private var previewHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(previewTitle)
                .font(.headline)
            Text(vin.isEmpty ? "Empty VIN" : vin)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var keyboardLayout: VINKeyboardInput.KeyboardLayout {
        switch scenario {
            case .complete:
                .qwerty
            default:
                .qwertz
        }
    }

    private static func initialVIN(for scenario: Scenario) -> String {
        switch scenario {
            case .empty:
                ""
            case .partial:
                "WVWZZZ"
            case .checkDigit:
                "WVWZZZ1K"
            case .complete:
                "1HGCM82633A123456"
            case .dark:
                "WVWZZZ1KZ"
        }
    }

    private var previewTitle: String {
        switch scenario {
            case .empty:
                "QWERTZ VIN Keyboard"
            case .partial:
                "Partial VIN"
            case .checkDigit:
                "Check Digit Position"
            case .complete:
                "QWERTY Complete VIN"
            case .dark:
                "Dark Terminal VIN Keyboard"
        }
    }
}

#Preview("VIN Keyboard Empty") {
    VINKeyboardInputPreview(.empty)
}

#Preview("VIN Keyboard Partial") {
    VINKeyboardInputPreview(.partial)
}

#Preview("VIN Keyboard Check Digit") {
    VINKeyboardInputPreview(.checkDigit)
}

#Preview("VIN Keyboard QWERTY Complete") {
    VINKeyboardInputPreview(.complete)
}

#Preview("VIN Keyboard Dark") {
    VINKeyboardInputPreview(.dark)
}
