//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
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
            .sheet(isPresented: $isPresented) {
                ConfirmationDialogView(
                    title: titleVisibility == .visible ? title : "",
                    message: message,
                    actions: actions,
                    actionsContent: actionsContent,
                    isPresented: $isPresented
                )
                .CC_presentationDetentAutoHeight()
                .presentationDragIndicator(.hidden)
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
        _ = Mirror(reflecting: view)

        func processView(_ view: Any) {
            if let dialogButton = view as? CC_ConfirmationDialogButton {
                actions.append(ConfirmationDialogAction(dialogButton.title, role: dialogButton.role, action: dialogButton.action))
            } else {
                let viewMirror = Mirror(reflecting: view)
                for child in viewMirror.children {
                    processView(child.value)
                }
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
                for textChild in textMirror.children {
                    if textChild.label == "storage" {
                        let storageMirror = Mirror(reflecting: textChild.value)
                        if let firstChild = storageMirror.children.first,
                           let verbatimText = firstChild.value as? String {
                            return verbatimText
                        }
                    }
                }
            }
        }
        return nil
    }
}
