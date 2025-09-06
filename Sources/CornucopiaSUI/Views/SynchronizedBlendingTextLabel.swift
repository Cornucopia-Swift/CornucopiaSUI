//
//  Cornucopia – (C) Dr. Lauer Information Technology
//

import SwiftUI

// MARK: - Synchronization Group Coordinator

@MainActor
public class BlendingSyncGroup: ObservableObject {
    public let id: String
    public let duration: TimeInterval
    private let fadeDuration: TimeInterval
    
    @Published private var currentPhase: BlendingPhase = .visible
    @Published private var cycleCount: Int = 0
    
    private var boundaryTimer: Timer?
    private var fadeEndTimer: Timer?
    private var subscriberCount = 0
    
    public init(id: String, duration: TimeInterval = 2.0) {
        self.id = id
        self.duration = duration
        // Ensure fade doesn't exceed half of the cycle
        self.fadeDuration = min(0.5, max(0.0, duration / 2))
        // Align initial state to wall-clock based cycle
        let now = Date.timeIntervalSinceReferenceDate
        self.cycleCount = Self.completedCycles(now: now, duration: duration, fade: fadeDuration)
        let intoCycle = now - (floor(now / duration) * duration)
        self.currentPhase = intoCycle < fadeDuration ? .fading : .visible
    }
    
    deinit { }
    
    func subscribe() {
        subscriberCount += 1
        if subscriberCount == 1 {
            startSyncTimerAligned()
        }
    }
    
    func unsubscribe() {
        subscriberCount = max(0, subscriberCount - 1)
        if subscriberCount == 0 { stopSyncTimer() }
    }
    
    var phase: BlendingPhase { currentPhase }
    var cycle: Int { cycleCount }
    
    private func startSyncTimerAligned() {
        let now = Date.timeIntervalSinceReferenceDate
        let intoCycle = now - (floor(now / duration) * duration)
        // If we start during the fade, schedule the imminent fade end
        if intoCycle < fadeDuration {
            let remainingFade = fadeDuration - intoCycle
            fadeEndTimer?.invalidate()
            fadeEndTimer = Timer.scheduledTimer(withTimeInterval: remainingFade, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    let now = Date.timeIntervalSinceReferenceDate
                    self.cycleCount = Self.completedCycles(now: now, duration: self.duration, fade: self.fadeDuration)
                    withAnimation(.easeInOut(duration: self.fadeDuration)) {
                        self.currentPhase = .visible
                    }
                }
            }
        }
        scheduleNextBoundary(from: now)
    }
    
    private func scheduleNextBoundary(from now: TimeInterval) {
        // Compute next boundary aligned to wall-clock multiples of duration
        let nextBoundary = ceil(now / duration) * duration
        let delay = max(0.0, nextBoundary - now)
        boundaryTimer?.invalidate()
        boundaryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // Enter fade phase
                withAnimation(.easeInOut(duration: self.fadeDuration)) {
                    self.currentPhase = .fading
                }
                // Schedule end of fade and cycle increment
                self.fadeEndTimer?.invalidate()
                self.fadeEndTimer = Timer.scheduledTimer(withTimeInterval: self.fadeDuration, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    Task { @MainActor in
                        // Align cycle count to number of completed fades
                        let now = Date.timeIntervalSinceReferenceDate
                        self.cycleCount = Self.completedCycles(now: now, duration: self.duration, fade: self.fadeDuration)
                        withAnimation(.easeInOut(duration: self.fadeDuration)) {
                            self.currentPhase = .visible
                        }
                        // Schedule the next boundary
                        self.scheduleNextBoundary(from: now)
                    }
                }
            }
        }
    }
    
    private func stopSyncTimer() {
        boundaryTimer?.invalidate(); boundaryTimer = nil
        fadeEndTimer?.invalidate(); fadeEndTimer = nil
    }
}

extension BlendingSyncGroup {
    fileprivate static func completedCycles(now: TimeInterval, duration: TimeInterval, fade: TimeInterval) -> Int {
        // Number of cycles whose fade has completed at time 'now'
        let value = floor((now - fade) / duration) + 1
        return max(0, Int(value))
    }
}

public enum BlendingPhase {
    case visible
    case fading
}

// MARK: - Global Sync Group Manager

