//
//  ControlsDemoViews.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
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
    @State private var showCustomDialog = false
    @State private var result = "No action yet"

    var body: some View {
        DemoScroll {
            DemoPanel("NotificationCapsule", subtitle: "Transient overlay messages for success, warning, error and activity states.") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                    capsuleButton("Info", style: .info)
                    capsuleButton("Success", style: .success)
                    capsuleButton("Warning", style: .warning)
                    capsuleButton("Error", style: .error)
                    capsuleButton("Activity", style: .activity, duration: 5)
                }
            }

            DemoPanel("CC_confirmationDialog", subtitle: "iOS bottom confirmation surface with backdrop and role-aware actions.") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Show destructive dialog") {
                        showDialog = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .demoID("dialog.destructive")

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

    private func capsuleButton(_ title: String, style: NotificationCapsuleStyle, duration: TimeInterval? = 2) -> some View {
        Button(title) {
            capsuleController.show("\(title) capsule", style: style, duration: duration)
        }
        .buttonStyle(.bordered)
    }
}
