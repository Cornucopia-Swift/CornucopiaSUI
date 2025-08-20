//
//  Cornucopia – (C) Dr. Lauer Information Technology
//

import SwiftUI

public struct BlendingTextLabel: View {
    private let texts: [String]
    private let duration: TimeInterval
    
    @State private var currentIndex: Int = 0
    @State private var opacity: Double = 1.0
    
    public init(_ texts: [String], duration: TimeInterval = 2.0) {
        self.texts = texts
        self.duration = duration
    }
    
    public var body: some View {
        Text(currentText)
            .opacity(opacity)
            .onAppear {
                guard texts.count > 1 else { return }
                startBlending()
            }
            .onChange(of: texts) { _ in
                guard texts.count > 1 else { return }
                currentIndex = 0
                opacity = 1.0
                startBlending()
            }
    }
    
    private var currentText: String {
        guard !texts.isEmpty else { return "" }
        return texts[currentIndex]
    }
    
    private func startBlending() {
        Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentIndex = (currentIndex + 1) % texts.count
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 1.0
                }
            }
        }
    }
}

//MARK: - Example
#if DEBUG
#Preview("BlendingTextLabel - Comprehensive") {
    struct BlendingTextShowcase: View {
        @State private var customTexts = ["Dynamic", "Interactive", "Changeable"]
        @State private var customDuration: Double = 1.5
        
        var body: some View {
            ScrollView {
                VStack(spacing: 40) {
                    Text("BlendingTextLabel Showcase")
                        .font(.largeTitle)
                        .padding(.bottom)
                    
                    // Basic usage with default duration
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Basic Usage (2s duration)")
                            .font(.headline)
                        BlendingTextLabel(["Hello", "World", "SwiftUI"])
                            .font(.title)
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Fast transitions
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Fast Transitions (0.8s duration)")
                            .font(.headline)
                        BlendingTextLabel(["Quick", "Fast", "Rapid", "Swift"], duration: 0.8)
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Slow transitions
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Slow Transitions (4s duration)")
                            .font(.headline)
                        BlendingTextLabel(["Peaceful", "Calm", "Serene"], duration: 4.0)
                            .font(.title2)
                            .foregroundStyle(.green)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Different font styles
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Various Font Styles")
                            .font(.headline)
                        
                        // Large title
                        BlendingTextLabel(["BOLD", "STRONG", "POWERFUL"], duration: 1.5)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.purple)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        
                        // Monospace
                        BlendingTextLabel(["CODE", "TECH", "DATA"], duration: 1.2)
                            .font(.system(.title3, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        
                        // Serif
                        BlendingTextLabel(["Elegant", "Classic", "Refined"], duration: 2.5)
                            .font(.system(.title2, design: .serif))
                            .italic()
                            .foregroundStyle(.brown)
                            .padding()
                            .background(Color.brown.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Status indicators
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Status Indicators")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            BlendingTextLabel(["●", "●", "●"], duration: 0.5)
                                .font(.title)
                                .foregroundStyle(.red)
                            
                            BlendingTextLabel(["Loading", "Processing", "Working"], duration: 1.0)
                                .font(.body)
                                .foregroundStyle(.blue)
                            
                            BlendingTextLabel(["…", "⋯", "⋱"], duration: 0.7)
                                .font(.title2)
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Single text (no blending)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Single Text (No Blending)")
                            .font(.headline)
                        BlendingTextLabel(["Static Text"])
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Empty array handling
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Empty Array (Graceful Handling)")
                            .font(.headline)
                        BlendingTextLabel([])
                            .font(.body)
                            .foregroundStyle(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Interactive example
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Interactive Controls")
                            .font(.headline)
                        
                        BlendingTextLabel(customTexts, duration: customDuration)
                            .font(.title2)
                            .foregroundStyle(.indigo)
                            .padding()
                            .background(Color.indigo.opacity(0.1))
                            .cornerRadius(12)
                        
                        VStack(spacing: 10) {
                            HStack {
                                Text("Duration: \(customDuration, specifier: "%.1f")s")
                                Slider(value: $customDuration, in: 0.5...5.0, step: 0.1)
                            }
                            
                            HStack {
                                Button("Tech Words") {
                                    customTexts = ["Swift", "SwiftUI", "iOS", "macOS"]
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Emotions") {
                                    customTexts = ["Happy", "Excited", "Joyful", "Cheerful"]
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Colors") {
                                    customTexts = ["Red", "Blue", "Green", "Yellow", "Purple"]
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    
                    // Very long text handling
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Long Text Handling")
                            .font(.headline)
                        BlendingTextLabel([
                            "This is a very long text that demonstrates how the component handles longer strings",
                            "Another lengthy sentence to show text blending capabilities",
                            "Short",
                            "Medium length text here"
                        ], duration: 3.0)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.teal.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
    }
    
    return BlendingTextShowcase()
}
#endif