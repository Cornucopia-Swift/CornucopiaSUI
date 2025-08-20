//
//  Cornucopia – (C) Dr. Lauer Information Technology
//

import SwiftUI

public enum BlendingAnimationStyle {
    case fade
    case slide(Edge)
    case scale
    case flip
    case bulletinBoard
    
    public static var slideLeading: BlendingAnimationStyle { .slide(.leading) }
    public static var slideTrailing: BlendingAnimationStyle { .slide(.trailing) }
    public static var slideTop: BlendingAnimationStyle { .slide(.top) }
    public static var slideBottom: BlendingAnimationStyle { .slide(.bottom) }
}

public struct BlendingTextLabel: View {
    private let texts: [String]
    private let duration: TimeInterval
    private let animationStyle: BlendingAnimationStyle
    
    @State private var currentIndex: Int = 0
    @State private var nextIndex: Int = 1
    @State private var animationPhase: Double = 0.0
    @State private var timer: Timer?
    @State private var flipProgress: [Double] = []
    @State private var bulletinCharacters: [String] = []
    
    public init(_ texts: [String], duration: TimeInterval = 2.0, animationStyle: BlendingAnimationStyle = .fade) {
        self.texts = texts
        self.duration = duration
        self.animationStyle = animationStyle
    }
    
    public var body: some View {
        ZStack {
            switch animationStyle {
            case .fade:
                fadeAnimation
            case .slide(let edge):
                slideAnimation(edge: edge)
            case .scale:
                scaleAnimation
            case .flip:
                flipAnimation
            case .bulletinBoard:
                bulletinBoardAnimation
            }
        }
        .onAppear {
            if case .bulletinBoard = animationStyle {
                initializeBulletinBoard()
            }
            guard texts.count > 1 else { return }
            startAnimating()
        }
        .onDisappear {
            stopAnimating()
        }
        .onChange(of: texts) { _ in
            guard texts.count > 1 else {
                stopAnimating()
                return
            }
            currentIndex = 0
            nextIndex = 1
            animationPhase = 0.0
            stopAnimating()
            if case .bulletinBoard = animationStyle {
                initializeBulletinBoard()
            }
            startAnimating()
        }
    }
    
    @ViewBuilder
    private var fadeAnimation: some View {
        Text(currentText)
            .opacity(1.0 - animationPhase)
            .overlay(
                Text(nextText)
                    .opacity(animationPhase)
            )
    }
    
    @ViewBuilder
    private func slideAnimation(edge: Edge) -> some View {
        GeometryReader { geometry in
            let offset = calculateSlideOffset(for: edge, in: geometry.size)
            
            Text(currentText)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: offset.current.width, y: offset.current.height)
            
            Text(nextText)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: offset.next.width, y: offset.next.height)
        }
    }
    
    private func calculateSlideOffset(for edge: Edge, in size: CGSize) -> (current: CGSize, next: CGSize) {
        switch edge {
        case .leading:
            return (
                current: CGSize(width: -size.width * animationPhase, height: 0),
                next: CGSize(width: size.width * (1 - animationPhase), height: 0)
            )
        case .trailing:
            return (
                current: CGSize(width: size.width * animationPhase, height: 0),
                next: CGSize(width: -size.width * (1 - animationPhase), height: 0)
            )
        case .top:
            return (
                current: CGSize(width: 0, height: -size.height * animationPhase),
                next: CGSize(width: 0, height: size.height * (1 - animationPhase))
            )
        case .bottom:
            return (
                current: CGSize(width: 0, height: size.height * animationPhase),
                next: CGSize(width: 0, height: -size.height * (1 - animationPhase))
            )
        }
    }
    
    @ViewBuilder
    private var scaleAnimation: some View {
        Text(currentText)
            .scaleEffect(1.0 - animationPhase * 0.5)
            .opacity(1.0 - animationPhase)
            .overlay(
                Text(nextText)
                    .scaleEffect(0.5 + animationPhase * 0.5)
                    .opacity(animationPhase)
            )
    }
    
    @ViewBuilder
    private var flipAnimation: some View {
        let rotation = animationPhase * 180
        let showNext = rotation > 90
        
        Text(showNext ? nextText : currentText)
            .rotation3DEffect(
                .degrees(showNext ? rotation - 180 : rotation),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
    }
    
    @ViewBuilder
    private var bulletinBoardAnimation: some View {
        let displayText = bulletinCharacters.isEmpty ? currentText.map { String($0) } : bulletinCharacters
        
        HStack(spacing: 0) {
            ForEach(0..<displayText.count, id: \.self) { index in
                BulletinCharacterView(
                    character: displayText[index]
                )
            }
        }
    }
    
    private var currentText: String {
        guard !texts.isEmpty else { return "" }
        return texts[currentIndex]
    }
    
    private var nextText: String {
        guard !texts.isEmpty else { return "" }
        return texts[nextIndex]
    }
    
    private func initializeBulletinBoard() {
        bulletinCharacters = currentText.map { String($0) }
    }
    
    private func startAnimating() {
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
            switch animationStyle {
            case .bulletinBoard:
                animateBulletinBoard()
            default:
                animateTransition()
            }
        }
    }
    
    private func animateTransition() {
        withAnimation(.easeInOut(duration: 0.5)) {
            animationPhase = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            currentIndex = nextIndex
            nextIndex = (nextIndex + 1) % texts.count
            animationPhase = 0.0
        }
    }
    
    private func animateBulletinBoard() {
        let targetChars = Array(nextText)
        let maxLength = max(bulletinCharacters.count, targetChars.count)
        
        // Ensure bulletinCharacters has the right length
        while bulletinCharacters.count < maxLength {
            bulletinCharacters.append(" ")
        }
        while bulletinCharacters.count > maxLength {
            bulletinCharacters.removeLast()
        }
        
        // Available characters for flipping effect
        let flipChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-:/ "
        let flipArray = Array(flipChars)
        
        for index in 0..<maxLength {
            let targetChar = index < targetChars.count ? targetChars[index] : Character(" ")
            let delay = Double(index) * 0.05 // Staggered start for each character
            let flipCount = 10 // Increased number of random flips before settling
            
            // Create flip sequence for this character
            for flip in 0..<flipCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + Double(flip) * 0.06) {
                    if index < bulletinCharacters.count {
                        if flip < flipCount - 1 {
                            // Random character during flip
                            let randomChar = flipArray.randomElement() ?? Character(" ")
                            withAnimation(.linear(duration: 0.03)) {
                                bulletinCharacters[index] = String(randomChar)
                            }
                        } else {
                            // Final character with spring animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                bulletinCharacters[index] = String(targetChar)
                            }
                        }
                    }
                }
            }
        }
        
        // Update indices after animation completes
        let totalAnimationTime = Double(maxLength) * 0.05 + Double(10) * 0.06
        DispatchQueue.main.asyncAfter(deadline: .now() + totalAnimationTime + 0.3) {
            currentIndex = nextIndex
            nextIndex = (nextIndex + 1) % texts.count
        }
    }
    
    private func stopAnimating() {
        timer?.invalidate()
        timer = nil
    }
}

