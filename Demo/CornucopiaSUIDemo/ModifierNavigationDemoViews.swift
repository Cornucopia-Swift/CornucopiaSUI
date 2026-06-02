//
//  ModifierNavigationDemoViews.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import SwiftUI

enum NavigationDemoTarget: Hashable {
    case detail(String)

    var title: String {
        switch self {
            case .detail: "Navigation Detail"
        }
    }

    @MainActor @ViewBuilder
    var destination: some View {
        switch self {
            case .detail(let value):
                NavigationDemoDetailView(value: value)
        }
    }
}

struct ModifierLabDemoView: View {
    @State private var blinkEnabled = true
    @State private var query = ""
    @State private var debouncedQuery = ""
    @State private var firstAppearCount = 0
    @State private var measuredSize: CGSize = .zero
    @State private var showAutoHeightSheet = false
    @State private var taskTicks = 0

    var body: some View {
        DemoScroll {
            DemoPanel("CC_blinking", subtitle: "Attention cue for transient status, warnings or recording indicators.") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 12, height: 12)
                            .CC_blinking(style: .soft, duration: 0.9, isEnabled: blinkEnabled)
                        Text("Recording trace")
                    }
                    Toggle("Blink enabled", isOn: $blinkEnabled)
                }
            }

            DemoPanel("CC_debouncedTask", subtitle: "Delays work until a rapidly changing value settles.") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Search command history", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .CC_debouncedTask(id: query, seconds: 0.45) {
                            await MainActor.run {
                                debouncedQuery = query
                            }
                        }
                    DemoMetric(title: "Immediate", value: query.isEmpty ? "-" : query)
                    DemoMetric(title: "Debounced", value: debouncedQuery.isEmpty ? "-" : debouncedQuery)
                }
            }

            DemoPanel("CC_onFirstAppear & CC_measureSize", subtitle: "One-shot setup and lightweight layout instrumentation.") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Measured sample")
                        .font(.title2.weight(.semibold))
                        .padding(12)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .CC_measureSize { size in
                            measuredSize = size
                        }
                        .CC_onFirstAppear {
                            firstAppearCount += 1
                        }

                    DemoMetric(title: "First appear count", value: "\(firstAppearCount)")
                    DemoMetric(title: "Measured size", value: "\(Int(measuredSize.width)) x \(Int(measuredSize.height))")
                }
            }

            DemoPanel("CC_task", subtitle: "Starts background work that survives temporary view hierarchy changes.") {
                DemoMetric(title: "Persistent ticks", value: "\(taskTicks)")
                    .CC_task {
                        while !Task.isCancelled {
                            try? await Task.sleep(for: .seconds(1))
                            await MainActor.run {
                                taskTicks += 1
                            }
                        }
                    }
            }

            DemoPanel("CC_presentationDetentAutoHeight", subtitle: "Sheet detent tracks the content instead of using a fixed medium/large size.") {
                Button("Show auto-height sheet") {
                    showAutoHeightSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showAutoHeightSheet) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Auto-height Sheet")
                    .font(.headline)
                Text("This content is intentionally short so the measured presentation detent can hug it.")
                    .foregroundStyle(.secondary)
                Button("Close") {
                    showAutoHeightSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .CC_presentationDetentAutoHeight()
        }
    }
}

struct NavigationControllerDemoView: View {
    @Environment(\.CC_navigationController) private var navigationController

    var body: some View {
        DemoScroll {
            DemoPanel("Environment Controller", subtitle: "The root app injects NavigationController through CC_navigationController.") {
                VStack(alignment: .leading, spacing: 12) {
                    DemoMetric(title: "Root path count", value: "\(navigationController?.path.count ?? 0)")
                    DemoMetric(title: "Contains DemoItem", value: containsCurrentItem ? "yes" : "no")

                    Button("Pop to root") {
                        navigationController?.popToRoot()
                    }
                    .buttonStyle(.bordered)
                }
            }

            DemoPanel("Registered Target Type", subtitle: "The root NavigationStack also registers NavigationDemoTarget.") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Push NavigationDemoTarget.detail") {
                        navigationController?.push(NavigationDemoTarget.detail("navigation-demo-detail"))
                    }
                    .buttonStyle(.borderedProminent)

                    DemoMetric(title: "Contains NavigationDemoTarget", value: containsDetailTarget ? "yes" : "no")
                }
            }
        }
    }

    private var containsCurrentItem: Bool {
        navigationController?.pathContains(DemoItem.navigation) ?? false
    }

    private var containsDetailTarget: Bool {
        navigationController?.pathContains(NavigationDemoTarget.detail("")) ?? false
    }
}

private struct NavigationDemoDetailView: View {
    @Environment(\.CC_navigationController) private var navigationController
    let value: String

    var body: some View {
        DemoScroll {
            DemoPanel("NavigationDemoTarget.detail") {
                VStack(alignment: .leading, spacing: 12) {
                    DemoMetric(title: "Value", value: value)
                    DemoMetric(title: "Path count", value: "\(navigationController?.path.count ?? 0)")
                    Button("Pop one") {
                        navigationController?.pop()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
