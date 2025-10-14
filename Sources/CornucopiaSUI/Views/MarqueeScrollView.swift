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
    private let scrollActivationThreshold: CGFloat = 1.0
    
    @State private var animate = false
    @State private var containerSize: CGSize = .zero
    @State private var contentSize: CGSize = .zero
    
    /// Creates a marquee scroll view with the given content.
    public init(
        startDelay: Double = 3.0,
        alignment: Alignment = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.startDelay = startDelay
        self.alignment = alignment
    }
    
    public var body: some View {
        marqueeContent
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                containerSize = newSize
                updateAnimationState()
            }
    }
    
    @ViewBuilder
    private var marqueeContent: some View {
        let needsScrolling = shouldAnimateScroll()
        
        if needsScrolling {
            scrollingContent
                .clipped()
        } else {
            staticContent
        }
    }
    
    @ViewBuilder
    private var scrollingContent: some View {
        let animation = Animation
            .linear(duration: Double(contentSize.width) / 30)
            .delay(startDelay)
            .repeatForever(autoreverses: false)
        
        ZStack(alignment: .leading) {
            // First copy
            content
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: animate ? -contentSize.width - contentSize.height * 2 : 0)
                .animation(animate ? animation : .linear(duration: 0), value: animate)
            
            // Second copy for seamless loop
            content
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: animate ? 0 : contentSize.width + contentSize.height * 2)
                .animation(animate ? animation : .linear(duration: 0), value: animate)
        }
        .frame(width: containerSize.width, alignment: .leading)
        .background {
            // Invisible copy for measuring content size
            content
                .fixedSize()
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { newSize in
                    contentSize = newSize
                    updateAnimationState()
                }
                .opacity(0)
        }
        .onAppear {
            updateAnimationState()
        }
        .onDisappear {
            animate = false
        }
    }
    
    @ViewBuilder
    private var staticContent: some View {
        content
            .frame(maxWidth: .infinity, alignment: alignment)
            .background {
                // Invisible copy for measuring content size
                content
                    .fixedSize()
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { newSize in
                        contentSize = newSize
                    }
                    .opacity(0)
            }
    }
    
    private func updateAnimationState() {
        let shouldAnimate = shouldAnimateScroll()
        if animate != shouldAnimate {
            animate = shouldAnimate
        }
    }
    
    private func shouldAnimateScroll() -> Bool {
        guard containerSize.width > 0 else { return false }
        return (contentSize.width - containerSize.width) > scrollActivationThreshold
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
                        .textFieldStyle(.roundedBorder)
                    
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
                            Slider(value: $startDelay, in: 0...5, step: 0.5)
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