@MainActor
public class BlendingSyncManager: ObservableObject {
    public static let shared = BlendingSyncManager()
    
    private var groups: [String: BlendingSyncGroup] = [:]
    
    private init() {}
    
    public func group(id: String, duration: TimeInterval = 2.0) -> BlendingSyncGroup {
        if let existing = groups[id] {
            return existing
        }
        
        let newGroup = BlendingSyncGroup(id: id, duration: duration)
        groups[id] = newGroup
        return newGroup
    }
    
    public func removeGroup(id: String) {
        groups.removeValue(forKey: id)
    }
}

// MARK: - Environment Key

private struct BlendingSyncGroupKey: EnvironmentKey {
    static let defaultValue: BlendingSyncGroup? = nil
}

extension EnvironmentValues {
    public var CC_blendingSyncGroup: BlendingSyncGroup? {
        get { self[BlendingSyncGroupKey.self] }
        set { self[BlendingSyncGroupKey.self] = newValue }
    }
}

// MARK: - Synchronized Blending Text Label

public struct SynchronizedBlendingTextLabel: View {
    private let texts: [String]
    private let duration: TimeInterval
    
    @Environment(\.CC_blendingSyncGroup) private var syncGroup
    @State private var localCurrentIndex: Int = 0
    @State private var lastCycle: Int = -1
    
    public init(_ texts: [String], duration: TimeInterval = 2.0) {
        self.texts = texts
        self.duration = duration
    }
    
    public var body: some View {
        Group {
            if let group = syncGroup {
                SyncedContent(
                    texts: texts,
                    group: group,
                    localCurrentIndex: $localCurrentIndex,
                    lastCycle: $lastCycle
                )
            } else {
                // Fallback to regular BlendingTextLabel behavior
                BlendingTextLabel(texts, duration: duration)
            }
        }
    }
}

private struct SyncedContent: View {
    let texts: [String]
    @ObservedObject var group: BlendingSyncGroup
    @Binding var localCurrentIndex: Int
    @Binding var lastCycle: Int
    
    var body: some View {
        Text(currentText)
            .opacity(group.phase == .visible ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5), value: group.phase)
            .onAppear {
                guard texts.count > 1 else { return }
                group.subscribe()
                // Align immediately to current cycle so appearance time doesn't matter
                let cycle = group.cycle
                if texts.count > 0 {
                    localCurrentIndex = safeIndex(for: cycle)
                }
                lastCycle = cycle
            }
            .onDisappear {
                group.unsubscribe()
            }
            .onChange(of: group.cycle) { newCycle in
                guard texts.count > 1, newCycle != lastCycle else { return }
                let delta = newCycle - lastCycle
                lastCycle = newCycle
                localCurrentIndex = mod(localCurrentIndex + delta, texts.count)
            }
            .onChange(of: texts) { _ in
                guard texts.count > 1 else { return }
                // Re-align to current group cycle if texts change
                localCurrentIndex = safeIndex(for: group.cycle)
                lastCycle = group.cycle
            }
    }
    
    private var currentText: String {
        guard !texts.isEmpty else { return "" }
        return texts[localCurrentIndex]
    }
    
    private func safeIndex(for cycle: Int) -> Int {
        guard texts.count > 0 else { return 0 }
        return mod(cycle, texts.count)
    }
    
    private func mod(_ a: Int, _ n: Int) -> Int { ((a % n) + n) % n }
}

// MARK: - View Modifier

public struct BlendingSyncGroupModifier: ViewModifier {
    let groupId: String
    let duration: TimeInterval
    
    public func body(content: Content) -> some View {
        content
            .environment(\.CC_blendingSyncGroup, BlendingSyncManager.shared.group(id: groupId, duration: duration))
    }
}

extension View {
    public func CC_blendingSyncGroup(_ groupId: String, duration: TimeInterval = 2.0) -> some View {
        modifier(BlendingSyncGroupModifier(groupId: groupId, duration: duration))
    }
}

// MARK: - Example

