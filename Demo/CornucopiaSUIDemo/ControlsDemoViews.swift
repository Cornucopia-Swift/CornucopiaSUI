//
//  ControlsDemoViews.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import SFSafeSymbols
import SwiftUI

struct BusyButtonsDemoView: View {
    @State private var classicBusy = false
    @State private var modernBusy = false
    @State private var pulseBusy = false
    @State private var orbitBusy = false
    @State private var confirmedBusy = false
    @State private var log: [String] = []

    var body: some View {
        DemoScroll {
            DemoPanel("BusyButton", subtitle: "A compact async button that disables itself and shows progress.") {
                VStack(alignment: .leading, spacing: 12) {
                    BusyButton(isBusy: $classicBusy, title: "Sync ECU") {
                        await appendAfterDelay("BusyButton completed")
                    }
                    .buttonStyle(.borderedProminent)
                    .demoID("busy.basic")

                    Text("Upload Snapshot")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .CC_busyButton(isBusy: $modernBusy, indicatorStyle: .modern) {
                            await appendAfterDelay("CC_busyButton completed")
                        }
                        .buttonStyle(.bordered)
                        .demoID("busy.wrapper")
                }
            }

            DemoPanel("GenericBusyButton", subtitle: "Custom labels and indicator styles for longer-running actions.") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        GenericBusyButton("Classic", isBusy: $pulseBusy, indicatorStyle: .classic) {
                            await appendAfterDelay("Classic indicator completed")
                        }
                        .buttonStyle(.bordered)

                        GenericBusyButton(isBusy: $orbitBusy, indicatorStyle: .orbit) {
                            await appendAfterDelay("Orbit indicator completed")
                        } label: {
                            Label("Route", systemImage: "point.3.connected.trianglepath.dotted")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    ConfirmationBusyButton(
                        "Erase Cache",
                        isBusy: $confirmedBusy,
                        confirmationTitle: "Erase cached data?",
                        confirmationMessage: "The demo only appends to the log, but production flows use this before destructive work.",
                        confirmButtonTitle: "Erase",
                        confirmButtonRole: .destructive,
                        indicatorStyle: .pulse
                    ) {
                        await appendAfterDelay("Confirmed action completed")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .demoID("busy.confirmation")
                }
            }

            DemoPanel("Action Log") {
                if log.isEmpty {
                    Text("Run an action to add a log entry.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(log, id: \.self) { entry in
                        Text(entry)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
        }
    }

    @MainActor
    private func appendAfterDelay(_ message: String) async {
        try? await Task.sleep(for: .milliseconds(800))
        log.insert(message, at: 0)
    }
}

struct DialogsDemoView: View {
    @StateObject private var capsuleController = NotificationCapsuleController()
    @State private var showDialog = false
    @State private var showStandardDialog = false
    @State private var showGlassDialog = false
    @State private var showCustomDialog = false
    @State private var result = "No action yet"
    @State private var toastPreset: ToastPreset = .copied
    @State private var toastPosition: NotificationCapsulePosition = .top
    @State private var toastBackground: NotificationCapsuleBackground = .default
    @State private var useCustomColors = false
    @State private var toastTitleColor = Color.primary
    @State private var toastSubtitleColor = Color.secondary
    @State private var toastIconColor = Color.accentColor

    var body: some View {
        DemoScroll {
            DemoPanel("NotificationCapsule", subtitle: "Drops-inspired transient HUDs with title, subtitle, queueing, actions, positions and glass backgrounds.") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Preset", selection: $toastPreset) {
                        ForEach(ToastPreset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .demoID("toast.preset")

                    Picker("Position", selection: $toastPosition) {
                        Text("Top").tag(NotificationCapsulePosition.top)
                        Text("Bottom").tag(NotificationCapsulePosition.bottom)
                    }
                    .pickerStyle(.segmented)
                    .demoID("toast.position")

                    Picker("Background", selection: $toastBackground) {
                        Text("Default").tag(NotificationCapsuleBackground.default)
                        Text("Standard").tag(NotificationCapsuleBackground.standard)
                        Text("Glass").tag(NotificationCapsuleBackground.glass)
                    }
                    .pickerStyle(.segmented)
                    .demoID("toast.background")

                    Toggle("Custom colors", isOn: $useCustomColors)
                        .demoID("toast.colors.toggle")

                    if useCustomColors {
                        VStack(alignment: .leading, spacing: 8) {
                            ColorPicker("Title", selection: $toastTitleColor, supportsOpacity: false)
                            ColorPicker("Subtitle", selection: $toastSubtitleColor, supportsOpacity: false)
                            ColorPicker("Icon", selection: $toastIconColor, supportsOpacity: false)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 126), spacing: 10)], spacing: 10) {
                        Button("Show") {
                            capsuleController.show(makeToastMessage())
                        }
                        .buttonStyle(.borderedProminent)
                        .demoID("toast.show")

                        Button("Queue 3") {
                            queueToastSequence()
                        }
                        .buttonStyle(.bordered)
                        .demoID("toast.queue")

                        Button("Replace") {
                            capsuleController.show(makeToastMessage(), presentation: .replaceCurrent)
                        }
                        .buttonStyle(.bordered)
                        .demoID("toast.replace")

                        Button("Dismiss All") {
                            capsuleController.dismissAll()
                        }
                        .buttonStyle(.bordered)
                        .demoID("toast.dismissAll")
                    }
                }
            }

            DemoPanel("CC_confirmationDialog", subtitle: "Drops-inspired bottom confirmation surface with standard and glass looks.") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Show destructive dialog") {
                        showDialog = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .demoID("dialog.destructive")

                    HStack {
                        Button("Standard") {
                            showStandardDialog = true
                        }
                        .buttonStyle(.bordered)
                        .demoID("dialog.standard")

                        Button("Glass") {
                            showGlassDialog = true
                        }
                        .buttonStyle(.bordered)
                        .demoID("dialog.glass")
                    }

                    Button("Show custom content dialog") {
                        showCustomDialog = true
                    }
                    .buttonStyle(.bordered)
                    .demoID("dialog.custom")

                    DemoMetric(title: "Result", value: result)
                }
            }
        }
        .CC_notificationCapsule(capsuleController)
        .CC_confirmationDialog(
            "Delete session?",
            isPresented: $showDialog,
            actions: [
                ConfirmationDialogAction("Delete", role: .destructive) {
                    result = "Deleted session"
                    capsuleController.show("Session deleted", style: .warning)
                }
            ],
            message: "Use this for irreversible app actions where the native confirmationDialog styling is not flexible enough."
        )
        .CC_confirmationDialog(
            "Standard Surface",
            isPresented: $showStandardDialog,
            background: .init(surfaceStyle: .standard),
            actions: [
                ConfirmationDialogAction("Save Snapshot") {
                    result = "Saved with standard dialog"
                    capsuleController.show("Standard dialog completed", style: .success)
                }
            ],
            message: "A crisp floating system surface for routine confirmations."
        )
        .CC_confirmationDialog(
            "Glass Surface",
            isPresented: $showGlassDialog,
            background: .init(surfaceStyle: .glass),
            actions: [
                ConfirmationDialogAction("Connect") {
                    result = "Connected with glass dialog"
                    capsuleController.show("Glass dialog completed", style: .success)
                }
            ],
            message: "Uses Liquid Glass on OS 26 and a material fallback on older systems."
        )
        .CC_confirmationDialog("Choose response", isPresented: $showCustomDialog) {
            CC_ConfirmationDialogButton("Accept") {
                result = "Accepted custom dialog"
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text("The message slot can host arbitrary SwiftUI content.")
                DemoPill("Custom message", color: .blue)
            }
        }
    }

    private func makeToastMessage(preset: ToastPreset? = nil) -> NotificationCapsuleMessage {
        let preset = preset ?? toastPreset
        let action: NotificationCapsuleAction? = if preset.hasAction {
            NotificationCapsuleAction(icon: .arrowCounterclockwise, accessibilityLabel: "Retry") {
                result = "Toast action tapped"
                capsuleController.show(
                    NotificationCapsuleMessage(
                        title: "Retry queued",
                        subtitle: "The action can enqueue follow-up feedback.",
                        style: .info,
                        icon: .arrowCounterclockwise,
                        position: toastPosition,
                        duration: .recommended
                    )
                )
            }
        } else {
            nil
        }

        return NotificationCapsuleMessage(
            title: preset.toastTitle,
            titleColor: useCustomColors ? toastTitleColor : nil,
            subtitle: preset.subtitle,
            subtitleColor: useCustomColors ? toastSubtitleColor : nil,
            style: preset.style,
            icon: preset.icon,
            iconColor: useCustomColors ? toastIconColor : nil,
            background: toastBackground,
            action: action,
            position: toastPosition,
            duration: preset.duration
        )
    }

    private func queueToastSequence() {
        capsuleController.show(makeToastMessage(preset: .copied))
        capsuleController.show(makeToastMessage(preset: .connected))
        capsuleController.show(makeToastMessage(preset: .failed))
    }
}

