//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// Style options for the busy indicator
public enum BusyIndicatorStyle {
    case classic           // Traditional spinner
    case modern           // Animated dots
    case pulse            // Pulsing circle
    case orbit            // Orbiting dot
}

/// Execution and presentation options shared by all busy button variants.
public struct BusyButtonOptions {
    public var shrinkToCircle: Bool
    public var indicatorStyle: BusyIndicatorStyle
    public var animation: Animation
    public var cancelTaskOnDisappear: Bool
    public var onError: ((Error) -> Void)?

    public init(
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        animation: Animation = .easeInOut(duration: 0.3),
        cancelTaskOnDisappear: Bool = true,
        onError: ((Error) -> Void)? = nil
    ) {
        self.shrinkToCircle = shrinkToCircle
        self.indicatorStyle = indicatorStyle
        self.animation = animation
        self.cancelTaskOnDisappear = cancelTaskOnDisappear
        self.onError = onError
    }
}

/// Modern animated dots indicator
struct ModernBusyIndicator: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    let phase = (time + Double(index) * 0.16).truncatingRemainder(dividingBy: 0.72) / 0.72
                    let pulse = 0.5 + 0.5 * sin(phase * 2 * .pi)

                    Circle()
                        .fill(Color.primary.opacity(0.55 + pulse * 0.35))
                        .frame(width: 6, height: 6)
                        .scaleEffect(0.75 + pulse * 0.55)
                }
            }
        }
    }
}

/// Pulsing circle indicator
struct PulseBusyIndicator: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let duration = 1.35

            ZStack {
                ForEach(0..<2) { index in
                    let phase = (time + Double(index) * duration / 2).truncatingRemainder(dividingBy: duration) / duration

                    Circle()
                        .stroke(Color.primary.opacity(0.75 * (1 - phase)), lineWidth: 2)
                        .frame(width: 18, height: 18)
                        .scaleEffect(0.55 + phase * 0.85)
                }

                Circle()
                    .fill(Color.primary.opacity(0.82))
                    .frame(width: 6, height: 6)
            }
            .frame(width: 24, height: 24)
        }
    }
}

/// Orbiting dot indicator
struct OrbitBusyIndicator: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let rotation = Angle.degrees(time.truncatingRemainder(dividingBy: 1.0) * 360)

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.25), lineWidth: 2)
                    .frame(width: 20, height: 20)

                Circle()
                    .fill(Color.primary.opacity(0.86))
                    .frame(width: 6, height: 6)
                    .offset(x: 10)
                    .rotationEffect(rotation)
            }
        }
    }
}

struct BusyIndicator: View {
    let style: BusyIndicatorStyle

    var body: some View {
        switch style {
        case .classic:
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle())
        case .modern:
            ModernBusyIndicator()
        case .pulse:
            PulseBusyIndicator()
        case .orbit:
            OrbitBusyIndicator()
        }
    }
}

/// A button wrapper that creates a new button with busy behavior.
/// Unlike a traditional ViewModifier, this CREATES the button rather than modifying an existing one.
/// This is necessary because SwiftUI doesn't allow intercepting/replacing a Button's action.
public struct BusyButtonWrapper<Label: View>: View {

    private let externalIsBusy: Binding<Bool>?
    let action: () async throws -> Void
    let role: ButtonRole?
    let options: BusyButtonOptions
    let label: () -> Label

    @State private var internalIsBusy = false

    public var body: some View {
        BusyButtonCore(
            isBusy: effectiveIsBusy,
            role: role,
            options: options,
            action: action,
            label: label
        )
    }

    private var effectiveIsBusy: Binding<Bool> {
        externalIsBusy ?? $internalIsBusy
    }

    public init(
        isBusy: Binding<Bool>,
        role: ButtonRole? = nil,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        onError: ((Error) -> Void)? = nil,
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.externalIsBusy = isBusy
        self.role = role
        self.options = BusyButtonOptions(
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            onError: onError
        )
        self.action = action
        self.label = label
    }

    public init(
        role: ButtonRole? = nil,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        onError: ((Error) -> Void)? = nil,
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.externalIsBusy = nil
        self.role = role
        self.options = BusyButtonOptions(
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            onError: onError
        )
        self.action = action
        self.label = label
    }

    public init(
        isBusy: Binding<Bool>,
        role: ButtonRole? = nil,
        options: BusyButtonOptions,
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.externalIsBusy = isBusy
        self.role = role
        self.options = options
        self.action = action
        self.label = label
    }

