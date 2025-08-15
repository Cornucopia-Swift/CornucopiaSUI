// (C) Canis, taken from https://www.wooji-juice.com/blog/stupid-swiftui-tricks-single-axis-geometry-reader.html
import SwiftUI

struct SingleAxisGeometryReader<Content: View>: View {
    
    private struct SizeKey: PreferenceKey {
        static var defaultValue: CGFloat { 10 }
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    @State private var size: CGFloat = SizeKey.defaultValue

    var axis: Axis = .horizontal
    var alignment: Alignment = .center
    let content: (CGFloat) -> Content

    var body: some View {
        content(size)
            .frame(maxWidth:  axis == .horizontal ? .infinity : nil,
                   maxHeight: axis == .vertical   ? .infinity : nil,
                   alignment: alignment)
            .background(GeometryReader { proxy in
                Color.clear.preference(key: SizeKey.self, value: axis == .horizontal ? proxy.size.width : proxy.size.height)
            })
            .onPreferenceChange(SizeKey.self) { size = $0 }
    }
}

#if DEBUG
#Preview("SingleAxisGeometryReader - Comprehensive") {
    struct SingleAxisShowcase: View {
        @State private var containerWidth: CGFloat = 300
        @State private var containerHeight: CGFloat = 200
        
        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    Text("SingleAxisGeometryReader")
                        .font(.largeTitle)
                        .padding(.bottom)
                    
                    // Horizontal axis with different alignments
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Horizontal Axis - Alignments")
                            .font(.headline)
                        
                        VStack(spacing: 15) {
                            // Center alignment (default)
                            SingleAxisGeometryReader(axis: .horizontal, alignment: .center) { width in
                                VStack {
                                    Text("Center: \(width, specifier: "%.0f")px")
                                        .font(.caption)
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.3))
                                        .frame(width: width * 0.8, height: 50)
                                }
                            }
                            .frame(height: 80)
                            .background(Color.blue.opacity(0.1))
                            
                            // Leading alignment
                            SingleAxisGeometryReader(axis: .horizontal, alignment: .leading) { width in
                                VStack(alignment: .leading) {
                                    Text("Leading: \(width, specifier: "%.0f")px")
                                        .font(.caption)
                                    Rectangle()
                                        .fill(Color.green.opacity(0.3))
                                        .frame(width: width * 0.6, height: 50)
                                }
                            }
                            .frame(height: 80)
                            .background(Color.green.opacity(0.1))
                            
                            // Trailing alignment
                            SingleAxisGeometryReader(axis: .horizontal, alignment: .trailing) { width in
                                VStack(alignment: .trailing) {
                                    Text("Trailing: \(width, specifier: "%.0f")px")
                                        .font(.caption)
                                    Rectangle()
                                        .fill(Color.orange.opacity(0.3))
                                        .frame(width: width * 0.7, height: 50)
                                }
                            }
                            .frame(height: 80)
                            .background(Color.orange.opacity(0.1))
                        }
                        .padding(.horizontal)
                    }
                    
                    // Vertical axis with different alignments
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vertical Axis - Alignments")
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            // Center alignment
                            SingleAxisGeometryReader(axis: .vertical, alignment: .center) { height in
                                VStack {
                                    Text("Center")
                                        .font(.caption)
                                    Text("\(height, specifier: "%.0f")px")
                                        .font(.caption2)
                                    Rectangle()
                                        .fill(Color.purple.opacity(0.3))
                                        .frame(width: 80, height: height * 0.8)
                                }
                            }
                            .frame(width: 100, height: 200)
                            .background(Color.purple.opacity(0.1))
                            
                            // Top alignment
                            SingleAxisGeometryReader(axis: .vertical, alignment: .top) { height in
                                VStack {
                                    Text("Top")
                                        .font(.caption)
                                    Text("\(height, specifier: "%.0f")px")
                                        .font(.caption2)
                                    Rectangle()
                                        .fill(Color.mint.opacity(0.3))
                                        .frame(width: 80, height: height * 0.6)
                                }
                            }
                            .frame(width: 100, height: 200)
                            .background(Color.mint.opacity(0.1))
                            
                            // Bottom alignment
                            SingleAxisGeometryReader(axis: .vertical, alignment: .bottom) { height in
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(Color.indigo.opacity(0.3))
                                        .frame(width: 80, height: height * 0.7)
                                    Text("Bottom")
                                        .font(.caption)
                                    Text("\(height, specifier: "%.0f")px")
                                        .font(.caption2)
                                }
                            }
                            .frame(width: 100, height: 200)
                            .background(Color.indigo.opacity(0.1))
                        }
                    }
                    
                    // Dynamic resizing example
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Dynamic Container Resizing")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            SingleAxisGeometryReader(axis: .horizontal) { width in
                                VStack {
                                    Text("Responsive Width: \(width, specifier: "%.0f")px")
                                    HStack(spacing: 5) {
                                        ForEach(0..<Int(width/30), id: \.self) { _ in
                                            Rectangle()
                                                .fill(Color.red.opacity(0.3))
                                                .frame(width: 25, height: 40)
                                        }
                                    }
                                }
                            }
                            .frame(width: containerWidth, height: 80)
                            .background(Color.red.opacity(0.1))
                            .animation(.easeInOut, value: containerWidth)
                            
                            Slider(value: $containerWidth, in: 200...400) {
                                Text("Width")
                            }
                            .padding(.horizontal)
                        }
                        
                        VStack(spacing: 10) {
                            SingleAxisGeometryReader(axis: .vertical) { height in
                                HStack {
                                    Text("Height:\n\(height, specifier: "%.0f")px")
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                    VStack(spacing: 5) {
                                        ForEach(0..<Int(height/25), id: \.self) { _ in
                                            Rectangle()
                                                .fill(Color.teal.opacity(0.3))
                                                .frame(width: 60, height: 20)
                                        }
                                    }
                                }
                            }
                            .frame(width: 150, height: containerHeight)
                            .background(Color.teal.opacity(0.1))
                            .animation(.easeInOut, value: containerHeight)
                            
                            Slider(value: $containerHeight, in: 100...300) {
                                Text("Height")
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Practical use case - responsive grid
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Practical Example: Responsive Grid")
                            .font(.headline)
                        
                        SingleAxisGeometryReader(axis: .horizontal) { width in
                            let columns = max(1, Int(width / 80))
                            let itemWidth = (width - CGFloat(columns - 1) * 10) / CGFloat(columns)
                            
                            return VStack(alignment: .leading, spacing: 5) {
                                Text("Columns: \(columns), Item Width: \(itemWidth, specifier: "%.0f")px")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: 10), count: columns), spacing: 10) {
                                    ForEach(0..<12, id: \.self) { index in
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.cyan.opacity(0.3))
                                            .frame(height: 60)
                                            .overlay {
                                                Text("\(index + 1)")
                                                    .font(.headline)
                                            }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.cyan.opacity(0.05))
                    }
                }
                .padding()
            }
        }
    }
    
    return SingleAxisShowcase()
}
#endif
