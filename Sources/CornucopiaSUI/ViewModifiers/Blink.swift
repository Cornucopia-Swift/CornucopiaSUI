//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Combine
import SwiftUI

/// Blinks the content.
public struct Blink: ViewModifier {

    /// The blink style.
    public enum Style {
        case hard
        case soft
    }

    private var style: Style
    private var duration: TimeInterval
    @State private var repeatCount: Int
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>? = nil

    public init(style: Style = .hard, duration: TimeInterval = 1.0, repeatCount: Int = Int.max) {
        self.style = style
        self.duration = duration
        self.repeatCount = repeatCount

        if self.style == .hard {
            self.timer = Timer.publish(every: duration, on: .main, in: .common).autoconnect()
        }
    }

    @State private var visible: Bool = true

    public func body(content: Content) -> some View {

        if style == .soft {
            // In the `.soft` case, we can leverage an ``Animation``:
            content
                .opacity(visible ? 1.0 : 0.0)
                .onAppear {
                    let animation = Animation.easeInOut(duration: self.duration).repeatCount(self.repeatCount, autoreverses: true)
                    withAnimation(animation) {
                        visible.toggle()
                    }
                }
        } else {
            // In the `.hard` case, we rely on a ``Timer``:
            content
                .opacity(visible ? 1.0 : 0.0)
                .onReceive(self.timer!) { _ in
                    visible.toggle()
                    if visible {
                        self.repeatCount -= 1
                        if self.repeatCount == 0 {
                            timer?.upstream.connect().cancel()
                        }
                    }
                }
        }
    }
}

extension View {
    /// Lets the content blink in the desired `style`. Every blink phase has the given `duration` and repeats for `repeatCount` times. Use `Int.max` for "forever".
    public func CC_blinking(style: Blink.Style = .hard, duration: TimeInterval = 1.0, repeatCount: Int = Int.max) -> some View {
        modifier(Blink(style: style, duration: duration, repeatCount: repeatCount))
    }
}
#if DEBUG
#Preview("Blink - Comprehensive") {
    struct BlinkShowcase: View {
        @State private var isBlinking = true
        @State private var customRepeatCount = 5
        
        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    Text("Blink Modifier Showcase")
                        .font(.largeTitle)
                        .padding(.bottom)
                    
                    Toggle("Enable Blinking", isOn: $isBlinking)
                        .padding(.horizontal)
                    
                    if isBlinking {
                        // Soft vs Hard blinking
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Blinking Styles")
                                .font(.headline)
                            
                            HStack(spacing: 30) {
                                VStack {
                                    Text("Soft Blink")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Smooth")
                                        .padding()
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                        .CC_blinking(style: .soft, duration: 1.0)
                                }
                                
                                VStack {
                                    Text("Hard Blink")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Instant")
                                        .padding()
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(8)
                                        .CC_blinking(style: .hard, duration: 1.0)
                                }
                            }
                        }
                        
                        // Different durations
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Duration Variations")
                                .font(.headline)
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("0.3s")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 50, height: 50)
                                        .CC_blinking(style: .soft, duration: 0.3)
                                }
                                
                                VStack {
                                    Text("0.7s")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Circle()
                                        .fill(Color.purple)
                                        .frame(width: 50, height: 50)
                                        .CC_blinking(style: .soft, duration: 0.7)
                                }
                                
                                VStack {
                                    Text("1.5s")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 50, height: 50)
                                        .CC_blinking(style: .soft, duration: 1.5)
                                }
                                
                                VStack {
                                    Text("3.0s")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Circle()
                                        .fill(Color.indigo)
                                        .frame(width: 50, height: 50)
                                        .CC_blinking(style: .soft, duration: 3.0)
                                }
                            }
                        }
                        
                        // Repeat count examples
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Repeat Count")
                                .font(.headline)
                            
                            VStack(spacing: 15) {
                                HStack {
                                    Text("3 times:")
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.teal.opacity(0.3))
                                        .frame(width: 150, height: 40)
                                        .overlay {
                                            Text("Limited")
                                                .foregroundColor(.white)
                                        }
                                        .CC_blinking(style: .soft, duration: 0.5, repeatCount: 3)
                                }
                                
                                HStack {
                                    Text("Custom (\(customRepeatCount) times):")
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.mint.opacity(0.3))
                                        .frame(width: 150, height: 40)
                                        .overlay {
                                            Text("Adjustable")
                                                .foregroundColor(.white)
                                        }
                                        .CC_blinking(style: .soft, duration: 0.5, repeatCount: customRepeatCount)
                                }
                                
                                Stepper("Repeat Count: \(customRepeatCount)", value: $customRepeatCount, in: 1...10)
                                    .padding(.horizontal)
                                
                                HStack {
                                    Text("Forever:")
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.cyan.opacity(0.3))
                                        .frame(width: 150, height: 40)
                                        .overlay {
                                            Text("Infinite")
                                                .foregroundColor(.white)
                                        }
                                        .CC_blinking(style: .soft, duration: 1.0, repeatCount: Int.max)
                                }
                            }
                        }
                        
                        // Practical examples
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Practical Examples")
                                .font(.headline)
                            
                            VStack(spacing: 20) {
                                // Alert indicator
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                        .CC_blinking(style: .hard, duration: 0.8)
                                    Text("Warning: Low Battery")
                                        .font(.callout)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                                
                                // Recording indicator
                                HStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 12, height: 12)
                                        .CC_blinking(style: .soft, duration: 1.0)
                                    Text("Recording...")
                                        .font(.callout)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                
                                // Loading state
                                Text("Processing...")
                                    .font(.headline)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                    .CC_blinking(style: .soft, duration: 1.5)
                            }
                        }
                        
                        // Complex view blinking
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Complex View Blinking")
                                .font(.headline)
                            
                            VStack(spacing: 10) {
                                Image(systemName: "star.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.yellow)
                                Text("Achievement Unlocked!")
                                    .font(.headline)
                                Text("You've reached 100 points")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.yellow.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.yellow, lineWidth: 2)
                                    )
                            )
                            .CC_blinking(style: .soft, duration: 0.8, repeatCount: 5)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    return BlinkShowcase()
}
#endif
