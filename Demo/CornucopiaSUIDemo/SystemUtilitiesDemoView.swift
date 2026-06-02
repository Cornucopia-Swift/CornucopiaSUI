//
//  SystemUtilitiesDemoView.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import Network
import SwiftUI
import UIKit

struct SystemUtilitiesDemoView: View {
    @StateObject private var reachability = ObservableReachability.shared
    @StateObject private var localNetworkAuthorization = ObservableLocalNetworkAuthorization.shared
    @StateObject private var busyness = ObservableBusyness(debounceInterval: .milliseconds(180))

    @State private var selectedImage = UIImage(systemName: "photo") ?? UIImage()
    @State private var showImagePicker = false
    @State private var idleTimerLog = "not run"

    var body: some View {
        DemoScroll {
            DemoPanel("ObservableReachability", subtitle: "NWPathMonitor wrapper for app-wide connection state.") {
                VStack(alignment: .leading, spacing: 8) {
                    DemoMetric(title: "Connected", value: reachability.isConnected ? "yes" : "no")
                    DemoMetric(title: "Path", value: reachability.currentPath?.status.description ?? "unknown")
                }
            }

            DemoPanel("ObservableLocalNetworkAuthorization", subtitle: "Tracks the local network authorization prompt state.") {
                VStack(alignment: .leading, spacing: 8) {
                    DemoMetric(title: "Status", value: localNetworkStatusDescription)
                    Text("This may trigger Apple's local-network permission flow in a fresh simulator.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            DemoPanel("ObservableBusyness", subtitle: "Debounced busy-state observer for overlapping async work.") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if busyness.isBusy {
                            ProgressView()
                        }
                        DemoMetric(title: "Busy", value: busyness.isBusy ? "yes" : "no")
                    }
                    Button("Run overlapping work") {
                        runBusynessDemo()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            DemoPanel("DevicePickerView", subtitle: "SwiftUI wrapper around AVRoutePickerView for AirPlay and route selection.") {
                HStack(spacing: 12) {
                    DevicePickerView(
                        configuration: .init(
                            activeTintColor: .green,
                            normalTintColor: .accentColor,
                            prioritizesVideoDevices: false
                        )
                    )
                    .frame(width: 48, height: 36)
                    Text("Tap the route picker to inspect available output devices.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            DemoPanel("ImagePickerView & UIImage Resize", subtitle: "UIKit picker bridge plus CC_resized(height:) helper.") {
                VStack(alignment: .leading, spacing: 12) {
                    Image(uiImage: selectedImage.CC_resized(height: 80))
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 120)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button("Pick image") {
                        showImagePicker = true
                    }
                    .buttonStyle(.bordered)
                }
            }

            DemoPanel("UIApplication.CC_withIdleTimerDisabled", subtitle: "Temporarily disables display sleep during long-running operations.") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Run protected wait") {
                        Task {
                            idleTimerLog = "running"
                            try? await UIApplication.shared.CC_withIdleTimerDisabled {
                                try await Task.sleep(for: .milliseconds(600))
                                return ()
                            }
                            idleTimerLog = "completed"
                        }
                    }
                    .buttonStyle(.bordered)
                    DemoMetric(title: "Idle timer demo", value: idleTimerLog)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $selectedImage)
        }
    }

    private var localNetworkStatusDescription: String {
        switch localNetworkAuthorization.status {
            case .notDetermined: "not determined"
            case .denied: "denied"
            case .granted: "granted"
        }
    }

    private func runBusynessDemo() {
        busyness.enterBusy()
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            busyness.leaveBusy()
        }

        busyness.enterBusy()
        Task {
            try? await Task.sleep(for: .milliseconds(1_100))
            busyness.leaveBusy()
        }
    }
}

private extension NWPath.Status {
    var description: String {
        switch self {
            case .satisfied: "satisfied"
            case .unsatisfied: "unsatisfied"
            case .requiresConnection: "requires connection"
            @unknown default: "unknown"
        }
    }
}

#Preview {
    NavigationStack {
        SystemUtilitiesDemoView()
    }
}
