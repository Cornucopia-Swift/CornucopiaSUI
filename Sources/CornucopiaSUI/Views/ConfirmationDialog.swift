//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

public struct ConfirmationDialogAction {
    let title: String
    let role: ButtonRole?
    let action: () -> Void

    public init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }
}

struct ConfirmationDialogView: View {
    let title: String
    let message: String?
    let actions: [ConfirmationDialogAction]
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            actionSection
            cancelSeparator
            cancelSection
        }
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            if let message = message {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, title.isEmpty && message == nil ? 16 : 20)
    }

    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                actionButton(for: action)

                if index < actions.count - 1 {
                    Divider()
                        .background(separatorColor)
                }
            }
        }
        .background(backgroundColor)
    }

    @ViewBuilder
    private func actionButton(for action: ConfirmationDialogAction) -> some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action.action()
            }
        } label: {
            Text(action.title)
                .font(.body)
                .fontWeight(action.role == .destructive ? .medium : .regular)
                .foregroundStyle(buttonTextColor(for: action.role))
                .lineLimit(2)
                .frame(minHeight: 56)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var cancelSeparator: some View {
        if colorScheme == .dark {
            // Dark mode: simple divider like other buttons
            Divider()
                .background(separatorColor)
        } else {
            // Light mode: gradient separator
            Rectangle()
                .fill(separatorColor)
                .frame(height: 8)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.1),
                            Color.clear,
                            Color.black.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    @ViewBuilder
    private var cancelSection: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(secondaryBackgroundColor)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }


    private func buttonTextColor(for role: ButtonRole?) -> Color {
        switch role {
        case .destructive:
            return Color.red
        case .cancel:
            return Color.accentColor
        default:
            return Color.accentColor
        }
    }

    private var backgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    private var secondaryBackgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    private var separatorColor: Color {
        #if os(iOS)
        return Color(UIColor.separator)
        #else
        return Color(NSColor.separatorColor)
        #endif
    }

}

struct ProfessionalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                backgroundColor
                    .opacity(configuration.isPressed ? 0.5 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var backgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
}

#Preview("Custom Confirmation Dialog") {
    struct ConfirmationDialogDemo: View {
        @State private var showSimpleDialog = false
        @State private var showComplexDialog = false
        @State private var lastAction = ""

        var body: some View {
            VStack(spacing: 30) {
                Text("Professional Confirmation Dialog")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 20) {
                    Button("Delete All Data") {
                        showSimpleDialog = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Export Options") {
                        showComplexDialog = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                if !lastAction.isEmpty {
                    Text("✓ \(lastAction)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .CC_confirmationDialog(
                "Clear Garage",
                isPresented: $showSimpleDialog,
                actions: [
                    ConfirmationDialogAction("Yes, Clear All", role: .destructive) {
                        lastAction = "Cleared garage"
                    }
                ],
                message: "This will permanently delete all vehicles and their scan data from your garage. This action cannot be undone."
            )
            .CC_confirmationDialog(
                "Export Data",
                isPresented: $showComplexDialog,
                actions: [
                    ConfirmationDialogAction("Export as CSV") {
                        lastAction = "Exported as CSV"
                    },
                    ConfirmationDialogAction("Export as JSON") {
                        lastAction = "Exported as JSON"
                    },
                    ConfirmationDialogAction("Export as PDF") {
                        lastAction = "Exported as PDF"
                    },
                    ConfirmationDialogAction("Delete Instead", role: .destructive) {
                        lastAction = "Data deleted"
                    }
                ],
                message: "Choose your preferred export format:"
            )
        }
    }

    return ConfirmationDialogDemo()
}
