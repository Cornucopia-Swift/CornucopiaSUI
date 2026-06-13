//
//  SlideOverCardDemoView.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import SwiftUI

struct SlideOverCardDemoView: View {
    @State private var showWelcomeCard = false
    @State private var showPairingCard = false
    @State private var showBleedingPreviewCard = false
    @State private var showFullWidthCard = false
    @State private var showRequiredCard = false
    @State private var showActionStylesCard = false
    @State private var showTextFieldCard = false
    @State private var activeSetupStep: SetupStep?
    @State private var adapterName = ""
    @State private var lastEvent = "No card shown yet"
    @State private var didApplyInitialCard = false

    private let standardStyle = CC_SlideOverCardStyle(
        surfaceStyle: .standard,
        accentTint: .blue
    )

    private let setupFlowStyle = CC_SlideOverCardStyle(
        surfaceStyle: .glass,
        accentTint: .teal
    )

    private let bleedingPreviewStyle = CC_SlideOverCardStyle(
        surfaceStyle: .glass,
        allowsBackgroundBleeding: true,
        accentTint: .purple
    )

    private let fullWidthStyle = CC_SlideOverCardStyle(
        surfaceStyle: .standard,
        presentationLayout: .fullWidth,
        accentTint: .blue
    )

    var body: some View {
        DemoScroll {
            DemoPanel("Setup Cards", subtitle: "Bottom-mounted cards for onboarding, pairing and permission prompts.") {
                VStack(alignment: .leading, spacing: 12) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 10)], spacing: 10) {
                        Button {
                            showWelcomeCard = true
                            lastEvent = "Opened welcome"
                        } label: {
                            Label("Welcome", systemImage: "sparkles")
                        }
                        .buttonStyle(.borderedProminent)
                        .demoID("slideover.welcome")

                        Button {
                            activeSetupStep = .privacy
                            lastEvent = "Started setup flow"
                        } label: {
                            Label("Setup Flow", systemImage: "slider.horizontal.3")
                        }
                        .buttonStyle(.bordered)
                        .demoID("slideover.flow")

                        Button {
                            showPairingCard = true
                            lastEvent = "Opened pairing"
                        } label: {
                            Label("Pair Device", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .buttonStyle(.bordered)
                        .demoID("slideover.pair")

                        Button {
                            showBleedingPreviewCard = true
                            lastEvent = "Opened bleeding preview"
                        } label: {
                            Label("Glass", systemImage: "circle.lefthalf.filled")
                        }
                        .buttonStyle(.bordered)
                        .demoID("slideover.glass")

                        Button {
                            showFullWidthCard = true
                            lastEvent = "Opened full-width card"
                        } label: {
                            Label("Full Width", systemImage: "rectangle.compress.vertical")
                        }
                        .buttonStyle(.bordered)
                        .demoID("slideover.fullWidth")

                        Button {
                            showRequiredCard = true
                            lastEvent = "Opened required step"
                        } label: {
                            Label("Required", systemImage: "lock.shield")
                        }
                        .buttonStyle(.bordered)
                        .demoID("slideover.required")

                        Button {
                            showActionStylesCard = true
                            lastEvent = "Opened action styles"
                        } label: {
                            Label("Actions", systemImage: "square.stack.3d.up")
                        }
                        .buttonStyle(.bordered)
                        .demoID("slideover.actions")

                        Button {
                            showTextFieldCard = true
                            lastEvent = "Opened text-field setup"
                        } label: {
                            Label("Text Field", systemImage: "keyboard")
                        }
                        .buttonStyle(.bordered)
                        .demoID("slideover.textField")
                    }

                    DemoMetric(title: "Last Event", value: lastEvent)
                }
            }

