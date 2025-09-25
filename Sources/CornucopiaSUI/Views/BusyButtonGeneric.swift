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

/// Modern animated dots indicator
struct ModernBusyIndicator: View {
    @State private var animationPhase = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.primary.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationPhase == Double(index) ? 1.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            animationPhase = 2.0
        }
    }
}

/// Pulsing circle indicator
struct PulseBusyIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .stroke(Color.primary.opacity(0.6), lineWidth: 2)
            .frame(width: 20, height: 20)
            .scaleEffect(isPulsing ? 1.2 : 0.8)
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

/// Orbiting dot indicator
struct OrbitBusyIndicator: View {
    @State private var rotation = 0.0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 20, height: 20)

            Circle()
                .fill(Color.primary.opacity(0.8))
                .frame(width: 6, height: 6)
                .offset(x: 10)
                .rotationEffect(.degrees(rotation))
                .animation(
                    .linear(duration: 1.0)
                    .repeatForever(autoreverses: false),
                    value: rotation
                )
        }
        .onAppear {
            rotation = 360
        }
    }
}

/// A button wrapper that creates a new button with busy behavior.
/// Unlike a traditional ViewModifier, this CREATES the button rather than modifying an existing one.
/// This is necessary because SwiftUI doesn't allow intercepting/replacing a Button's action.
public struct BusyButtonWrapper<Label: View>: View {

    @Binding var isBusy: Bool
    let action: () async throws -> Void
    let shrinkToCircle: Bool
    let indicatorStyle: BusyIndicatorStyle
    let label: () -> Label

    public var body: some View {
        Button(action: {
            withAnimation {
                isBusy = true
            }
            Task {
                defer {
                    DispatchQueue.main.async {
                        withAnimation {
                            isBusy = false
                        }
                    }
                }
                try await action()
            }
        }) {
            ZStack {
                if shrinkToCircle && isBusy {
                    label()
                        .opacity(0)
                        .clipShape(Circle())
                } else {
                    label()
                        .opacity(isBusy ? 0 : 1)
                }

                if isBusy {
                    switch indicatorStyle {
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
        }
        .disabled(isBusy)
        .animation(.easeInOut(duration: 0.3), value: isBusy)
        .clipShape(shrinkToCircle && isBusy ? AnyShape(Circle()) : AnyShape(Rectangle()))
    }

    public init(
        isBusy: Binding<Bool>,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self._isBusy = isBusy
        self.shrinkToCircle = shrinkToCircle
        self.indicatorStyle = indicatorStyle
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
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        action: @escaping () async throws -> Void
    ) -> some View {
        BusyButtonWrapper(
            isBusy: isBusy,
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            action: action
        ) {
            self
        }
    }
}

/// A generic button that shows busy behavior and accepts any label content
public struct GenericBusyButton<Label: View>: View {

    public typealias ActionFunc = () async throws -> Void

    @Binding var isBusy: Bool
    let action: ActionFunc
    let shrinkToCircle: Bool
    let indicatorStyle: BusyIndicatorStyle
    let label: () -> Label

    public var body: some View {
        Button(action: {
            withAnimation {
                self.isBusy = true
            }
            Task {
                defer {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.isBusy = false
                        }
                    }
                }
                try await self.action()
            }
        }) {
            ZStack {
                if shrinkToCircle && isBusy {
                    label()
                        .opacity(0)
                        .clipShape(Circle())
                } else {
                    label()
                        .opacity(isBusy ? 0 : 1)
                }

                if isBusy {
                    switch indicatorStyle {
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
        }
        .disabled(isBusy)
        .animation(.easeInOut(duration: 0.3), value: isBusy)
        .clipShape(shrinkToCircle && isBusy ? AnyShape(Circle()) : AnyShape(Rectangle()))
    }

    public init(
        isBusy: Binding<Bool>,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        action: @escaping ActionFunc,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self._isBusy = isBusy
        self.shrinkToCircle = shrinkToCircle
        self.indicatorStyle = indicatorStyle
        self.action = action
        self.label = label
    }
}

/// Convenience initializer for text-only buttons
public extension GenericBusyButton where Label == Text {
    init(
        _ title: String,
        isBusy: Binding<Bool>,
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        action: @escaping ActionFunc
    ) {
        self.init(isBusy: isBusy, shrinkToCircle: shrinkToCircle, indicatorStyle: indicatorStyle, action: action) {
            Text(title)
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