struct BulletinCharacterView: View {
    let character: String
    
    var body: some View {
        Text(character)
            .font(.system(.body, design: .monospaced))
            .frame(minWidth: 12)
            .transition(.opacity.combined(with: .scale))
            .animation(.linear(duration: 0.03), value: character)
    }
}

//MARK: - Example
#if DEBUG
#Preview("BlendingTextLabel - Animation Styles") {
    struct AnimationStyleShowcase: View {
        @State private var selectedStyle: Int = 0
        @State private var customDuration: Double = 2.0
        
        let styles: [(name: String, style: BlendingAnimationStyle)] = [
            ("Fade", .fade),
            ("Slide Leading", .slideLeading),
            ("Slide Trailing", .slideTrailing),
            ("Slide Top", .slideTop),
            ("Slide Bottom", .slideBottom),
            ("Scale", .scale),
            ("Flip", .flip),
            ("Bulletin Board", .bulletinBoard)
        ]
        
        let sampleTexts = ["Innovation", "Technology", "Excellence", "Progress"]
        
        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    Text("BlendingTextLabel Animation Styles")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    VStack(spacing: 20) {
                        HStack {
                            Text("Animation Style:")
                                .font(.headline)
                            
                            Menu {
                                ForEach(0..<styles.count, id: \.self) { index in
                                    Button(styles[index].name) {
                                        selectedStyle = index
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(styles[selectedStyle].name)
                                        .foregroundColor(.primary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("Duration: \(customDuration, specifier: "%.1f")s")
                            Slider(value: $customDuration, in: 0.5...5.0, step: 0.1)
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(spacing: 15) {
                        Text("Current Style: \(styles[selectedStyle].name)")
                            .font(.headline)
                        
                        BlendingTextLabel(
                            sampleTexts,
                            duration: customDuration,
                            animationStyle: styles[selectedStyle].style
                        )
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundStyle(.blue)
                        .frame(height: 60)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .id(selectedStyle) // Force view recreation when style changes
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("All Styles Preview")
                            .font(.headline)
                        
                        ForEach(styles, id: \.name) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                BlendingTextLabel(
                                    ["Hello", "World", "Swift"],
                                    duration: 2.0,
                                    animationStyle: item.style
                                )
                                .font(.title2)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(height: 40)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Special Effects")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Airport Departure Board")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            BlendingTextLabel(
                                ["DEPARTING", "ON TIME", "BOARDING", "DELAYED"],
                                duration: 3.0,
                                animationStyle: .bulletinBoard
                            )
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundStyle(.green)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status Indicator")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                
                                BlendingTextLabel(
                                    ["Connecting", "Connected", "Active", "Ready"],
                                    duration: 1.5,
                                    animationStyle: .scale
                                )
                                .font(.body)
                                .foregroundStyle(.primary)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
    }
    
    return AnimationStyleShowcase()
}
#endif

