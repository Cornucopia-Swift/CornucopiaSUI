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
    
    public func updateGroupDuration(id: String, duration: TimeInterval) {
        // Remove and recreate the group with new duration
        groups.removeValue(forKey: id)
        let newGroup = BlendingSyncGroup(id: id, duration: duration)
        groups[id] = newGroup
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