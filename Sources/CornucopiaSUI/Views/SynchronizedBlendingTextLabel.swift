//
//  Cornucopia – (C) Dr. Lauer Information Technology
//

import SwiftUI

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