    public init(
        role: ButtonRole? = nil,
        options: BusyButtonOptions,
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.externalIsBusy = nil
        self.role = role
        self.options = options
        self.action = action
        self.label = label
    }
}

/// Helper to type-erase shapes
struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

public extension View {
    /// Creates a button from this view with busy behavior.
    ///
    /// IMPORTANT: This does NOT modify an existing Button. Instead, it:
    /// 1. Takes the current view as the button's label content
    /// 2. Creates a NEW Button with the provided action
    /// 3. Adds busy state management automatically
    ///
    /// Usage:
    /// ```swift
    /// Text("Download")  // <-- NOT a Button, just a Text view
    ///     .CC_busyButton(isBusy: $isBusy) { ... }  // <-- Creates the Button
    ///     .buttonStyle(.borderedProminent)  // <-- Styles the created Button
    /// ```
    ///
    /// Do NOT use on existing Buttons:
    /// ```swift
    /// Button("Download") { ... }  // ❌ Don't do this
    ///     .CC_busyButton(...)  // ❌ Would create a button inside a button!
    /// ```
    func CC_busyButton(
        isBusy: Binding<Bool>,
        role: ButtonRole? = nil,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        onError: ((Error) -> Void)? = nil,
        action: @escaping () async throws -> Void
    ) -> some View {
        BusyButtonWrapper(
            isBusy: isBusy,
            role: role,
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            onError: onError,
            action: action
        ) {
            self
        }
    }

    /// Creates a self-managed busy button from this view.
    func CC_busyButton(
        role: ButtonRole? = nil,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        onError: ((Error) -> Void)? = nil,
        action: @escaping () async throws -> Void
    ) -> some View {
        BusyButtonWrapper(
            role: role,
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            onError: onError,
            action: action
        ) {
            self
        }
    }

    /// Creates a button from this view with fully reusable busy button options.
    func CC_busyButton(
        isBusy: Binding<Bool>,
        role: ButtonRole? = nil,
        options: BusyButtonOptions,
        action: @escaping () async throws -> Void
    ) -> some View {
        BusyButtonWrapper(
            isBusy: isBusy,
            role: role,
            options: options,
            action: action
        ) {
            self
        }
    }

    /// Creates a self-managed busy button from this view with fully reusable options.
    func CC_busyButton(
        role: ButtonRole? = nil,
        options: BusyButtonOptions,
        action: @escaping () async throws -> Void
    ) -> some View {
        BusyButtonWrapper(
            role: role,
            options: options,
            action: action
        ) {
            self
        }
    }
}

/// A generic button that shows busy behavior and accepts any label content
public struct GenericBusyButton<Label: View>: View {

    public typealias ActionFunc = () async throws -> Void

    private let externalIsBusy: Binding<Bool>?
    let action: ActionFunc
    let role: ButtonRole?
    let options: BusyButtonOptions
    let label: () -> Label

    @State private var internalIsBusy = false

    public var body: some View {
        BusyButtonCore(
            isBusy: effectiveIsBusy,
            role: role,
            options: options,
            action: action,
            label: label
        )
    }

    private var effectiveIsBusy: Binding<Bool> {
        externalIsBusy ?? $internalIsBusy
    }

    public init(
        isBusy: Binding<Bool>,
        role: ButtonRole? = nil,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        onError: ((Error) -> Void)? = nil,
        action: @escaping ActionFunc,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.externalIsBusy = isBusy
        self.role = role
        self.options = BusyButtonOptions(
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            onError: onError
        )
        self.action = action
        self.label = label
    }

    public init(
        role: ButtonRole? = nil,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        onError: ((Error) -> Void)? = nil,
        action: @escaping ActionFunc,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.externalIsBusy = nil
        self.role = role
        self.options = BusyButtonOptions(
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            onError: onError
        )
        self.action = action
        self.label = label
    }

    public init(
        isBusy: Binding<Bool>,
        role: ButtonRole? = nil,
        options: BusyButtonOptions,
        action: @escaping ActionFunc,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.externalIsBusy = isBusy
        self.role = role
        self.options = options
        self.action = action
        self.label = label
    }

    public init(
        role: ButtonRole? = nil,
        options: BusyButtonOptions,
        action: @escaping ActionFunc,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.externalIsBusy = nil
        self.role = role
        self.options = options
        self.action = action
        self.label = label
    }
}

/// Convenience initializer for text-only buttons
public extension GenericBusyButton where Label == Text {
    init(
        _ title: String,
        isBusy: Binding<Bool>,
        role: ButtonRole? = nil,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        onError: ((Error) -> Void)? = nil,
        action: @escaping ActionFunc
    ) {
        self.init(
            isBusy: isBusy,
            role: role,
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            onError: onError,
            action: action
        ) {
            Text(title)
        }
    }

