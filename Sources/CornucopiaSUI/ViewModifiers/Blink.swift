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
//MARK: - Example
fileprivate struct BlinkView: View {

    var body: some View {
        VStack {
            Text("Soft Blinking")
                .padding()
                .CC_blinking(style: .soft)
            Text("Hard Blinking")
                .padding()
                .CC_blinking(style: .hard)
        }
    }
}

struct Blink_Previews: PreviewProvider {
    static var previews: some View {
        BlinkView()
    }
}
#endif
