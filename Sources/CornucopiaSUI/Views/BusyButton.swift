//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// A basic button that shows a 'busy' behavior when triggered.
public struct BusyButton: View {

    public typealias ActionFunc = () async throws -> ()

    @Binding var isBusy: Bool
    @State private var title: String
    @State private var action: ActionFunc

    public var body: some View {

        ZStack {

            if self.isBusy {
                button
                    .clipShape(Circle())
            } else {
                button
            }

            ProgressView()
                .opacity(isBusy ? 1 : 0)
                .saturation(-1)
        }
        .animation(.easeInOut, value: isBusy)
    }

    public var button: some View {
        Button(action: {
            withAnimation {
                self.isBusy = true
            }
            Task {
                defer { DispatchQueue.main.async { self.isBusy = false} }
                try await self.action()
            }
        }) {
            Text(title)
                .opacity(isBusy ? 0 : 1)
        }
        .disabled(isBusy)
    }

    public init(isBusy: Binding<Bool>, title: String, action: @escaping ActionFunc) {
        self._isBusy = isBusy
        self.title = title
        self.action = action
    }
}

//MARK: - Example
#if DEBUG
#Preview("BusyButton - Various Styles") {
    struct BusyButtonShowcase: View {
        @State private var isBusyDefault = false
        @State private var isBusyBordered = false
        @State private var isBusyProminent = false
        @State private var isBusyCustom = false
        @State private var isBusyError = false
        @State private var errorMessage = ""
        
        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    Text("BusyButton Showcase")
                        .font(.largeTitle)
                        .padding(.bottom)
                    
                    // Default style
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Default Button Style")
                            .font(.headline)
                        BusyButton(isBusy: $isBusyDefault, title: "Process Data") {
                            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                        }
                    }
                    
                    // Bordered style
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bordered Style")
                            .font(.headline)
                        BusyButton(isBusy: $isBusyBordered, title: "Upload File") {
                            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 3)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    
                    // Bordered Prominent
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bordered Prominent Style")
                            .font(.headline)
                        BusyButton(isBusy: $isBusyProminent, title: "Download") {
                            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    // Custom tint color
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Custom Tint Color")
                            .font(.headline)
                        HStack(spacing: 15) {
                            BusyButton(isBusy: $isBusyCustom, title: "Red Action") {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                            }
                            .tint(.red)
                            .buttonStyle(.bordered)
                            
                            BusyButton(isBusy: $isBusyCustom, title: "Green Action") {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                            }
                            .tint(.green)
                            .buttonStyle(.bordered)
                            
                            BusyButton(isBusy: $isBusyCustom, title: "Purple Action") {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                            }
                            .tint(.purple)
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    // Error handling example
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Error Handling")
                            .font(.headline)
                        BusyButton(isBusy: $isBusyError, title: "Try Operation") {
                            errorMessage = ""
                            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                            // Simulate random error
                            if Bool.random() {
                                throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Random error occurred"])
                            }
                            errorMessage = "Success!"
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(errorMessage == "Success!" ? .green : .red)
                        }
                    }
                    
                    // Different control sizes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Control Sizes")
                            .font(.headline)
                        HStack(spacing: 15) {
                            BusyButton(isBusy: .constant(false), title: "Mini") {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                            }
                            .controlSize(.mini)
                            .buttonStyle(.bordered)
                            
                            BusyButton(isBusy: .constant(false), title: "Small") {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                            }
                            .controlSize(.small)
                            .buttonStyle(.bordered)
                            
                            BusyButton(isBusy: .constant(false), title: "Regular") {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                            }
                            .controlSize(.regular)
                            .buttonStyle(.bordered)
                            
                            BusyButton(isBusy: .constant(false), title: "Large") {
                                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
                            }
                            .controlSize(.large)
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    return BusyButtonShowcase()
}
#endif
