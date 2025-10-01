//
//  Cornucopia – (C) Dr. Lauer Information Technology
//

import SwiftUI

/// A generalized synchronized blending container that cycles through up to four
/// heterogenous child views, optionally synchronizing with a global blending group.
///
/// - Synchronization: If an environment `CC_blendingSyncGroup` is present, the
///   container aligns its fade-out/in phases and index changes to the group's timeline.
///   Otherwise, it falls back to an internal timer-based cycle.
/// - Layout behavior: By default (`dynamicLayout: true`), the container uses each
///   child view's natural size so dimensions may change while blending.
///   If `dynamicLayout: false`, the container measures all provided child views and
///   reserves a fixed maximum width and height to avoid visual jumps while blending.
public struct SynchronizedBlendingContainer: View {
    private let duration: TimeInterval
    private let dynamicLayout: Bool
    private let builders: [() -> AnyView]

    @Environment(\.CC_blendingSyncGroup) private var syncGroup
    @State private var internalDuration: TimeInterval

    // MARK: - Concrete initializers (2...4 views)

    public init<V1: View, V2: View>(
        duration: TimeInterval = 2.0,
        dynamicLayout: Bool = true,
        @ViewBuilder _ view1: @escaping () -> V1,
        @ViewBuilder _ view2: @escaping () -> V2
    ) {
        self.duration = duration
        self.dynamicLayout = dynamicLayout
        self.builders = [
            { AnyView(view1()) },
            { AnyView(view2()) },
        ]
        self._internalDuration = State(initialValue: duration)
    }

    public init<V1: View, V2: View, V3: View>(
        duration: TimeInterval = 2.0,
        dynamicLayout: Bool = true,
        @ViewBuilder _ view1: @escaping () -> V1,
        @ViewBuilder _ view2: @escaping () -> V2,
        @ViewBuilder _ view3: @escaping () -> V3
    ) {
        self.duration = duration
        self.dynamicLayout = dynamicLayout
        self.builders = [
            { AnyView(view1()) },
            { AnyView(view2()) },
            { AnyView(view3()) },
        ]
        self._internalDuration = State(initialValue: duration)
    }

    public init<V1: View, V2: View, V3: View, V4: View>(
        duration: TimeInterval = 2.0,
        dynamicLayout: Bool = true,
        @ViewBuilder _ view1: @escaping () -> V1,
        @ViewBuilder _ view2: @escaping () -> V2,
        @ViewBuilder _ view3: @escaping () -> V3,
        @ViewBuilder _ view4: @escaping () -> V4
    ) {
        self.duration = duration
        self.dynamicLayout = dynamicLayout
        self.builders = [
            { AnyView(view1()) },
            { AnyView(view2()) },
            { AnyView(view3()) },
            { AnyView(view4()) },
        ]
        self._internalDuration = State(initialValue: duration)
    }

    public var body: some View {
        Group {
            if let group = syncGroup {
                SyncedContainer(
                    builders: builders,
                    group: group,
                    dynamicLayout: dynamicLayout
                )
            } else {
                NonSyncedContainer(
                    builders: builders,
                    duration: internalDuration,
                    dynamicLayout: dynamicLayout
                )
            }
        }
        .onChange(of: duration) { newDuration in
            internalDuration = newDuration
        }
    }
}

// MARK: - Shared helpers

private func mod(_ a: Int, _ n: Int) -> Int { ((a % n) + n) % n }

// MARK: - Synced variant

private struct SyncedContainer: View {
    let builders: [() -> AnyView]
    @ObservedObject var group: BlendingSyncGroup
    let dynamicLayout: Bool

    @State private var localCurrentIndex: Int = 0
    @State private var lastCycle: Int = -1

    // No explicit measurement needed when using fixed-size strategy

