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
    // If provided and `actions` is empty, render raw content instead of synthesized buttons
    let actionsContent: AnyView?
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            actionSection
            cancelSeparator
            cancelSection
        }
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .onAppear {
            if actionsContent != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputFocused = true
                }
            }
        }
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
            // First show input content if provided (e.g., TextField)
            if let actionsContent {
                VStack(spacing: 12) {
                    actionsContent
                        .focused($isInputFocused)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                if !actions.isEmpty {
                    Divider()
                        .background(separatorColor)
                }
            }

            // Then show action buttons
            if !actions.isEmpty {
                ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                    actionButton(for: action)

                    if index < actions.count - 1 {
                        Divider()
                            .background(separatorColor)
                    }
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
        @State private var showTextFieldDialog = false
        @State private var showLiveEditDialog = false
        @State private var lastAction = ""
        @State private var textFieldValue = ""
        @State private var liveEditText = ""
        @State private var characterCount = 0
        @State private var isValidInput = false

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

                    Button("Rename Item") {
                        textFieldValue = "Current Name"
                        showTextFieldDialog = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button("Live Edit Demo") {
                        textFieldValue = ""
                        showLiveEditDialog = true
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
            .CC_confirmationDialog(
                "Rename Item",
                isPresented: $showTextFieldDialog,
                actions: [
                    ConfirmationDialogAction("Rename") {
                        lastAction = "Renamed to: \(textFieldValue)"
                    },
                    ConfirmationDialogAction("Delete", role: .destructive) {
                        lastAction = "Item deleted"
                    }
                ],
                message: "Enter a new name for this item:"
            ) {
                TextField("Enter name", text: $textFieldValue)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 20)
            }
            // Demo: "On-the-fly" editing using SwiftUI bindings
            // The TextField's binding automatically updates parent state,
            // allowing real-time validation, character counting, and dynamic UI updates
            .CC_confirmationDialog(
                "Live Edit Demo",
                isPresented: $showLiveEditDialog,
                actions: [
                    ConfirmationDialogAction("Save", role: isValidInput ? nil : .cancel) {
                        lastAction = "Saved: '\(liveEditText)' (\(characterCount) chars)"
                    }
                ],
                message: "Watch the character count and validation update as you type:"
            ) {
                VStack(spacing: 12) {
                    TextField("Type something...", text: $liveEditText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: liveEditText) { newValue in
                            characterCount = newValue.count
                            isValidInput = newValue.count >= 3 && !newValue.trimmingCharacters(in: .whitespaces).isEmpty
                        }

                    HStack {
                        Text("Characters: \(characterCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        if characterCount > 0 {
                            Text(isValidInput ? "✓ Valid" : "⚠️ Min 3 chars")
                                .font(.caption)
                                .foregroundColor(isValidInput ? .green : .orange)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    return ConfirmationDialogDemo()
}
