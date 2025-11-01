//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// A busy button that shows a confirmation dialog before executing the action.
public struct ConfirmationBusyButton<Label: View>: View {

    public typealias ActionFunc = () async throws -> Void

    @Binding var isBusy: Bool
    @State private var showConfirmation = false

    let confirmationTitle: String
    let confirmationMessage: String
    let confirmButtonTitle: String
    let confirmButtonRole: ButtonRole?
    let indicatorStyle: BusyIndicatorStyle
    let action: ActionFunc
    let label: () -> Label

    public var body: some View {
        Button {
            showConfirmation = true
        } label: {
            ZStack {
                label()
                    .opacity(isBusy ? 0 : 1)

                if isBusy {
                    switch indicatorStyle {
                    case .classic:
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle())
                    case .modern:
                        ModernBusyIndicator()
                    case .pulse:
                        PulseBusyIndicator()
                    case .orbit:
                        OrbitBusyIndicator()
                    }
                }
            }
        }
        .disabled(isBusy)
        .animation(.easeInOut(duration: 0.3), value: isBusy)
#if os(iOS)
        .CC_confirmationDialog(
            confirmationTitle,
            isPresented: $showConfirmation,
            actions: [
                ConfirmationDialogAction(confirmButtonTitle, role: confirmButtonRole) {
                    withAnimation {
                        isBusy = true
                    }
                    Task {
                        defer {
                            DispatchQueue.main.async {
                                withAnimation {
                                    isBusy = false
                                }
                            }
                        }
                        try await action()
                    }
                }
            ],
            message: confirmationMessage
        )
#else
        .confirmationDialog(
            confirmationTitle,
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button(confirmButtonTitle, role: confirmButtonRole) {
                withAnimation {
                    isBusy = true
                }
                Task {
                    defer {
                        DispatchQueue.main.async {
                            withAnimation {
                                isBusy = false
                            }
                        }
                    }
                    try await action()
                }
            }
        } message: {
            Text(confirmationMessage)
        }
#endif
    }

    public init(
        isBusy: Binding<Bool>,
        confirmationTitle: String,
        confirmationMessage: String,
        confirmButtonTitle: String,
        confirmButtonRole: ButtonRole? = nil,
        indicatorStyle: BusyIndicatorStyle = .modern,
        action: @escaping ActionFunc,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self._isBusy = isBusy
        self.confirmationTitle = confirmationTitle
        self.confirmationMessage = confirmationMessage
        self.confirmButtonTitle = confirmButtonTitle
        self.confirmButtonRole = confirmButtonRole
        self.indicatorStyle = indicatorStyle
        self.action = action
        self.label = label
    }
}

/// Convenience initializer for text-only buttons
public extension ConfirmationBusyButton where Label == Text {
    init(
        _ title: String,
        isBusy: Binding<Bool>,
        confirmationTitle: String,
        confirmationMessage: String,
        confirmButtonTitle: String,
        confirmButtonRole: ButtonRole? = nil,
        indicatorStyle: BusyIndicatorStyle = .modern,
        action: @escaping ActionFunc
    ) {
        self.init(
            isBusy: isBusy,
            confirmationTitle: confirmationTitle,
            confirmationMessage: confirmationMessage,
            confirmButtonTitle: confirmButtonTitle,
            confirmButtonRole: confirmButtonRole,
            indicatorStyle: indicatorStyle,
            action: action
        ) {
            Text(title)
        }
    }
}

#if DEBUG
#Preview("ConfirmationBusyButton") {
    struct PreviewWrapper: View {
        @State private var isBusy = false

        var body: some View {
            VStack(spacing: 30) {
                Text("ConfirmationBusyButton Examples")
                    .font(.largeTitle)
                    .padding()

                ConfirmationBusyButton(
                    isBusy: $isBusy,
                    confirmationTitle: "Delete Item",
                    confirmationMessage: "Are you sure you want to delete this item? This action cannot be undone.",
                    confirmButtonTitle: "Delete",
                    confirmButtonRole: .destructive,
                    action: {
                        try await Task.sleep(nanoseconds: 2_000_000_000)
                    }
                ) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                ConfirmationBusyButton(
                    "Clear Data",
                    isBusy: $isBusy,
                    confirmationTitle: "Clear All Data",
                    confirmationMessage: "This will clear all stored data. Continue?",
                    confirmButtonTitle: "Clear",
                    confirmButtonRole: .destructive,
                    action: {
                        try await Task.sleep(nanoseconds: 2_000_000_000)
                    }
                )
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
#endif