    init(
        _ title: String,
        role: ButtonRole? = nil,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        onError: ((Error) -> Void)? = nil,
        action: @escaping ActionFunc
    ) {
        self.init(
            role: role,
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            onError: onError,
            action: action
        ) {
            Text(title)
        }
    }

    init(
        _ title: String,
        isBusy: Binding<Bool>,
        role: ButtonRole? = nil,
        options: BusyButtonOptions,
        action: @escaping ActionFunc
    ) {
        self.init(isBusy: isBusy, role: role, options: options, action: action) {
            Text(title)
        }
    }

    init(
        _ title: String,
        role: ButtonRole? = nil,
        options: BusyButtonOptions,
        action: @escaping ActionFunc
    ) {
        self.init(role: role, options: options, action: action) {
            Text(title)
        }
    }
}

private struct BusyButtonCore<Label: View>: View {

    @Binding var isBusy: Bool
    let role: ButtonRole?
    let options: BusyButtonOptions
    let action: () async throws -> Void
    let label: () -> Label

    @State private var task: Task<Void, Never>?

    var body: some View {
        Button(role: role) {
            start()
        } label: {
            label()
                .opacity(isBusy ? 0 : 1)
                .accessibilityHidden(isBusy)
                .overlay {
                    if isBusy {
                        BusyIndicator(style: options.indicatorStyle)
                            .accessibilityLabel("Busy")
                    }
                }
                .accessibilityValue(isBusy ? Text("Busy") : Text(""))
        }
        .disabled(isBusy)
        .animation(options.animation, value: isBusy)
        .clipShape(options.shrinkToCircle && isBusy ? AnyShape(Circle()) : AnyShape(Rectangle()))
        .onDisappear {
            guard options.cancelTaskOnDisappear else { return }
            task?.cancel()
            task = nil
            if isBusy {
                withAnimation(options.animation) {
                    isBusy = false
                }
            }
        }
    }

    private func start() {
        guard !isBusy, task == nil else { return }
        withAnimation(options.animation) {
            isBusy = true
        }

        task = Task {
            do {
                try await action()
            } catch is CancellationError {
            } catch {
                await MainActor.run {
                    options.onError?(error)
                }
            }

            await MainActor.run {
                withAnimation(options.animation) {
                    isBusy = false
                }
                task = nil
            }
        }
    }
}

