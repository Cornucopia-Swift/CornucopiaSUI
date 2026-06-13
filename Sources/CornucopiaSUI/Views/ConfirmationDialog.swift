//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI
#if os(iOS) || os(tvOS)
import UIKit
#endif

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

#if os(iOS)
struct ConfirmationDialogView: View {
    let title: String
    let message: String?
    let messageContent: AnyView?
    let background: ConfirmationDialogBackground
    let actions: [ConfirmationDialogAction]
    // If provided and `actions` is empty, render raw content instead of synthesized buttons
    let actionsContent: AnyView?
    @Binding var isPresented: Bool
    var dismissAction: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isInputFocused: Bool

    private var bottomSafeArea: CGFloat {
        #if os(iOS) || os(tvOS)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom ?? 0
        #else
        return 0
        #endif
    }

    private var bottomPadding: CGFloat {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 30 : 0
        #else
        return 0
        #endif
    }

    var body: some View {
        dialogCard
            .padding(.top, 30)
            .padding(.horizontal, 20)
            .padding(.bottom, bottomPadding + 12)
            .background(
                sheetBackground
                    .ignoresSafeArea()
            )
    }

    private var dialogCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                headerSection
                actionSection
            }

            cancelSeparator
            cancelSection
        }
        .frame(maxWidth: dialogMaxWidth)
        .confirmationDialogSurface(background, tint: .accentColor, colorScheme: colorScheme)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.46 : 0.18), radius: 28, y: 12)
        .shadow(color: Color.accentColor.opacity(colorScheme == .dark ? 0.12 : 0.08), radius: 24, y: 4)
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
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.86)
            }

            if let messageContent {
                messageContent
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else if let message = message {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: 0) {
            // First show input content if provided (e.g., TextField)
            if let actionsContent {
                VStack(spacing: 12) {
                    actionsContent
                        .focused($isInputFocused)
                        .textFieldStyle(RecessedTextFieldStyle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(inputFieldBackground)
                .padding(.horizontal, 16)
                .padding(.bottom, actions.isEmpty ? 12 : 8)
            }

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
        .padding(.bottom, 0)
    }

    private func dismiss() {
        if let dismissAction {
            dismissAction()
        } else {
            isPresented = false
        }
    }

    @ViewBuilder
    private func actionButton(for action: ConfirmationDialogAction) -> some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                action.action()
            }
        } label: {
            Text(action.title)
                .font(.body)
                .fontWeight(action.role == .destructive ? .semibold : .regular)
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
        if background.style != .plain {
            Rectangle()
                .fill(Color.clear)
                .frame(height: 8)
                .background(separatorBand)
        } else {
            Divider()
                .background(separatorColor)
        }
    }

    @ViewBuilder
    private var cancelSection: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
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
        #elseif os(tvOS)
        return colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    private var separatorColor: Color {
        #if os(iOS)
        return Color(UIColor.separator)
        #elseif os(tvOS)
        return colorScheme == .dark ? Color(white: 0.3) : Color(white: 0.8)
        #else
        return Color(NSColor.separatorColor)
        #endif
    }

    private var dialogMaxWidth: CGFloat {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 520 : .infinity
        #else
        return .infinity
        #endif
    }

    @ViewBuilder
    private var sheetBackground: some View {
        Color.clear
    }

    private var separatorBand: some View {
        ZStack {
            separatorColor.opacity(colorScheme == .dark ? 0.9 : 0.45)
            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.32 : 0.10),
                    Color.clear,
                    Color.white.opacity(colorScheme == .dark ? 0.02 : 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var inputFieldBackground: some View {
        let baseSurface = colorScheme == .dark ? Color(white: 0.14) : Color.white
        let highlight = Color.white.opacity(colorScheme == .dark ? 0.08 : 0.55)
        let contourShadow = Color.black.opacity(colorScheme == .dark ? 0.55 : 0.12)

        return RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        baseSurface.opacity(colorScheme == .dark ? 0.85 : 0.96),
                        baseSurface.opacity(colorScheme == .dark ? 0.6 : 0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                highlight,
                                contourShadow.opacity(colorScheme == .dark ? 0.7 : 0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.overlay)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.accentColor.opacity(isInputFocused ? (colorScheme == .dark ? 0.55 : 0.28) : 0), lineWidth: isInputFocused ? 1.6 : 0)
            )
            .shadow(color: contourShadow.opacity(colorScheme == .dark ? 0.9 : 0.6), radius: 20, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.03 : 0.18), lineWidth: 0.8)
                    .blendMode(.screen)
                    .opacity(0.8)
            )
            .animation(.easeInOut(duration: 0.18), value: isInputFocused)
    }

}