private enum ToastPreset: String, CaseIterable, Identifiable {
    case copied
    case connected
    case failed
    case retry
    case activity

    var id: String { rawValue }

    var title: String {
        switch self {
            case .copied: "Copied"
            case .connected: "Connected"
            case .failed: "Failed"
            case .retry: "Retry Action"
            case .activity: "Activity"
        }
    }

    var toastTitle: String {
        switch self {
            case .copied: "Copied"
            case .connected: "Adapter connected"
            case .failed: "Upload failed"
            case .retry: "Command failed"
            case .activity: "Syncing"
        }
    }

    var subtitle: String? {
        switch self {
            case .copied: "Diagnostic payload copied to pasteboard."
            case .connected: "OBDLink MX+ is ready for requests."
            case .failed: "No response before timeout."
            case .retry: "Tap the action button to enqueue a retry notice."
            case .activity: "Waiting for the adapter."
        }
    }

    var style: NotificationCapsuleStyle {
        switch self {
            case .copied, .connected: .success
            case .failed, .retry: .error
            case .activity: .activity
        }
    }

    var icon: SFSymbol? {
        switch self {
            case .copied: .documentOnDocumentFill
            case .connected: .checkmarkCircleFill
            case .failed: .xmarkCircleFill
            case .retry: .exclamationmarkTriangleFill
            case .activity: nil
        }
    }

    var duration: NotificationCapsuleDuration {
        switch self {
            case .activity: .persistent
            default: .recommended
        }
    }

    var hasAction: Bool {
        self == .retry
    }
}