    var body: some View {
        let count = builders.count
        let currentIndex = safeIndex(localCurrentIndex, count: count)
        let current = builders.isEmpty ? AnyView(EmptyView()) : builders[currentIndex]()

        content(current: current, count: count)
            .opacity(group.phase == .visible ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5), value: group.phase)
            .onAppear {
                guard count > 1 else { return }
                group.subscribe()
                localCurrentIndex = safeIndex(group.cycle, count: count)
                lastCycle = group.cycle
            }
            .onDisappear { group.unsubscribe() }
            .onChange(of: group.cycle) { newCycle in
                guard count > 1, newCycle != lastCycle else { return }
                let delta = newCycle - lastCycle
                lastCycle = newCycle
                localCurrentIndex = safeIndex(localCurrentIndex + delta, count: count)
            }
            .onChange(of: builders.count) { newCount in
                // Re-align if the number of builders changes (defensive)
                localCurrentIndex = safeIndex(group.cycle, count: newCount)
                lastCycle = group.cycle
            }
    }

    @ViewBuilder
    private func content(current: AnyView, count: Int) -> some View {
        if dynamicLayout {
            current
        } else {
            ZStack {
                // Build all candidates invisibly so ZStack adopts their max size
                ForEach(0..<count, id: \.self) { idx in
                    builders[idx]()
                        .opacity(0)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
                current
            }
            .allowsHitTesting(true) // keep interactions on current content
        }
    }

    private func safeIndex(_ value: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return mod(value, count)
    }
}

// MARK: - Non-synced variant

private struct NonSyncedContainer: View {
    let builders: [() -> AnyView]
    let duration: TimeInterval
    let dynamicLayout: Bool

    @State private var currentIndex: Int = 0
    @State private var opacity: Double = 1.0
    @State private var timer: Timer?

    // No explicit measurement needed when using fixed-size strategy

    var body: some View {
        let count = builders.count
        let current = builders.isEmpty ? AnyView(EmptyView()) : builders[safeIndex(currentIndex, count: count)]()

        content(current: current, count: count)
            .opacity(opacity)
            .onAppear {
                guard count > 1 else { return }
                start()
            }
            .onDisappear { stop() }
            .onChange(of: builders.count) { newCount in
                stop()
                currentIndex = 0
                opacity = 1.0
                if newCount > 1 { start() }
            }
            .onChange(of: duration) { _ in
                guard count > 1 else { return }
                stop()
                start()
            }
    }

    @ViewBuilder
    private func content(current: AnyView, count: Int) -> some View {
        if dynamicLayout {
            current
        } else {
            ZStack {
                ForEach(0..<count, id: \.self) { idx in
                    builders[idx]()
                        .opacity(0)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
                current
            }
            .allowsHitTesting(true)
        }
    }

    private func start() {
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) { opacity = 0.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentIndex = (currentIndex + 1) % max(1, builders.count)
                withAnimation(.easeInOut(duration: 0.5)) { opacity = 1.0 }
            }
        }
    }

    private func stop() {
        timer?.invalidate(); timer = nil
    }

    private func safeIndex(_ value: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return mod(value, count)
    }
}

// MARK: - Previews

#if DEBUG
// 1) Typography and color variance (side-by-side dynamic vs fixed)
#Preview("Container – Typography & Colors") {
    struct Demo: View {
        @State private var dynamicLayout: Bool = true
        @State private var duration: Double = 1.2
        var body: some View {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Toggle("Dynamic Layout", isOn: $dynamicLayout)
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Duration:")
                            Spacer()
                            Text("\(max(0.1, duration), specifier: "%.1f")s")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        
                        Slider(value: $duration, in: 0...10, step: 0.1)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)
                .shadow(radius: 2)
                .padding(.bottom, 24)
                
                SynchronizedBlendingContainer(duration: max(0.1, duration), dynamicLayout: dynamicLayout,
                                               { Text("Short").font(.title).foregroundStyle(.red) },
                                               { Text("A very very long title").font(.title).foregroundStyle(.blue) },
                                               { Text("Title").font(.largeTitle).foregroundStyle(.green) })
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(dynamicLayout ? Color.red.opacity(0.6) : Color.green.opacity(0.6), lineWidth: 1)
                    )
                    .padding()
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
    }
    return Demo()
}

// 2) Height variance with mixed styles
#Preview("Container – Height Variance") {
    struct Demo: View {
        @State private var dynamicLayout: Bool = true
        @State private var duration: Double = 1.5
        var body: some View {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Toggle("Dynamic Layout", isOn: $dynamicLayout)
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Duration:")
                            Spacer()
                            Text("\(max(0.1, duration), specifier: "%.1f")s")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        
                        Slider(value: $duration, in: 0...10, step: 0.1)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)
                .shadow(radius: 2)
                .padding(.bottom, 24)
                
                SynchronizedBlendingContainer(duration: max(0.1, duration), dynamicLayout: dynamicLayout,
                                               { Text("One line").font(.headline) },
                                               { Text("Two\nLines").font(.headline).multilineTextAlignment(.center) },
                                               { VStack(spacing: 4) {
                                                    Text("Stacked").font(.headline)
                                                    Text("Content").font(.caption)
                                                } })
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(dynamicLayout ? Color.red.opacity(0.6) : Color.green.opacity(0.6), lineWidth: 1)
                    )
                    .padding()
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
    }
    return Demo()
}