#if DEBUG
#Preview("SynchronizedBlendingTextLabel - Scroll Sync Showcase") {
    struct SyncShowcase: View {
        @State private var useSync = true
        
        // A diverse set of short lists we will repeat to ensure scrolling
        let sampleDataBase = [
            ["Loading", "Processing", "Working"],
            ["Hello", "World", "SwiftUI"],
            ["Fast", "Quick", "Rapid"],
            ["Code", "Build", "Test"],
            ["iOS", "macOS", "tvOS"],
            ["Red", "Blue", "Green"],
            ["Start", "Continue", "Finish"],
            ["One", "Two", "Three", "Four"],
            ["Alpha", "Beta", "Gamma"],
            ["Sun", "Moon", "Stars"],
        ]
        // Build a long list by repeating the base
        var sampleData: [[String]] {
            (0..<30).map { i in sampleDataBase[i % sampleDataBase.count] }
        }
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    Toggle("Use Synchronization", isOn: $useSync)
                        .padding()
                    
                    // Tall scroll view so cells appear at different times
                    ScrollView {
                        VStack(spacing: 24) {
                            // A: Single group list (1.5s)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("List — Single Group (1.5s)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(sampleData.enumerated()), id: \.offset) { item in
                                        HStack {
                                            Text("#\(item.offset + 1)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .frame(width: 40, alignment: .leading)
                                            if useSync {
                                                SynchronizedBlendingTextLabel(item.element, duration: 1.5)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                            } else {
                                                BlendingTextLabel(item.element, duration: 1.5)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                        .background(Color.blue.opacity(0.08))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .CC_blendingSyncGroup("listFast", duration: 1.5)

                            // B: Alternating groups per row (Fast/Slow)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("List — Alternating Groups (Fast 1.5s / Slow 3.0s)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(sampleData.enumerated()), id: \.offset) { item in
                                        let isSlow = item.offset % 2 == 1
                                        HStack(spacing: 8) {
                                            Text("#\(item.offset + 1)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .frame(width: 40, alignment: .leading)
                                            if useSync {
                                                SynchronizedBlendingTextLabel(item.element, duration: isSlow ? 3.0 : 1.5)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                            } else {
                                                BlendingTextLabel(item.element, duration: isSlow ? 3.0 : 1.5)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                            }
                                            // Badge indicating which group
                                            Text(isSlow ? "SLOW" : "FAST")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background((isSlow ? Color.blue : Color.red).opacity(0.15))
                                                .foregroundStyle(isSlow ? .blue : .red)
                                                .clipShape(Capsule())
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                        .background((isSlow ? Color.blue : Color.red).opacity(0.06))
                                        .cornerRadius(8)
                                        .CC_blendingSyncGroup(isSlow ? "listSlow" : "listFast", duration: isSlow ? 3.0 : 1.5)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    
                    // Multiple groups example
                    VStack(spacing: 10) {
                        Text("Multiple Sync Groups")
                            .font(.headline)
                        Text("Left: Fast (1.5s)  •  Right: Slow (3.0s)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                    HStack(spacing: 20) {
                        VStack {
                            Text("Fast Group (1.5s)\nID: fast")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            SynchronizedBlendingTextLabel(["●", "●", "●"], duration: 1.5)
                                .font(.largeTitle)
                                .foregroundStyle(.red)
                            GroupCycleIndicator()
                        }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red.opacity(0.4), lineWidth: 1)
                            )
                            .cornerRadius(10)
                            .CC_blendingSyncGroup("fast", duration: 1.5)
                            
                        VStack {
                            Text("Slow Group (3.0s)\nID: slow")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            SynchronizedBlendingTextLabel(["◆", "◆", "◆"], duration: 3.0)
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                            GroupCycleIndicator()
                        }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                            )
                            .cornerRadius(10)
                            .CC_blendingSyncGroup("slow", duration: 3.0)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
                .navigationTitle("Sync Demo")
            }
        }
    }
    
    return SyncShowcase()
}
#endif

#if DEBUG
private struct GroupCycleIndicator: View {
    @Environment(\.CC_blendingSyncGroup) private var environmentGroup
    var body: some View {
        if let g = environmentGroup {
            GroupCycleIndicatorObserved(group: g)
        }
    }
}

private struct GroupCycleIndicatorObserved: View {
    @ObservedObject var group: BlendingSyncGroup
    var body: some View {
        HStack(spacing: 8) {
            let phase = (group.phase == .visible) ? "Visible" : "Fading"
            Text("Cycle: \(group.cycle)")
            Text(phase)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }
}
#endif