//MARK: - Preview
#if DEBUG
#Preview("Generic Busy Button Examples") {
    struct ShowcaseView: View {
        @State private var isBusyWrapper1 = false
        @State private var isBusyWrapper2 = false
        @State private var isBusyShrink1 = false
        @State private var isBusyShrink2 = false
        @State private var isBusyGeneric1 = false
        @State private var isBusyGeneric2 = false
        @State private var isBusyGeneric3 = false
        @State private var isBusyGeneric4 = false

        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    Text("Generic Busy Button Showcase")
                        .font(.largeTitle)
                        .padding(.bottom)

                    // BusyButtonWrapper approach with different indicators
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Different Indicator Styles")
                            .font(.headline)

                        HStack(spacing: 15) {
                            Label("Modern", systemImage: "arrow.down.circle.fill")
                                .CC_busyButton(isBusy: $isBusyWrapper1, indicatorStyle: .modern) {
                                    try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                                }
                                .buttonStyle(.borderedProminent)

                            Label("Pulse", systemImage: "heart.fill")
                                .CC_busyButton(isBusy: $isBusyWrapper2, indicatorStyle: .pulse) {
                                    try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                        }

                        Text("Modern animated indicators")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // With circle shrinking
                    VStack(alignment: .leading, spacing: 15) {
                        Text("With Circle Shrinking")
                            .font(.headline)

                        HStack(spacing: 20) {
                            Text("Process")
                                .CC_busyButton(isBusy: $isBusyShrink1, shrinkToCircle: true) {
                                    try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                                }
                                .buttonStyle(.borderedProminent)

                            Label("Upload", systemImage: "arrow.up.circle")
                                .CC_busyButton(isBusy: $isBusyShrink2, shrinkToCircle: true) {
                                    try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)
                        }

                        Text("Buttons shrink to circles when busy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Generic BusyButton with text
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Generic BusyButton - Text Only")
                            .font(.headline)

                        HStack(spacing: 15) {
                            GenericBusyButton("No Shrink", isBusy: $isBusyGeneric1) {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                            }
                            .buttonStyle(.bordered)

                            GenericBusyButton("With Shrink", isBusy: $isBusyGeneric2, shrinkToCircle: true) {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    // Generic BusyButton with icon
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Generic BusyButton - With Icon")
                            .font(.headline)

                        GenericBusyButton(isBusy: $isBusyGeneric3, shrinkToCircle: true, action: {
                            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                        }) {
                            Label("Upload Photo", systemImage: "photo.badge.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }

                    // Generic BusyButton with custom content
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Generic BusyButton - Custom Content")
                            .font(.headline)

                        GenericBusyButton(isBusy: $isBusyGeneric4, action: {
                            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 3)
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Configure")
                                        .font(.headline)
                                    Text("Settings & Options")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    // Complex example with various styles
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Various Button Styles")
                            .font(.headline)

                        VStack(spacing: 10) {
                            Text("Default Style")
                                .CC_busyButton(isBusy: .constant(false), shrinkToCircle: true) {
                                    try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                                }

                            Text("Bordered Style")
                                .CC_busyButton(isBusy: .constant(false), shrinkToCircle: true) {
                                    try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                                }
                                .buttonStyle(.bordered)

                            Text("Bordered Prominent")
                                .CC_busyButton(isBusy: .constant(false), shrinkToCircle: true) {
                                    try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                                }
                                .buttonStyle(.borderedProminent)

                            Text("Plain Style")
                                .CC_busyButton(isBusy: .constant(false)) {
                                    try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
            }
        }
    }

    return ShowcaseView()
}

// iOS 26+ Future Button Styles Preview
#if canImport(UIKit)  // Only available on iOS
@available(iOS 26.0, *)
#Preview("iOS 26 Glass Button Styles") {
    struct FutureBusyButtonShowcase: View {
        @State private var isBusyGlass1 = false
        @State private var isBusyGlass2 = false
        @State private var isBusyGlass3 = false
        @State private var isBusyGlass4 = false

        var body: some View {
            VStack(spacing: 30) {
                Text("iOS 26 Glass Button Styles")
                    .font(.largeTitle)
                    .padding(.bottom)

                Text("With Modern Indicators")
                    .font(.headline)

                VStack(spacing: 20) {
                    // Glass button with modern dots indicator
                    HStack {
                        Label("Download", systemImage: "arrow.down.circle")
                            .CC_busyButton(
                                isBusy: $isBusyGlass1,
                                shrinkToCircle: false,
                                indicatorStyle: .modern
                            ) {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                            }
                            // .buttonStyle(.glass)  // Future iOS 26 style
                            .buttonStyle(.borderedProminent)  // Placeholder for now
                            .tint(.blue)

                        Text("Modern dots")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Glass button with pulse indicator and shrink
                    HStack {
                        Label("Process", systemImage: "gearshape.fill")
                            .CC_busyButton(
                                isBusy: $isBusyGlass2,
                                shrinkToCircle: true,
                                indicatorStyle: .pulse
                            ) {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                            }
                            // .buttonStyle(.glass)  // Future iOS 26 style
                            .buttonStyle(.borderedProminent)  // Placeholder
                            .tint(.purple)

                        Text("Pulse + shrink")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Glass button with orbit indicator
                    HStack {
                        Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                            .CC_busyButton(
                                isBusy: $isBusyGlass3,
                                indicatorStyle: .orbit
                            ) {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                            }
                            // .buttonStyle(.glass)  // Future iOS 26 style
                            .buttonStyle(.borderedProminent)  // Placeholder
                            .tint(.green)

                        Text("Orbit animation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Classic indicator for comparison
                    HStack {
                        Label("Upload", systemImage: "icloud.and.arrow.up")
                            .CC_busyButton(
                                isBusy: $isBusyGlass4,
                                indicatorStyle: .classic
                            ) {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                            }
                            // .buttonStyle(.glass)  // Future iOS 26 style
                            .buttonStyle(.borderedProminent)  // Placeholder
                            .tint(.orange)

                        Text("Classic spinner")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                Text("Indicator Style Comparison")
                    .font(.headline)

                HStack(spacing: 30) {
                    VStack {
                        ModernBusyIndicator()
                        Text("Modern")
                            .font(.caption)
                    }

                    VStack {
                        PulseBusyIndicator()
                        Text("Pulse")
                            .font(.caption)
                    }

                    VStack {
                        OrbitBusyIndicator()
                        Text("Orbit")
                            .font(.caption)
                    }

                    VStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Classic")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                Text("Note: Using .borderedProminent as placeholder for future .glass style")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    return FutureBusyButtonShowcase()
}
#endif  // canImport(UIKit)

#endif  // DEBUG
