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
    let options: BusyButtonOptions
    let action: ActionFunc
    let label: () -> Label

    @State private var task: Task<Void, Never>?

    public var body: some View {
        Button {
            guard !isBusy else { return }
            showConfirmation = true
        } label: {
            label()
                .opacity(isBusy ? 0 : 1)
                .accessibilityHidden(isBusy)
                .overlay {
                    if isBusy {
                        BusyIndicator(style: options.indicatorStyle)
                            .accessibilityLabel("Busy")
                    }
                }
        }
        .disabled(isBusy)
        .animation(options.animation, value: isBusy)
        .clipShape(options.shrinkToCircle && isBusy ? AnyShape(Circle()) : AnyShape(Rectangle()))
        .accessibilityValue(isBusy ? Text("Busy") : Text(""))
        .onDisappear {
            guard options.cancelTaskOnDisappear else { return }
            task?.cancel()
            task = nil
            if isBusy {
                withAnimation(options.animation) {
                    isBusy = false
                }
            }
        }
#if os(iOS)
        .CC_confirmationDialog(
            confirmationTitle,
            isPresented: $showConfirmation,
            actions: [
                ConfirmationDialogAction(confirmButtonTitle, role: confirmButtonRole) {
                    runConfirmedAction()
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
                runConfirmedAction()
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
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        onError: ((Error) -> Void)? = nil,
        action: @escaping ActionFunc,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self._isBusy = isBusy
        self.confirmationTitle = confirmationTitle
        self.confirmationMessage = confirmationMessage
        self.confirmButtonTitle = confirmButtonTitle
        self.confirmButtonRole = confirmButtonRole
        self.options = BusyButtonOptions(
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            onError: onError
        )
        self.action = action
        self.label = label
    }

    public init(
        isBusy: Binding<Bool>,
        confirmationTitle: String,
        confirmationMessage: String,
        confirmButtonTitle: String,
        confirmButtonRole: ButtonRole? = nil,
        options: BusyButtonOptions,
        action: @escaping ActionFunc,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self._isBusy = isBusy
        self.confirmationTitle = confirmationTitle
        self.confirmationMessage = confirmationMessage
        self.confirmButtonTitle = confirmButtonTitle
        self.confirmButtonRole = confirmButtonRole
        self.options = options
        self.action = action
        self.label = label
    }

    private func runConfirmedAction() {
        guard !isBusy, task == nil else { return }
        withAnimation(options.animation) {
            isBusy = true
        }

        task = Task {
            do {
                try await action()
            } catch is CancellationError {
            } catch {
                await MainActor.run {
                    options.onError?(error)
                }
            }

            await MainActor.run {
                withAnimation(options.animation) {
                    isBusy = false
                }
                task = nil
            }
        }
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
        shrinkToCircle: Bool = false,
        indicatorStyle: BusyIndicatorStyle = .modern,
        onError: ((Error) -> Void)? = nil,
        action: @escaping ActionFunc
    ) {
        self.init(
            isBusy: isBusy,
            confirmationTitle: confirmationTitle,
            confirmationMessage: confirmationMessage,
            confirmButtonTitle: confirmButtonTitle,
            confirmButtonRole: confirmButtonRole,
            shrinkToCircle: shrinkToCircle,
            indicatorStyle: indicatorStyle,
            onError: onError,
            action: action
        ) {
            Text(title)
        }
    }

    init(
        _ title: String,
        isBusy: Binding<Bool>,
        confirmationTitle: String,
        confirmationMessage: String,
        confirmButtonTitle: String,
        confirmButtonRole: ButtonRole? = nil,
        options: BusyButtonOptions,
        action: @escaping ActionFunc
    ) {
        self.init(
            isBusy: isBusy,
            confirmationTitle: confirmationTitle,
            confirmationMessage: confirmationMessage,
            confirmButtonTitle: confirmButtonTitle,
            confirmButtonRole: confirmButtonRole,
            options: options,
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
