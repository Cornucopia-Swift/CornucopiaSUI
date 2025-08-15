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
#Preview("MarqueeText - Comprehensive") {
    struct MarqueeTextShowcase: View {
        @State private var shortText = "Short text"
        @State private var longText = "This is a very long text that will definitely need to scroll because it's too long to fit in the available space"
        @State private var customAlignment = "Center aligned marquee text that scrolls when it's too long for the container"
        
        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    Text("MarqueeText Showcase")
                        .font(.largeTitle)
                        .padding(.bottom)
                    
                    // Short text that doesn't scroll
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Short Text (No Scrolling)")
                            .font(.headline)
                        MarqueeText(shortText)
                            .font(.body)
                            .frame(width: 200)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Long text with default settings
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Long Text (Default Delay: 3s)")
                            .font(.headline)
                        MarqueeText(longText)
                            .font(.body)
                            .frame(width: 250)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Custom start delay
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Custom Start Delay (1s)")
                            .font(.headline)
                        MarqueeText("Quick start scrolling text with a shorter delay before animation begins", startDelay: 1.0)
                            .font(.body)
                            .frame(width: 200)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // No delay
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No Delay (Immediate Start)")
                            .font(.headline)
                        MarqueeText("This text starts scrolling immediately without any delay", startDelay: 0)
                            .font(.body)
                            .frame(width: 180)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Different alignments
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Different Alignments")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            MarqueeText("Leading alignment text", alignment: .leading)
                                .font(.caption)
                                .frame(width: 150)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            
                            MarqueeText(customAlignment, alignment: .center)
                                .font(.caption)
                                .frame(width: 150)
                                .padding()
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(8)
                            
                            MarqueeText("Trailing alignment text that scrolls", alignment: .trailing)
                                .font(.caption)
                                .frame(width: 150)
                                .padding()
                                .background(Color.mint.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Different font styles
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Various Font Styles")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            MarqueeText("Large Title Font - Scrolling text with large title styling for prominence")
                                .font(.largeTitle)
                                .frame(width: 300)
                                .padding()
                                .background(Color.indigo.opacity(0.1))
                                .cornerRadius(8)
                            
                            MarqueeText("Bold Caption - Small but bold text that scrolls smoothly across the view")
                                .font(.caption)
                                .bold()
                                .frame(width: 200)
                                .padding()
                                .background(Color.teal.opacity(0.1))
                                .cornerRadius(8)
                            
                            MarqueeText("Monospaced Font - CODE_EXAMPLE_TEXT_THAT_SCROLLS_CONTINUOUSLY")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 250)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Dynamic text update
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Dynamic Text Update")
                            .font(.headline)
                        
                        let texts = [
                            "First message that scrolls",
                            "Second longer message that definitely needs to scroll across the view",
                            "Third",
                            "Fourth message with even more content to demonstrate the scrolling behavior"
                        ]
                        @State var currentIndex = 0
                        
                        MarqueeText(texts[currentIndex])
                            .font(.body)
                            .frame(width: 200)
                            .padding()
                            .background(Color.cyan.opacity(0.1))
                            .cornerRadius(8)
                        
                        Button("Next Message") {
                            currentIndex = (currentIndex + 1) % texts.count
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
        }
    }
    
    return MarqueeTextShowcase()
}
#endif