private extension View {
    @ViewBuilder
    func confirmationDialogSurface(
        _ background: ConfirmationDialogBackground,
        tint: Color,
        colorScheme: ColorScheme
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        switch background.surfaceStyle.resolved {
            case .glass:
                if #available(iOS 26.0, *) {
                    self
                        .background {
                            shape
                                .fill(tint.opacity(colorScheme == .dark ? 0.08 : 0.05))
                        }
                        .glassEffect(.regular.tint(tint.opacity(0.06)), in: shape)
                        .clipShape(shape)
                } else {
                    materialConfirmationDialogSurface(background, tint: tint, colorScheme: colorScheme)
                }
            case .standard, .default:
                self
                    .background {
                        shape
                            .fill(Self.confirmationDialogBaseColor(background))
                            .overlay {
                                shape.fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.20),
                                            Color.clear,
                                            tint.opacity(colorScheme == .dark ? 0.05 : 0.03)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            }
                            .overlay {
                                shape.strokeBorder(Self.confirmationDialogBorder(colorScheme: colorScheme), lineWidth: 0.7)
                            }
                    }
                    .clipShape(shape)
        }
    }

    private func materialConfirmationDialogSurface(
        _ background: ConfirmationDialogBackground,
        tint: Color,
        colorScheme: ColorScheme
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        return self
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay {
                        shape.fill(tint.opacity(colorScheme == .dark ? 0.09 : 0.06))
                    }
                    .overlay {
                        shape.strokeBorder(Self.confirmationDialogBorder(colorScheme: colorScheme), lineWidth: 0.7)
                    }
            }
            .clipShape(shape)
    }

    private static func confirmationDialogBaseColor(_ background: ConfirmationDialogBackground) -> Color {
        if let cardBackgroundColor = background.cardBackgroundColor {
            return cardBackgroundColor
        }

        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #else
        return Color.secondary.opacity(0.18)
        #endif
    }

    private static func confirmationDialogBorder(colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.16 : 0.55),
                Color.black.opacity(colorScheme == .dark ? 0.26 : 0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct RecessedTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme

    func _body(configuration: TextField<Self._Label>) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

        return configuration
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                shape
                    .fill(fieldFill)
                    .shadow(color: highlightShadow, radius: 1.2, x: -1, y: -1)
                    .shadow(color: dropShadow, radius: 2.0, x: 1.4, y: 1.6)
            )
            .overlay(shape.strokeBorder(fieldStroke, lineWidth: 0.9))
            .overlay(
                shape
                    .stroke(Color.accentColor.opacity(colorScheme == .dark ? 0.25 : 0.18), lineWidth: 0.6)
                    .blendMode(.overlay)
            )
    }

    private var fieldFill: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.95),
                Color.black.opacity(colorScheme == .dark ? 0.45 : 0.08)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var fieldStroke: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.4),
                Color.black.opacity(colorScheme == .dark ? 0.55 : 0.12)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var highlightShadow: Color {
        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.6)
    }

    private var dropShadow: Color {
        Color.black.opacity(colorScheme == .dark ? 0.6 : 0.12)
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
                    .textInputAutocapitalization(.words)
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
                        .onChange(of: liveEditText) { _, newValue in
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

#Preview("Confirmation Dialog Backgrounds") {
    struct ConfirmationDialogBackgroundDemo: View {
        @State private var showDefaultBackground = false
        @State private var showNeutralBackground = false
        @State private var showTransparentBackground = false

        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [Color.orange.opacity(0.2), Color.teal.opacity(0.2), Color.indigo.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Background Variants")
                        .font(.title3.weight(.semibold))

                    Button("Default Background") {
                        showDefaultBackground = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Neutral Background") {
                        showNeutralBackground = true
                    }
                    .buttonStyle(.bordered)

                    Button("Transparent / None") {
                        showTransparentBackground = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(24)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .CC_confirmationDialog(
                "Default",
                isPresented: $showDefaultBackground,
                actions: [
                    ConfirmationDialogAction("Proceed") {}
                ],
                message: "Uses the default CornucopiaSUI dialog background."
            )
            .CC_confirmationDialog(
                "Neutral Surface",
                isPresented: $showNeutralBackground,
                background: .init(
                    sheetBackgroundColor: .clear,
                    cardBackgroundColor: Color(UIColor.systemBackground),
                    style: .plain
                ),
                actions: [
                    ConfirmationDialogAction("Proceed") {}
                ],
                message: "Uses a neutral card to avoid accent-tinted backgrounds."
            )
            .CC_confirmationDialog(
                "Transparent",
                isPresented: $showTransparentBackground,
                background: .clear,
                actions: [
                    ConfirmationDialogAction("Proceed") {}
                ],
                message: "No backdrop and no dialog surface background."
            )
        }
    }

    return ConfirmationDialogBackgroundDemo()
}
#endif
