//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// Blinks the content with configurable style and behavior.
public struct Blink: ViewModifier {

    /// The blink style.
    public enum Style {
        /// Instant on/off transition
        case hard
        /// Smooth fade transition
        case soft
    }

    private let style: Style
    private let duration: TimeInterval
    private let repeatCount: Int
    private let isEnabled: Bool

    @State private var isVisible = true
    @State private var remainingRepeats = 0
    @State private var task: Task<Void, Never>?

    public init(
        style: Style = .hard,
        duration: TimeInterval = 1.0,
        repeatCount: Int = Int.max,
        isEnabled: Bool = true
    ) {
        self.style = style
        self.duration = duration
        self.repeatCount = repeatCount
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(style == .soft ? .easeInOut(duration: duration / 2) : nil, value: isVisible)
            .onAppear {
                startBlinking()
            }
            .onDisappear {
                stopBlinking()
            }
            .onChange(of: isEnabled) { newValue in
                if newValue {
                    startBlinking()
                } else {
                    stopBlinking()
                    isVisible = true
                }
            }
            .onChange(of: duration) { _ in
                if isEnabled {
                    startBlinking()
                }
            }
            .onChange(of: repeatCount) { _ in
                if isEnabled {
                    startBlinking()
                }
            }
    }

    private func startBlinking() {
        guard isEnabled else {
            isVisible = true
            return
        }

        stopBlinking()
        remainingRepeats = repeatCount
        isVisible = true

        task = Task { @MainActor in
            while remainingRepeats > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(duration / 2))
                guard !Task.isCancelled else { break }

                isVisible.toggle()

                if !isVisible {
                    remainingRepeats -= 1
                }
            }

            if !Task.isCancelled {
                isVisible = true
            }
        }
    }

    private func stopBlinking() {
        task?.cancel()
        task = nil
    }
}

extension View {
    /// Makes the content blink with the specified configuration.
    /// - Parameters:
    ///   - style: The blink animation style (.hard for instant, .soft for smooth fade)
    ///   - duration: The duration of one complete blink cycle (on + off)
    ///   - repeatCount: Number of blink cycles. Use `Int.max` for infinite blinking
    ///   - isEnabled: Controls whether blinking is active
    /// - Returns: A view that blinks according to the specified parameters
    public func CC_blinking(
        style: Blink.Style = .hard,
        duration: TimeInterval = 1.0,
        repeatCount: Int = Int.max,
        isEnabled: Bool = true
    ) -> some View {
        modifier(Blink(
            style: style,
            duration: duration,
            repeatCount: repeatCount,
            isEnabled: isEnabled
        ))
    }
}

