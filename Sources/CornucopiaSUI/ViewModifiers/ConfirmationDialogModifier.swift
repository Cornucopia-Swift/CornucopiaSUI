//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if os(iOS)
import SwiftUI

public struct CC_ConfirmationDialogButton: View {
    let title: String
    let role: ButtonRole?
    let action: () -> Void

    public init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }

    public var body: some View {
        EmptyView()
    }
}

struct ConfirmationDialogModifier: ViewModifier {
    let title: String
    let titleVisibility: Visibility
    @Binding var isPresented: Bool
    let message: String?
    let actions: [ConfirmationDialogAction]
    let actionsContent: AnyView?

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                ConfirmationDialogContainer(
                    title: titleVisibility == .visible ? title : "",
                    message: message,
                    actions: actions,
                    actionsContent: actionsContent,
                    isPresented: $isPresented
                )
                .presentationBackground(.clear)
            }
            .transaction { $0.disablesAnimations = true }
    }
}

private struct ConfirmationDialogContainer: View {
    let title: String
    let message: String?
    let actions: [ConfirmationDialogAction]
    let actionsContent: AnyView?
    @Binding var isPresented: Bool

    @State private var showContent = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(showContent ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            if showContent {
                ConfirmationDialogView(
                    title: title,
                    message: message,
                    actions: actions,
                    actionsContent: actionsContent,
                    isPresented: $isPresented,
                    dismissAction: dismissWithAnimation
                )
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showContent)
        .onAppear {
            showContent = true
        }
    }

    private func dismissWithAnimation() {
        showContent = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

public extension View {
    func CC_confirmationDialog(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        actions: [ConfirmationDialogAction],
        message: String? = nil
    ) -> some View {
        modifier(
            ConfirmationDialogModifier(
                title: title,
                titleVisibility: titleVisibility == .automatic ? .visible : titleVisibility,
                isPresented: isPresented,
                message: message,
                actions: actions,
                actionsContent: nil
            )
        )
    }

    func CC_confirmationDialog<I: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        actions: [ConfirmationDialogAction],
        message: String? = nil,
        @ViewBuilder inputContent: () -> I
    ) -> some View {
        modifier(
            ConfirmationDialogModifier(
                title: title,
                titleVisibility: titleVisibility == .automatic ? .visible : titleVisibility,
                isPresented: isPresented,
                message: message,
                actions: actions,
                actionsContent: AnyView(inputContent())
            )
        )
    }

    func CC_confirmationDialog<A: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        @ViewBuilder actions: () -> A
    ) -> some View {
        let providedActionsView = actions()
        let extractedActions = Self.extractActions(from: providedActionsView)
        return modifier(
            ConfirmationDialogModifier(
                title: title,
                titleVisibility: titleVisibility == .automatic ? .visible : titleVisibility,
                isPresented: isPresented,
                message: nil,
                actions: extractedActions,
                actionsContent: extractedActions.isEmpty ? AnyView(providedActionsView) : nil
            )
        )
    }

    func CC_confirmationDialog<A: View, M: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        @ViewBuilder actions: () -> A,
        @ViewBuilder message: () -> M
    ) -> some View {
        let providedActionsView = actions()
        let extractedActions = Self.extractActions(from: providedActionsView)
        let messageText = Self.extractText(from: message())
        return modifier(
            ConfirmationDialogModifier(
                title: title,
                titleVisibility: titleVisibility == .automatic ? .visible : titleVisibility,
                isPresented: isPresented,
                message: messageText,
                actions: extractedActions,
                actionsContent: extractedActions.isEmpty ? AnyView(providedActionsView) : nil
            )
        )
    }

    private static func extractActions<A: View>(from view: A) -> [ConfirmationDialogAction] {
        var actions: [ConfirmationDialogAction] = []

        func processView(_ value: Any) {
            if let dialogButton = value as? CC_ConfirmationDialogButton {
                actions.append(
                    ConfirmationDialogAction(
                        dialogButton.title,
                        role: dialogButton.role,
                        action: dialogButton.action
                    )
                )
                return
            }

            for child in Mirror(reflecting: value).children {
                processView(child.value)
            }
        }

        processView(view)
        return actions
    }

    private static func extractText<V: View>(from view: V) -> String? {
        let mirror = Mirror(reflecting: view)

        for child in mirror.children {
            if let text = child.value as? Text {
                let textMirror = Mirror(reflecting: text)
                for textChild in textMirror.children where textChild.label == "storage" {
                    let storageMirror = Mirror(reflecting: textChild.value)
                    if let firstChild = storageMirror.children.first,
                       let verbatimText = firstChild.value as? String {
                        return verbatimText
                    }
                }
            }
        }

        return nil
    }
}
#endif
