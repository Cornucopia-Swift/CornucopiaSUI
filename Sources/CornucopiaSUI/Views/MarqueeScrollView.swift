//
//  Cornucopia – (C) Dr. Lauer Information Technology
//

/**

A generic auto-scrolling container that smoothly scrolls any SwiftUI content when it exceeds the available width.

This implementation was inspired by https://github.com/joekndy/MarqueeText with significant architectural changes:
- Redesigned as a generic container using @ViewBuilder pattern, similar to ScrollView
- Uses modern iOS 17+ SwiftUI APIs including onGeometryChange for better layout behavior  
- Eliminates GeometryReader to prevent layout issues and sizing problems
- Removes gradient masks that caused visual artifacts and drawing boundary issues
- Supports any SwiftUI content: Text, Labels, HStacks, custom views, etc.
- Everything scrolls together as a unified content block

Usage is similar to other SwiftUI containers:
```swift
MarqueeScrollView {
    Label("Long scrolling content", systemImage: "gear")
}
```

*/

import SwiftUI

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public struct MarqueeScrollView<Content: View>: View {
    private let content: Content
    private let startDelay: Double
    private let alignment: Alignment
    private let scrollActivationThreshold: CGFloat = -1.0
    private let gap: CGFloat = 32
    private let pointsPerSecond: CGFloat = 30
    private let loopPause: Double
    private let measurementTolerance: CGFloat = 0.5

    @State private var containerSize: CGSize = .zero
    @State private var contentSize: CGSize = .zero
    @State private var measurementVersion: Int = 0

    /// Creates a marquee scroll view with the given content.
    public init(
        startDelay: Double = 3.0,
        loopPause: Double? = nil,
        alignment: Alignment = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.startDelay = startDelay
        self.alignment = alignment
        self.loopPause = max(0, loopPause ?? startDelay)
    }
    
    public var body: some View {
        let _shouldAnimate = shouldAnimate

        return ZStack(alignment: alignment) {
            if _shouldAnimate {
                MarqueeTicker(
                    content: content,
                    contentSize: contentSize,
                    containerWidth: containerSize.width,
                    startDelay: startDelay,
                    loopPause: loopPause,
                    gap: gap,
                    pointsPerSecond: pointsPerSecond
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                content
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .frame(height: effectiveHeight, alignment: alignment)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            updateContainerSize(newSize)
        }
        .overlay(alignment: .topLeading) {
            content
                .fixedSize()
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { newSize in
                    updateContentSize(newSize)
                }
                .hidden()
                .allowsHitTesting(false)
        }
    }

    private var effectiveHeight: CGFloat? {
        contentSize.height > 0 ? contentSize.height : nil
    }

    private var shouldAnimate: Bool {
        MarqueeScrollLogic.shouldAnimate(
            contentWidth: contentSize.width,
            containerWidth: containerSize.width,
            threshold: scrollActivationThreshold
        )
    }

    private func updateContainerSize(_ size: CGSize) {
        let sanitizedSize = size.sanitizedForMarquee()
        guard sanitizedSize.isFinite else { return }
        guard !containerSize.isApproximatelyEqual(to: sanitizedSize, tolerance: measurementTolerance) else { return }
        containerSize = sanitizedSize
        measurementVersion += 1
        scheduleDebouncedDebugPrint()
    }

    private func updateContentSize(_ size: CGSize) {
        let sanitizedSize = size.sanitizedForMarquee()
        guard sanitizedSize.isFinite else { return }
        guard !contentSize.isApproximatelyEqual(to: sanitizedSize, tolerance: measurementTolerance) else { return }
        contentSize = sanitizedSize
        measurementVersion += 1
        scheduleDebouncedDebugPrint()
    }

    private func scheduleDebouncedDebugPrint() {
#if DEBUG
        Task { @MainActor in
            let version = measurementVersion
            try? await Task.sleep(for: .milliseconds(5))

            guard version == measurementVersion else { return }
            guard containerSize.width > 0, contentSize.width > 0 else { return }

            let willScroll = shouldAnimate
            print("DEBUG: MarqueeScrollView content: \(String(format: "%.0f", contentSize.width))w, container: \(String(format: "%.0f", containerSize.width))w → \(willScroll ? "SCROLLS" : "static")")
        }
#endif
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
private struct MarqueeTicker<Content: View>: View {
    let content: Content
    let contentSize: CGSize
    let containerWidth: CGFloat
    let startDelay: Double
    let loopPause: Double
    let gap: CGFloat
    let pointsPerSecond: CGFloat

    @State private var anchorDate: Date?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let anchor = preparedAnchor(for: context.date)
            timelineContent(context: context, anchor: anchor)
        }
        .onChange(of: contentSize) { _, _ in reset() }
        .onChange(of: containerWidth) { _, _ in reset() }
        .onChange(of: startDelay) { _, _ in reset() }
        .onDisappear { anchorDate = nil }
    }

    @ViewBuilder
    private func marqueeCopy(id: String) -> some View {
        content
            .fixedSize(horizontal: true, vertical: false)
            .padding(.trailing, gap)
            .frame(height: contentSize.height, alignment: .leading)
            .id(id)
    }

    private func reset() {
        anchorDate = nil
    }

    private func preparedAnchor(for now: Date) -> Date {
        if let anchorDate {
            return anchorDate
        }

        let anchor = now
        DispatchQueue.main.async {
            self.anchorDate = anchor
        }
        return anchor
    }

    @ViewBuilder
    private func timelineContent(context: TimelineViewDefaultContext, anchor: Date) -> some View {
        let cycleLength = contentSize.width + gap
        let width = containerWidth

        if cycleLength <= 0 || width <= 0 {
            content
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: width, height: contentSize.height, alignment: .leading)
        } else {
            let now = context.date
            let elapsed = max(0, now.timeIntervalSince(anchor) - startDelay)
            let calculator = MarqueeAnimationCalculator(
                cycleLength: cycleLength,
                pointsPerSecond: pointsPerSecond,
                loopPause: loopPause
            )
            let normalizedOffset = calculator.offset(for: elapsed)

            ZStack(alignment: .leading) {
                marqueeCopy(id: "first")
                    .offset(x: normalizedOffset)
                marqueeCopy(id: "second")
                    .offset(x: normalizedOffset + cycleLength)
            }
            .frame(width: width, height: contentSize.height, alignment: .leading)
            .clipped()
        }
    }

}

struct MarqueeScrollLogic {
    static func shouldAnimate(contentWidth: CGFloat, containerWidth: CGFloat, threshold: CGFloat) -> Bool {
        guard contentWidth > 0, containerWidth > 0 else { return false }
        return (contentWidth - containerWidth) > threshold
    }
}

struct MarqueeAnimationCalculator {
    let cycleLength: CGFloat
    let pointsPerSecond: CGFloat
    let loopPause: Double

    func offset(for elapsed: TimeInterval) -> CGFloat {
        guard cycleLength > 0, pointsPerSecond > 0, elapsed > 0 else { return 0 }

        let pause = max(0, loopPause)
        let travelDuration = Double(cycleLength / pointsPerSecond)
        guard travelDuration > 0 else { return 0 }

        let cycleDuration = travelDuration + pause
        let timeInCycle = elapsed.truncatingRemainder(dividingBy: cycleDuration)

        if timeInCycle < pause {
            return 0
        }

        let travelTime = min(timeInCycle - pause, travelDuration)
        let progress = travelTime / travelDuration
        return -CGFloat(progress) * cycleLength
    }
}

private extension CGSize {
    var isFinite: Bool {
        width.isFinite && height.isFinite
    }

    func isApproximatelyEqual(to other: CGSize, tolerance: CGFloat) -> Bool {
        abs(width - other.width) <= tolerance && abs(height - other.height) <= tolerance
    }

    func sanitizedForMarquee() -> CGSize {
        CGSize(
            width: Self.sanitizedDimension(width),
            height: Self.sanitizedDimension(height)
        )
    }

    private static func sanitizedDimension(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        guard !value.isNaN else { return 0 }
        return max(0, value)
    }
}

//MARK: - Examples
#if DEBUG
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview("Basic Usage") {
    struct BasicExamples: View {
        var body: some View {
            VStack(spacing: 20) {
                Text("Basic MarqueeScrollView Examples")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                Group {
                    // Simple text that doesn't need scrolling
                    MarqueeScrollView {
                        Text("Short text")
                    }
                    .frame(width: 200)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Long text that will scroll
                    MarqueeScrollView(startDelay: 1.0) {
                        Text("This is a very long text that will definitely need to scroll because it's too long to fit")
                    }
                    .frame(width: 250)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Immediate scrolling with no delay
                    MarqueeScrollView(startDelay: 0) {
                        Text("Scrolls immediately without delay")
                    }
                    .frame(width: 180)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Different alignment for non-scrolling content
                    MarqueeScrollView(alignment: .center) {
                        Text("Centered when short")
                    }
                    .frame(width: 200)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    return BasicExamples()
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview("Labels & Icons") {
    struct LabelsAndIcons: View {
        var body: some View {
            VStack(spacing: 20) {
                Text("Labels & Icons")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                Group {
                    // Standard labels with system images
                    MarqueeScrollView {
                        Label("Settings and Configuration Options", systemImage: "gear")
                    }
                    .frame(width: 200)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    MarqueeScrollView {
                        Label("Download Progress and Status Updates", systemImage: "arrow.down.circle")
                    }
                    .frame(width: 220)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    MarqueeScrollView {
                        Label("Favorite Items Collection", systemImage: "heart.fill")
                            .foregroundColor(.red)
                    }
                    .frame(width: 160)
                    .padding()
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Custom icon with text
                    MarqueeScrollView {
                        HStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom))
                                .frame(width: 16, height: 16)
                            Text("Custom gradient circle icon with descriptive text")
                        }
                    }
                    .frame(width: 200)
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    return LabelsAndIcons()
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview("Advanced Layouts") {
    struct AdvancedLayouts: View {
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Advanced Layout Examples")
                        .font(.largeTitle)
                        .padding(.bottom)
                    
                    Group {
                        // Multi-element rating display
                        MarqueeScrollView {
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                                Text("★★★★★")
                                Text("Absolutely fantastic product with amazing reviews!")
                                    .bold()
                            }
                        }
                        .frame(width: 250)
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Status indicators
                        MarqueeScrollView {
                            HStack(spacing: 8) {
                                HStack(spacing: 3) {
                                    Circle().fill(Color.green).frame(width: 8, height: 8)
                                    Circle().fill(Color.yellow).frame(width: 8, height: 8)
                                    Circle().fill(Color.red).frame(width: 8, height: 8)
                                }
                                Text("System Status:")
                                    .bold()
                                Text("All services operational and running smoothly")
                            }
                        }
                        .frame(width: 220)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Styled text combinations
                        MarqueeScrollView {
                            HStack {
                                Text("Welcome")
                                    .font(.title3)
                                    .bold()
                                Text("to our")
                                    .italic()
                                Text("Amazing")
                                    .foregroundColor(.blue)
                                    .bold()
                                Text("Application!")
                                    .underline()
                            }
                        }
                        .frame(width: 200)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Gradient text effect
                        MarqueeScrollView {
                            Text("Beautiful Gradient Text That Flows Seamlessly Across The Screen")
                                .font(.headline)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue, .cyan, .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .frame(width: 250)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Badge-style content
                        MarqueeScrollView {
                            HStack {
                                Text("NEW")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(4)
                                
                                Text("Exciting new features have been added to enhance your experience")
                            }
                        }
                        .frame(width: 230)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
    }
    return AdvancedLayouts()
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview("Music Player UI") {
    struct MusicPlayerExamples: View {
        @State private var songs = [
            ("Bohemian Rhapsody", "Queen", "6:07"),
            ("Stairway to Heaven", "Led Zeppelin", "8:02"),
            ("Hotel California", "Eagles", "6:31"),
            ("Sweet Child O' Mine", "Guns N' Roses", "5:03"),
            ("Imagine", "John Lennon", "3:07")
        ]
        @State private var currentSong = 0
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Music Player Interface")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                // Now Playing Display
                VStack(spacing: 16) {
                    Text("Now Playing")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    MarqueeScrollView(startDelay: 2.0) {
                        HStack(spacing: 12) {
                            // Album artwork placeholder
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "music.note")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(songs[currentSong].0)
                                    .font(.headline)
                                    .bold()
                                Text("by \(songs[currentSong].1)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(songs[currentSong].2)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .frame(width: 280)
                    .padding()
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Queue Preview
                    Text("Up Next")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        ForEach(0..<min(3, songs.count - currentSong - 1), id: \.self) { index in
                            let nextIndex = currentSong + 1 + index
                            if nextIndex < songs.count {
                                MarqueeScrollView(startDelay: Double(index + 1) * 0.5) {
                                    HStack {
                                        Text("\(nextIndex + 1).")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 20, alignment: .trailing)
                                        
                                        Text(songs[nextIndex].0)
                                            .font(.subheadline)
                                        
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        
                                        Text(songs[nextIndex].1)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(width: 250)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.secondary.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Control simulation
                    HStack(spacing: 20) {
                        Button("⏮") { 
                            currentSong = max(0, currentSong - 1)
                        }
                        .font(.title)
                        
                        Button("⏯") { }
                        .font(.title)
                        
                        Button("⏭") { 
                            currentSong = min(songs.count - 1, currentSong + 1)
                        }
                        .font(.title)
                    }
                    .padding()
                }
                
                // Podcast-style content
                VStack(spacing: 12) {
                    Text("Podcast Player")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    MarqueeScrollView(startDelay: 1.5) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "mic.fill")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("The Amazing Tech Podcast Episode 127")
                                    .font(.subheadline)
                                    .bold()
                                Text("Discussing the future of artificial intelligence and machine learning")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(width: 260)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }
    return MusicPlayerExamples()
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview("Interactive Demo") {
    struct InteractiveDemo: View {
        @State private var messages = [
            "Breaking: New technology breakthrough announced today",
            "Weather: Sunny skies ahead for the weekend",
            "Sports: Championship game tonight at 8 PM",
            "Quick update from our newsroom",
            "Traffic: Heavy congestion on Highway 101 southbound near downtown area"
        ]
        @State private var currentMessage = 0
        @State private var customText = "Edit this text to see live updates"
        @State private var scrollSpeed: Double = 30
        @State private var startDelay: Double = 2.0
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Interactive Demo")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                // News ticker simulation
                VStack(alignment: .leading, spacing: 10) {
                    Text("📺 News Ticker")
                        .font(.headline)
                    
                    MarqueeScrollView(startDelay: startDelay) {
                        HStack {
                            Text("LIVE")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(4)
                            
                            Text("•")
                                .foregroundColor(.red)
                                .bold()
                            
                            Text(messages[currentMessage])
                                .font(.subheadline)
                        }
                    }
                    .frame(width: 280)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Next News Item") {
                        currentMessage = (currentMessage + 1) % messages.count
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Custom text editor
                VStack(alignment: .leading, spacing: 10) {
                    Text("✏️ Live Text Editor")
                        .font(.headline)
                    
                    TextField("Enter custom text", text: $customText)
#if os(iOS) || os(macOS)
                        .textFieldStyle(.roundedBorder)
#endif
                    
                    MarqueeScrollView(startDelay: startDelay) {
                        Text(customText)
                            .font(.title3)
                    }
                    .frame(width: 200)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Divider()
                
                // Settings controls
                VStack(alignment: .leading, spacing: 10) {
                    Text("⚙️ Settings")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Start Delay: \(startDelay, specifier: "%.1f")s")
#if !os(tvOS)
                            Slider(value: $startDelay, in: 0...5, step: 0.5)
#endif
                        }
                        
                        // Demo with current settings
                        MarqueeScrollView(startDelay: startDelay) {
                            Text("This text uses your current delay setting of \(startDelay, specifier: "%.1f") seconds")
                        }
                        .frame(width: 200)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
    return InteractiveDemo()
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview("Real-World Examples") {
    struct RealWorldExamples: View {
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Real-World Use Cases")
                        .font(.largeTitle)
                        .padding(.bottom)
                    
                    Group {
                        // App Store style
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📱 App Store Style")
                                .font(.headline)
                            
                            MarqueeScrollView {
                                HStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            Text("📊")
                                                .font(.title2)
                                        }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Analytics Pro - Advanced Data Visualization Tool")
                                            .font(.subheadline)
                                            .bold()
                                        Text("Business • 4.8★ • #1 in Productivity")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(width: 280)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Notification banner
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🔔 Notification Banner")
                                .font(.headline)
                            
                            MarqueeScrollView(startDelay: 1.0) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.orange)
                                    Text("System maintenance scheduled for tonight at 2 AM EST. Expected downtime: 30 minutes.")
                                        .font(.subheadline)
                                }
                            }
                            .frame(width: 280)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Stock ticker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📈 Stock Ticker")
                                .font(.headline)
                            
                            MarqueeScrollView(startDelay: 0.5) {
                                HStack(spacing: 20) {
                                    ForEach(["AAPL +2.34%", "GOOGL -1.23%", "MSFT +0.89%", "TSLA +5.67%", "AMZN -0.45%"], id: \.self) { stock in
                                        HStack {
                                            let isPositive = stock.contains("+")
                                            Text(stock)
                                                .font(.system(.subheadline, design: .monospaced))
                                                .foregroundColor(isPositive ? .green : .red)
                                            
                                            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                                                .font(.caption)
                                                .foregroundColor(isPositive ? .green : .red)
                                        }
                                    }
                                }
                            }
                            .frame(width: 250)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.green)
                            .cornerRadius(8)
                        }
                        
                        // Social media post
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💬 Social Media Post")
                                .font(.headline)
                            
                            MarqueeScrollView {
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            Text("JD")
                                                .font(.caption)
                                                .bold()
                                                .foregroundColor(.white)
                                        }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text("@johndoe")
                                                .font(.subheadline)
                                                .bold()
                                            Text("• 2h")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Text("Just shipped a major update to our app! New features include dark mode, improved performance, and better accessibility support.")
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .frame(width: 280)
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                        }
                        
                        // Status bar
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📊 Status Bar")
                                .font(.headline)
                            
                            MarqueeScrollView(startDelay: 0) {
                                HStack(spacing: 15) {
                                    HStack {
                                        Circle().fill(Color.green).frame(width: 6, height: 6)
                                        Text("Server Online")
                                    }
                                    
                                    HStack {
                                        Circle().fill(Color.yellow).frame(width: 6, height: 6)
                                        Text("Database: 89% capacity")
                                    }
                                    
                                    HStack {
                                        Circle().fill(Color.green).frame(width: 6, height: 6)
                                        Text("API: 250ms response time")
                                    }
                                    
                                    HStack {
                                        Circle().fill(Color.red).frame(width: 6, height: 6)
                                        Text("Backup: Last run 2 days ago")
                                    }
                                }
                                .font(.caption)
                            }
                            .frame(width: 300)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding()
            }
        }
    }
    return RealWorldExamples()
}
#endif
