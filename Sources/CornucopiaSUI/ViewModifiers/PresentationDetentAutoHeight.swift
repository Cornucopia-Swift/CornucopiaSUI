//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// Measures the content's height and uses it as `presentationDetents`
struct PresentationDetentAutoHeight: ViewModifier {
    @State private var height: CGFloat? = nil
    @State private var isInitialized = false
    
    // Threshold to avoid micro-adjustments
    private let heightChangeThreshold: CGFloat = 5.0
    
    func body(content: Content) -> some View {
        if #available(macOS 13.3, iOS 16.4, *) {
            content
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newHeight in
                    // Only update if significantly different or first measurement
                    if !isInitialized {
                        height = newHeight
                        isInitialized = true
                    } else if let currentHeight = height,
                              abs(newHeight - currentHeight) > heightChangeThreshold {
                        height = newHeight
                    }
                }
                .presentationDetents(
                    height != nil ? [.height(height!)] : []
                )
                .presentationBackgroundInteraction(.enabled)
        } else {
            content
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newHeight in
                    if !isInitialized {
                        height = newHeight
                        isInitialized = true
                    } else if let currentHeight = height,
                              abs(newHeight - currentHeight) > heightChangeThreshold {
                        height = newHeight
                    }
                }
                .presentationDetents(
                    height != nil ? [.height(height!)] : []
                )
        }
    }
}

public extension View {
    func CC_presentationDetentAutoHeight() -> some View {
        self.modifier(PresentationDetentAutoHeight())
    }
}

#Preview("Simple Text") {
    struct SimpleTextDemo: View {
        @State private var showSheet = true

        var body: some View {
            Button("Show Sheet") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                VStack(spacing: 16) {
                    Text("Auto-sized Sheet")
                        .font(.headline)
                    Text("This sheet automatically sizes to fit its content.")
                        .multilineTextAlignment(.center)
                }
                .padding()
                .CC_presentationDetentAutoHeight()
            }
        }
    }
    return SimpleTextDemo()
}

#Preview("Variable Content") {
    struct VariableContentDemo: View {
        @State private var showSheet = true
        @State private var isExpanded = false

        var body: some View {
            Button("Show Sheet") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Expandable Content")
                        .font(.headline)

                    DisclosureGroup("Show Details", isExpanded: $isExpanded) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detail line 1")
                            Text("Detail line 2")
                            Text("Detail line 3")
                            Text("Detail line 4")
                        }
                        .padding(.top, 8)
                    }

                    Text("The sheet height adjusts when content expands.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .CC_presentationDetentAutoHeight()
            }
        }
    }
    return VariableContentDemo()
}

#Preview("List Content") {
    struct ListContentDemo: View {
        @State private var showSheet = true

        var body: some View {
            Button("Show Sheet") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                VStack(spacing: 0) {
                    Text("Select an Option")
                        .font(.headline)
                        .padding()

                    List {
                        ForEach(1...5, id: \.self) { index in
                            Text("Option \(index)")
                        }
                    }
                    .frame(height: 200)
                }
                .CC_presentationDetentAutoHeight()
            }
        }
    }
    return ListContentDemo()
}

#Preview("Form Content") {
    struct FormContentDemo: View {
        @State private var showSheet = true
        @State private var name = ""
        @State private var email = ""
        @State private var subscribe = false

        var body: some View {
            Button("Show Sheet") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                NavigationStack {
                    Form {
                        Section("Details") {
                            TextField("Name", text: $name)
                            TextField("Email", text: $email)
                        }

                        Section {
                            Toggle("Subscribe to newsletter", isOn: $subscribe)
                        }
                    }
                    .navigationTitle("Sign Up")
                    #if os(iOS) || os(tvOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                }
                .CC_presentationDetentAutoHeight()
            }
        }
    }
    return FormContentDemo()
}

#Preview("Image and Text") {
    struct ImageTextDemo: View {
        @State private var showSheet = true

        var body: some View {
            Button("Show Sheet") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)

                    Text("Success!")
                        .font(.title2)
                        .bold()

                    Text("Your action was completed successfully.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    Button("Done") {
                        showSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .CC_presentationDetentAutoHeight()
            }
        }
    }
    return ImageTextDemo()
}

#Preview("Dynamic Size Change") {
    struct DynamicSizeDemo: View {
        @State private var showSheet = true
        @State private var itemCount = 3

        var body: some View {
            Button("Show Sheet") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                VStack(spacing: 16) {
                    Text("Dynamic Content")
                        .font(.headline)

                    ForEach(1...itemCount, id: \.self) { index in
                        Text("Item \(index)")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue.opacity(0.1))
                            .cornerRadius(8)
                    }

                    HStack {
                        Button("Remove") {
                            if itemCount > 1 {
                                withAnimation {
                                    itemCount -= 1
                                }
                            }
                        }
                        .disabled(itemCount <= 1)

                        Button("Add") {
                            if itemCount < 6 {
                                withAnimation {
                                    itemCount += 1
                                }
                            }
                        }
                        .disabled(itemCount >= 6)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .CC_presentationDetentAutoHeight()
            }
        }
    }
    return DynamicSizeDemo()
}

#Preview("iPad Compatibility") {
    struct iPadCompatibilityDemo: View {
        @State private var showSheet = true

        var body: some View {
            Button("Show Sheet") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                VStack(spacing: 20) {
                    Text("Cross-platform Sheet")
                        .font(.headline)

                    Text("This auto-height presentation works on both iPhone and iPad.")
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Image(systemName: "iphone")
                        Image(systemName: "ipad")
                    }
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                }
                .padding()
                .CC_presentationDetentAutoHeight()
            }
        }
    }
    return iPadCompatibilityDemo()
}