            DemoPanel("Interaction Modes", subtitle: "The same modifier can allow casual dismissal or hold the user inside a required step.") {
                VStack(alignment: .leading, spacing: 10) {
                    DemoPill("Default card surface is opaque", color: .blue)
                    DemoPill("Background bleeding is opt-in", color: .purple)
                    DemoPill("Outer padding can be removed", color: .blue)
                    DemoPill("Drag down to dismiss", color: .blue)
                    DemoPill("Tap outside to dismiss", color: .teal)
                    DemoPill("Item binding animates between setup steps", color: .indigo)
                    DemoPill("Required cards can disable tap and drag dismissal", color: .orange)
                    DemoPill("Grabber and dismiss button can be hidden for a custom one", color: .indigo)
                    DemoPill("Text fields keep the card above the keyboard", color: .green)
                }
            }
        }
        .CC_slideOverCard(
            isPresented: $showWelcomeCard,
            style: standardStyle,
            onDismiss: {
                lastEvent = "Welcome dismissed"
            }
        ) {
            WelcomeCard {
                showWelcomeCard = false
                activeSetupStep = .privacy
                lastEvent = "Welcome continued"
            }
        }
        .CC_slideOverCard(
            item: $activeSetupStep,
            style: setupFlowStyle,
            onDismiss: {
                lastEvent = "Setup flow dismissed"
            }
        ) { step in
            SetupStepCard(
                step: step,
                backAction: {
                    activeSetupStep = step.previous
                    lastEvent = "Moved to \(step.previous?.shortTitle ?? "catalog")"
                },
                primaryAction: {
                    if let next = step.next {
                        activeSetupStep = next
                        lastEvent = "Moved to \(next.shortTitle)"
                    } else {
                        activeSetupStep = nil
                        lastEvent = "Setup completed"
                    }
                }
            )
        }
        .CC_slideOverCard(
            isPresented: $showPairingCard,
            style: CC_SlideOverCardStyle(accentTint: .green),
            options: [.disableTapToDismiss],
            onDismiss: {
                lastEvent = "Pairing dismissed"
            }
        ) {
            PairingCard {
                showPairingCard = false
                lastEvent = "Device paired"
            }
        }
        .CC_slideOverCard(
            isPresented: $showBleedingPreviewCard,
            style: bleedingPreviewStyle,
            onDismiss: {
                lastEvent = "Bleeding preview dismissed"
            }
        ) {
            BleedingPreviewCard {
                showBleedingPreviewCard = false
                lastEvent = "Bleeding preview closed"
            }
        }
        .CC_slideOverCard(
            isPresented: $showFullWidthCard,
            style: fullWidthStyle,
            onDismiss: {
                lastEvent = "Full-width card dismissed"
            }
        ) {
            FullWidthPreviewCard {
                showFullWidthCard = false
                lastEvent = "Full-width card closed"
            }
        }
        .CC_slideOverCard(
            isPresented: $showRequiredCard,
            style: CC_SlideOverCardStyle(surfaceStyle: .standard, accentTint: .orange),
            options: [.disableDragToDismiss, .disableTapToDismiss],
            onDismiss: {
                lastEvent = "Required step dismissed"
            }
        ) {
            RequiredStepCard {
                showRequiredCard = false
                lastEvent = "Required step accepted"
            }
        }
        .CC_slideOverCard(
            isPresented: $showActionStylesCard,
            style: CC_SlideOverCardStyle(surfaceStyle: .standard, accentTint: .indigo),
            options: [.hideGrabber, .hideDismissButton],
            onDismiss: {
                lastEvent = "Action styles dismissed"
            }
        ) {
            ActionStylesCard(
                primaryAction: {
                    showActionStylesCard = false
                    lastEvent = "Primary action tapped"
                },
                secondaryAction: {
                    lastEvent = "Secondary action tapped"
                },
                closeAction: {
                    showActionStylesCard = false
                    lastEvent = "Action styles closed"
                }
            )
        }
        .CC_slideOverCard(
            isPresented: $showTextFieldCard,
            style: CC_SlideOverCardStyle(surfaceStyle: .standard, accentTint: .green),
            options: [.disableTapToDismiss],
            onDismiss: {
                lastEvent = "Text-field setup dismissed"
            }
        ) {
            TextFieldSetupCard(adapterName: $adapterName) {
                showTextFieldCard = false
                lastEvent = adapterName.isEmpty ? "Skipped adapter name" : "Saved \(adapterName)"
            }
        }
        .task {
            applyInitialDemoCardIfNeeded()
        }
    }

    private func applyInitialDemoCardIfNeeded() {
        guard !didApplyInitialCard else { return }
        didApplyInitialCard = true

        switch ProcessInfo.processInfo.environment["CORNUCOPIA_DEMO_SLIDEOVER_CARD"] {
            case "welcome":
                showWelcomeCard = true
                lastEvent = "Opened welcome from environment"
            case "flow":
                activeSetupStep = .privacy
                lastEvent = "Started setup flow from environment"
            case "pair":
                showPairingCard = true
                lastEvent = "Opened pairing from environment"
            case "glass":
                showBleedingPreviewCard = true
                lastEvent = "Opened bleeding preview from environment"
            case "fullWidth":
                showFullWidthCard = true
                lastEvent = "Opened full-width card from environment"
            case "required":
                showRequiredCard = true
                lastEvent = "Opened required step from environment"
            case "actions":
                showActionStylesCard = true
                lastEvent = "Opened action styles from environment"
            case "textField":
                showTextFieldCard = true
                lastEvent = "Opened text-field setup from environment"
            default:
                break
        }
    }
}

private struct WelcomeCard: View {
    let continueAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            SetupGlyph(systemName: "car.side.fill", color: .blue)