#if DEBUG
#Preview("Blink - Comprehensive") {
    struct BlinkShowcase: View {
        @State private var globalBlinkingEnabled = true
        @State private var customRepeatCount = 5
        @State private var selectedDuration = 1.0
        @State private var showLimitedBlink = false
        @State private var showCustomBlink = false
        @State private var isRecording = false
        @State private var achievementUnlocked = false
        @State private var refreshKey = UUID()

        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Blink Modifier Showcase")
                            .font(.largeTitle)
                            .bold()
                        Text("Modern SwiftUI Blinking Effects")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom)

                    // Master Control
                    GroupBox {
                        Toggle("Enable All Blinking Effects", isOn: $globalBlinkingEnabled)
                            .tint(.blue)
                    }
                    .groupBoxStyle(.automatic)

                    // Style Comparison
                    GroupBox("Animation Styles") {
                        HStack(spacing: 40) {
                            VStack(spacing: 12) {
                                Text("Soft Fade")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 100, height: 60)
                                    .overlay {
                                        Text("Smooth")
                                            .foregroundStyle(.white)
                                            .fontWeight(.medium)
                                    }
                                    .CC_blinking(
                                        style: .soft,
                                        duration: 1.2,
                                        isEnabled: globalBlinkingEnabled
                                    )
                            }

                            VStack(spacing: 12) {
                                Text("Hard Switch")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 100, height: 60)
                                    .overlay {
                                        Text("Instant")
                                            .foregroundStyle(.white)
                                            .fontWeight(.medium)
                                    }
                                    .CC_blinking(
                                        style: .hard,
                                        duration: 1.2,
                                        isEnabled: globalBlinkingEnabled
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }

                    // Duration Control
                    GroupBox("Duration Control") {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Speed:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(selectedDuration, specifier: "%.1f")s")
                                    .monospacedDigit()
                                    .foregroundStyle(.blue)
                            }

                            Slider(value: $selectedDuration, in: 0.2...3.0, step: 0.1)
                                .tint(.blue)

                            // Single demo element that responds to duration changes
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.indigo.gradient)
                                .frame(height: 60)
                                .overlay {
                                    Text("Duration: \(selectedDuration, specifier: "%.1f")s")
                                        .foregroundStyle(.white)
                                        .fontWeight(.medium)
                                }
                                .CC_blinking(
                                    style: .soft,
                                    duration: selectedDuration,
                                    isEnabled: globalBlinkingEnabled
                                )
                                .id("\(selectedDuration)-\(globalBlinkingEnabled)")

                            HStack(spacing: 16) {
                                Text("Presets:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach([0.3, 0.7, 1.0, 1.5, 2.5], id: \.self) { duration in
                                    Button {
                                        selectedDuration = duration
                                    } label: {
                                        Text("\(duration, specifier: "%.1f")")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(duration == selectedDuration ? Color.accentColor : Color.gray.opacity(0.3))
                                            )
                                            .foregroundStyle(duration == selectedDuration ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    // Repeat Count Examples
                    GroupBox("Repeat Control") {
                        VStack(spacing: 20) {
                            // Limited repeats with button trigger
                            HStack {
                                Label("3 Blinks", systemImage: "repeat.circle")
                                    .frame(width: 120, alignment: .leading)

                                Button {
                                    showLimitedBlink = false
                                    Task {
                                        try? await Task.sleep(for: .milliseconds(100))
                                        showLimitedBlink = true
                                        Task {
                                            try? await Task.sleep(for: .seconds(2))
                                            showLimitedBlink = false
                                        }
                                    }
                                } label: {
                                    Text("Tap to Start")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(Color.orange.gradient)
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(showLimitedBlink)

                                if showLimitedBlink {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 20, height: 20)
                                        .CC_blinking(
                                            style: .soft,
                                            duration: 0.5,
                                            repeatCount: 3,
                                            isEnabled: true
                                        )
                                        .id(UUID())
                                }
                            }

                            // Custom repeat count
                            VStack(spacing: 12) {
                                HStack {
                                    Label("\(customRepeatCount) Blinks", systemImage: "slider.horizontal.3")
                                    Spacer()
                                    Stepper("", value: $customRepeatCount, in: 1...20)
                                        .labelsHidden()
                                }

                                HStack {
                                    Button {
                                        showCustomBlink = false
                                        Task {
                                            try? await Task.sleep(for: .milliseconds(100))
                                            showCustomBlink = true
                                            let waitTime = Double(customRepeatCount) * 0.6 + 0.5
                                            Task {
                                                try? await Task.sleep(for: .seconds(waitTime))
                                                showCustomBlink = false
                                            }
                                        }
                                    } label: {
                                        Text("Start Custom")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color.purple.gradient)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(showCustomBlink)

                                    if showCustomBlink {
                                        Circle()
                                            .fill(Color.purple)
                                            .frame(width: 20, height: 20)
                                            .CC_blinking(
                                                style: .soft,
                                                duration: 0.6,
                                                repeatCount: customRepeatCount,
                                                isEnabled: true
                                            )
                                            .id(UUID())
                                    }
                                }
                            }

                            // Infinite blinking
                            HStack {
                                Label("Infinite", systemImage: "infinity")
                                    .frame(width: 120, alignment: .leading)

                                Capsule()
                                    .fill(Color.cyan.gradient)
                                    .frame(height: 32)
                                    .overlay {
                                        Text("Always Blinking")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                            .fontWeight(.medium)
                                    }
                                    .CC_blinking(
                                        style: .soft,
                                        duration: 1.0,
                                        repeatCount: Int.max,
                                        isEnabled: globalBlinkingEnabled
                                    )
                            }
                        }
                    }

                    // Practical Use Cases
                    GroupBox("Real-World Examples") {
                        VStack(spacing: 16) {
                            // Alert/Warning
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                    .symbolRenderingMode(.multicolor)
                                    .CC_blinking(
                                        style: .hard,
                                        duration: 0.8,
                                        isEnabled: globalBlinkingEnabled
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("System Warning")
                                        .fontWeight(.semibold)
                                    Text("Low disk space available")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            // Recording indicator
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                    .CC_blinking(
                                        style: .soft,
                                        duration: 1.0,
                                        isEnabled: isRecording
                                    )

                                Text(isRecording ? "Recording…" : "Stopped")
                                    .font(.callout)

                                Spacer()

                                Button(isRecording ? "Stop" : "Record") {
                                    isRecording.toggle()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding()
                            .background(isRecording ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            // Achievement notification
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Achievement System")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Button("Unlock") {
                                        achievementUnlocked = true
                                        Task {
                                            try? await Task.sleep(for: .seconds(3))
                                            achievementUnlocked = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(achievementUnlocked)
                                }

                                if achievementUnlocked {
                                    HStack(spacing: 16) {
                                        Image(systemName: "trophy.fill")
                                            .font(.largeTitle)
                                            .foregroundStyle(.yellow)
                                            .symbolRenderingMode(.multicolor)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Achievement Unlocked!")
                                                .fontWeight(.bold)
                                            Text("Master of Blinking")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.yellow.opacity(0.15))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(Color.yellow, lineWidth: 2)
                                            )
                                    )
                                    .CC_blinking(
                                        style: .soft,
                                        duration: 0.8,
                                        repeatCount: 5,
                                        isEnabled: true
                                    )
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                    .id(UUID())
                                }
                            }
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: achievementUnlocked)

                            // Processing state
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Processing data…")
                                    .font(.callout)
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .CC_blinking(
                                style: .soft,
                                duration: 1.5,
                                isEnabled: globalBlinkingEnabled
                            )
                        }
                    }

                    // Interactive Demo
                    GroupBox("Interactive Playground") {
                        VStack(spacing: 16) {
                            Text("Different blink patterns")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(0..<9) { index in
                                    let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal, .indigo, .mint]
                                    let durations: [Double] = [0.3, 0.5, 0.7, 0.9, 1.1, 1.3, 1.5, 1.7, 2.0]

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(colors[index].gradient)
                                        .frame(height: 60)
                                        .overlay {
                                            VStack(spacing: 4) {
                                                Text("\(durations[index], specifier: "%.1f")s")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                Text(index % 2 == 0 ? "Soft" : "Hard")
                                                    .font(.caption2)
                                            }
                                            .foregroundStyle(.white)
                                        }
                                        .CC_blinking(
                                            style: index % 2 == 0 ? .soft : .hard,
                                            duration: durations[index],
                                            isEnabled: globalBlinkingEnabled
                                        )
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            #if os(iOS)
            .background(Color(uiColor: .systemGroupedBackground))
            #else
            .background(Color(nsColor: .controlBackgroundColor))
            #endif
        }
    }

    return BlinkShowcase()
}
#endif