// 3) Mixed content views (icon + text + shapes)
#Preview("Container – Mixed Content") {
    struct Demo: View {
        @State private var dynamicLayout: Bool = true
        @State private var duration: Double = 1.0
        var body: some View {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Toggle("Dynamic Layout", isOn: $dynamicLayout)
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Duration:")
                            Spacer()
                            Text("\(max(0.1, duration), specifier: "%.1f")s")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        
                        Slider(value: $duration, in: 0...10, step: 0.1)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)
                .shadow(radius: 2)
                .padding(.bottom, 24)
                
                VStack(spacing: 12) {
                    Text("Demonstrates heterogeneous views")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SynchronizedBlendingContainer(duration: max(0.1, duration), dynamicLayout: dynamicLayout,
                                                   { Label("Sync", systemImage: "clock").labelStyle(.titleAndIcon) },
                                                   { HStack(spacing: 6) { Image(systemName: "bolt.fill").foregroundStyle(.yellow); Text("Power").bold() } },
                                                   { RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.2)).frame(width: 140, height: 36) })
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(dynamicLayout ? Color.red.opacity(0.6) : Color.green.opacity(0.6), lineWidth: 1)
                        )
                        .padding()
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    return Demo()
}

// 4) Synchronized comparison across multiple containers
#Preview("Container – Synchronized Group Demo") {
    struct Demo: View {
        @State private var dynamicLayout: Bool = true
        @State private var duration: Double = 1.2
        var body: some View {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Toggle("Dynamic Layout", isOn: $dynamicLayout)
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Duration:")
                            Spacer()
                            Text("\(max(0.1, duration), specifier: "%.1f")s")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        
                        Slider(value: $duration, in: 0...10, step: 0.1)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)
                .shadow(radius: 2)
                .padding(.bottom, 24)
                
                VStack(spacing: 12) {
                    Text("Two containers share the same sync group")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    VStack(spacing: 16) {
                        SynchronizedBlendingContainer(duration: max(0.1, duration), dynamicLayout: dynamicLayout,
                                                       { Text("Go").font(.largeTitle).foregroundStyle(.red) },
                                                       { Text("Proceed").font(.title3).foregroundStyle(.orange) },
                                                       { Text("Continue").font(.title).foregroundStyle(.green) })
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(dynamicLayout ? Color.red.opacity(0.6) : Color.green.opacity(0.6), lineWidth: 1)
                            )
                        SynchronizedBlendingContainer(duration: max(0.1, duration), dynamicLayout: dynamicLayout,
                                                       { Image(systemName: "heart.fill").font(.largeTitle).foregroundStyle(.pink) },
                                                       { Text("♥︎").font(.system(size: 18)) },
                                                       { Text("HEART").font(.headline) })
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(dynamicLayout ? Color.red.opacity(0.6) : Color.green.opacity(0.6), lineWidth: 1)
                            )
                    }
                    .CC_blendingSyncGroup("demo-sync", duration: max(0.1, duration))
                    .onChange(of: duration) { newDuration in
                        BlendingSyncManager.shared.updateGroupDuration(id: "demo-sync", duration: max(0.1, newDuration))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    return Demo()
}

// 5) MarqueeScrollView integration with static layout
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview("Container – MarqueeScrollView Integration") {
    struct Demo: View {
        @State private var duration: Double = 2.0
        var body: some View {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    HStack {
                        Text("Duration:")
                        Spacer()
                        Text("\(max(0.1, duration), specifier: "%.1f")s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)

                    Slider(value: $duration, in: 0...10, step: 0.1)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)
                .shadow(radius: 2)
                .padding(.bottom, 24)

                Text("Static layout with Label and MarqueeScrollView")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SynchronizedBlendingContainer(duration: max(0.1, duration), dynamicLayout: false,
                                               { Label("Settings", systemImage: "gear") },
                                               { MarqueeScrollView(startDelay: 0) {
                                                   Label("Very Long Configuration and Advanced Settings Options", systemImage: "slider.horizontal.3")
                                               } })
                    .frame(width: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.purple.opacity(0.6), lineWidth: 1)
                    )
                    .padding()
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(12)

                Spacer()
            }
            .padding()
        }
    }
    return Demo()
}
#endif