            VStack(spacing: 8) {
                Text("Cornucopia Setup")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("Connect adapters, verify permissions and keep diagnostic workflows ready before the first request.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                SetupFeatureRow(symbol: "checkmark.seal.fill", title: "Guided", subtitle: "One focused decision per card.")
                SetupFeatureRow(symbol: "ipad.and.iphone", title: "Adaptive", subtitle: "Compact on iPhone, centered on iPad.")
                SetupFeatureRow(symbol: "hand.draw.fill", title: "Interactive", subtitle: "Drag, tap outside or use explicit actions.")
            }

            Button(action: continueAction) {
                Label("Continue", systemImage: "arrow.right")
            }
            .buttonStyle(CC_SlideOverCardActionButtonStyle(.primary))
            .demoID("slideover.welcome.continue")
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SetupStepCard: View {
    let step: SetupStep
    let backAction: () -> Void
    let primaryAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            SetupGlyph(systemName: step.symbol, color: step.color)

            VStack(spacing: 8) {
                Text(step.title)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(step.message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ProgressView(value: step.progress)
                .tint(step.color)
                .accessibilityLabel("Setup progress")

            VStack(spacing: 10) {
                ForEach(step.details, id: \.self) { detail in
                    SetupFeatureRow(symbol: "checkmark.circle.fill", title: detail, subtitle: nil)
                }
            }

            if !step.secondaryDetails.isEmpty {
                VStack(spacing: 10) {
                    ForEach(step.secondaryDetails, id: \.self) { detail in
                        SetupFeatureRow(symbol: "info.circle.fill", title: detail.title, subtitle: detail.subtitle)
                    }
                }
            }

            VStack(spacing: 9) {
                Button(action: primaryAction) {
                    Label(step.primaryTitle, systemImage: step.next == nil ? "checkmark" : "arrow.right")
                }
                .buttonStyle(CC_SlideOverCardActionButtonStyle(.primary, tint: step.color))
                .demoID("slideover.step.primary")

                if step.previous != nil {
                    Button(action: backAction) {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .buttonStyle(CC_SlideOverCardActionButtonStyle(.plain))
                    .demoID("slideover.step.back")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PairingCard: View {
    let pairAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            SetupGlyph(systemName: "dot.radiowaves.left.and.right", color: .green)

            VStack(spacing: 8) {
                Text("OBDLink MX+ Found")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("The adapter is nearby and ready. Keep the ignition on while the connection is prepared.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                SetupMetricRow(title: "Signal", value: "Strong")
                SetupMetricRow(title: "Protocol", value: "CAN 11-bit")
                SetupMetricRow(title: "Latency", value: "18 ms")
            }

            Button(action: pairAction) {
                Label("Pair Adapter", systemImage: "link")
            }
            .buttonStyle(CC_SlideOverCardActionButtonStyle(.primary, tint: .green))
            .demoID("slideover.pair.confirm")
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FullWidthPreviewCard: View {
    let closeAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            SetupGlyph(systemName: "rectangle.compress.vertical", color: .blue)

            VStack(spacing: 8) {
                Text("Full-width Layout")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("This presentation removes the narrow outside margins and sits flush against the bottom edge while keeping content clear of the home indicator.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: closeAction) {
                Label("Close", systemImage: "checkmark")
            }
            .buttonStyle(CC_SlideOverCardActionButtonStyle(.primary, tint: .blue))
            .demoID("slideover.fullWidth.close")
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BleedingPreviewCard: View {
    let closeAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            SetupGlyph(systemName: "circle.lefthalf.filled", color: .purple)

            VStack(spacing: 8) {
                Text("Glass Preview")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("This mode deliberately lets the presenting content influence the card surface. Use it for app-specific glass looks, not for Apple-style setup prompts.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: closeAction) {
                Label("Close", systemImage: "xmark")
            }
            .buttonStyle(CC_SlideOverCardActionButtonStyle(.primary, tint: .purple))
            .demoID("slideover.glass.close")
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RequiredStepCard: View {
    let acceptAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            SetupGlyph(systemName: "lock.shield.fill", color: .orange)

            VStack(spacing: 8) {
                Text("Safety Interlock")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("This card stays in place while a required setup step is pending. Dragging is allowed, but it returns to position.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            SetupFeatureRow(
                symbol: "exclamationmark.triangle.fill",
                title: "Explicit confirmation",
                subtitle: "Outside taps and drag dismissal are disabled."
            )

            Button(action: acceptAction) {
                Label("Acknowledge", systemImage: "checkmark")
            }
            .buttonStyle(CC_SlideOverCardActionButtonStyle(.primary, tint: .orange))
            .demoID("slideover.required.accept")
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ActionStylesCard: View {
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    let closeAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                CC_SlideOverCardDismissButton(action: closeAction)
                    .demoID("slideover.actions.dismiss")
            }

            SetupGlyph(systemName: "square.stack.3d.up.fill", color: .indigo)

            VStack(spacing: 8) {
                Text("Action Prominence")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("The default grabber and dismiss button are hidden here, so the card supplies its own CC_SlideOverCardDismissButton and shows all three button prominences.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 9) {
                Button(action: primaryAction) {
                    Label("Primary", systemImage: "checkmark")
                }
                .buttonStyle(CC_SlideOverCardActionButtonStyle(.primary, tint: .indigo))
                .demoID("slideover.actions.primary")

                Button(action: secondaryAction) {
                    Label("Secondary", systemImage: "wrench.and.screwdriver")
                }
                .buttonStyle(CC_SlideOverCardActionButtonStyle(.secondary, tint: .indigo))
                .demoID("slideover.actions.secondary")

                Button(action: closeAction) {
                    Label("Plain", systemImage: "xmark")
                }
                .buttonStyle(CC_SlideOverCardActionButtonStyle(.plain))
                .demoID("slideover.actions.plain")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TextFieldSetupCard: View {
    @Binding var adapterName: String

    let saveAction: () -> Void

    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 18) {
            SetupGlyph(systemName: "keyboard.fill", color: .green)

            VStack(spacing: 8) {
                Text("Name Adapter")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("This setup card intentionally focuses a text field so keyboard avoidance, focus changes and content-height updates can be checked together.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Adapter Name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Workshop adapter", text: $adapterName)
                    .focused($isNameFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(saveAction)
                    .padding(.horizontal, 13)
                    .frame(minHeight: 48)
                    .background(.quaternary.opacity(0.42), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isNameFocused ? Color.green.opacity(0.52) : Color.clear, lineWidth: 1)
                    }
                    .demoID("slideover.textField.input")

                if !adapterName.isEmpty {
                    Text("\(adapterName.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: saveAction) {
                Label(adapterName.isEmpty ? "Skip" : "Save Name", systemImage: adapterName.isEmpty ? "arrow.right" : "checkmark")
            }
            .buttonStyle(CC_SlideOverCardActionButtonStyle(.primary, tint: .green))
            .demoID("slideover.textField.save")
        }
        .frame(maxWidth: .infinity)
        .task {
            try? await Task.sleep(nanoseconds: 320_000_000)
            isNameFocused = true
        }
    }
}

private struct SetupGlyph: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 40, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .frame(width: 78, height: 78)
            .background(color.opacity(0.13), in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(color.opacity(0.18), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

private struct SetupFeatureRow: View {
    let symbol: String
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct SetupMetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .font(.system(.body, design: .rounded).weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private enum SetupStep: String, CaseIterable, Identifiable {
    case privacy
    case network
    case finish

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
            case .privacy: "privacy"
            case .network: "network"
            case .finish: "finish"
        }
    }

    var previous: SetupStep? {
        switch self {
            case .privacy: nil
            case .network: .privacy
            case .finish: .network
        }
    }

    var next: SetupStep? {
        switch self {
            case .privacy: .network
            case .network: .finish
            case .finish: nil
        }
    }

    var progress: Double {
        switch self {
            case .privacy: 0.33
            case .network: 0.66
            case .finish: 1.0
        }
    }

    var symbol: String {
        switch self {
            case .privacy: "hand.raised.fill"
            case .network: "network"
            case .finish: "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
            case .privacy: .indigo
            case .network: .teal
            case .finish: .green
        }
    }

    var title: String {
        switch self {
            case .privacy: "Review Permissions"
            case .network: "Prepare Local Network"
            case .finish: "Ready to Diagnose"
        }
    }

    var message: String {
        switch self {
            case .privacy: "The app can request camera, photo and local network access only when a workflow needs it."
            case .network: "Local network authorization keeps Wi-Fi adapters discoverable without hiding the main interface."
            case .finish: "The setup flow can now hand control back to the catalog or continue into a product workflow."
        }
    }

    var details: [String] {
        switch self {
            case .privacy:
                ["Camera prompts stay contextual", "Photos use the system picker", "No permission copy is duplicated"]
            case .network:
                ["Discovery remains cancellable", "Status survives card changes", "iPad presentation stays centered"]
            case .finish:
                ["State is item-driven", "The card animates between steps", "Dismiss callbacks update the parent view"]
        }
    }

    var secondaryDetails: [SetupStepDetail] {
        switch self {
            case .privacy, .finish:
                []
            case .network:
                [
                    SetupStepDetail(
                        title: "Height changes animate",
                        subtitle: "This step is intentionally taller so the card can resize without a jump."
                    )
                ]
        }
    }

    var primaryTitle: String {
        switch self {
            case .privacy: "Continue"
            case .network: "Continue"
            case .finish: "Done"
        }
    }
}

private struct SetupStepDetail: Hashable {
    let title: String
    let subtitle: String
}

#Preview {
    NavigationStack {
        SlideOverCardDemoView()
            .navigationTitle("Slide-over Card")
    }
}
