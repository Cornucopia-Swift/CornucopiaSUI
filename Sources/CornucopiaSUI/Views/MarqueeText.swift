//
//  Cornucopia – (C) Dr. Lauer Information Technology
//

/**

 This code is based on https://github.com/joekndy/MarqueeText with the following modifications:
 - Remove dependency on `UIFont`, that way we can just use the SwiftUI regular font modifiers.
 - Remove gradient mask. This was responsible for [drawing outside bounds](https://github.com/joekndy/MarqueeText/issues/14). IMHO: If it isn't possible to show the
 gradient mask only while scrolling, it does visually more harm than good.
 - Adjust initializer.

 */
import SwiftUI

public struct MarqueeText : View {
    public var text: String
    public var startDelay: Double
    public var alignment: Alignment

    @Environment(\.font) private var font
    @State private var animate = false
    @State private var textSize: CGSize = .zero

    /// Create a scrolling text view.
    public init(_ text: String, startDelay: Double = 3.0, alignment: Alignment? = nil) {
        self.text = text
        self.startDelay = startDelay
        self.alignment = alignment != nil ? alignment! : .topLeading
    }

    public var body : some View {

        let animation = Animation
            .linear(duration: Double(textSize.width) / 30)
            .delay(startDelay)
            .repeatForever(autoreverses: false)

        let nullAnimation = Animation
            .linear(duration: 0)

        return ZStack {
            GeometryReader { geo in
                if textSize.width > geo.size.width { // don't use self.animate as conditional here
                    Group {
                        Text(self.text)
                            .lineLimit(1)
                            .offset(x: self.animate ? -textSize.width - textSize.height * 2 : 0)
                            .animation(self.animate ? animation : nullAnimation, value: self.animate)
                            .onAppear {
                                DispatchQueue.main.async {
                                    self.animate = geo.size.width < textSize.width
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)

                        Text(self.text)
                            .lineLimit(1)
                            .offset(x: self.animate ? 0 : textSize.width + textSize.height * 2)
                            .animation(self.animate ? animation : nullAnimation, value: self.animate)
                            .onAppear {
                                DispatchQueue.main.async {
                                    self.animate = geo.size.width < textSize.width
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .onChange(of: self.text, perform: { _ in
                        self.animate = geo.size.width < textSize.width
                    })
                    .clipped()
                    .frame(width: geo.size.width)

                } else {
                    Text(self.text)
                        .onChange(of: self.text, perform: { text in
                            self.animate = geo.size.width < textSize.width
                        })
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: alignment)
                }
            }
        }
        .overlay {
            Text(self.text)
                .lineLimit(1)
                .fixedSize()
                .CC_measureSize(perform: { size in
                    self.textSize = size
                })
                .hidden()
        }
        .frame(height: textSize.height)
        .onDisappear { self.animate = false }
    }
}

//MARK: - Example
#if DEBUG
struct MarqueeTextPreviewProvider: PreviewProvider {
    static var previews: some View {
        MarqueeText("This is an example which hopefully starts to scroll, otherwise we couldn't demonstrate anything...")
    }
}
#endif
