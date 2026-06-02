//
//  ContentView.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import SwiftUI

struct ContentView: View {
    @StateObject private var navigationController = NavigationController()
    @State private var didApplyInitialItem = false

    private let initialItem: DemoItem?

    init(initialItem: DemoItem? = ProcessInfo.processInfo.CC_demoInitialItem) {
        self.initialItem = initialItem
    }

    var body: some View {
        NavigationStack(path: $navigationController.path) {
            List {
                ForEach(DemoSection.allCases) { section in
                    Section(section.title) {
                        ForEach(section.items) { item in
                            Button {
                                navigationController.push(item)
                            } label: {
                                DemoCatalogRow(item: item)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("demo.row.\(item.rawValue)")
                        }
                    }
                }
            }
            .navigationTitle("CornucopiaSUI")
            .navigationDestination(for: DemoItem.self) { item in
                item.destination
                    .navigationTitle(item.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .navigationDestination(for: NavigationDemoTarget.self) { target in
                target.destination
                    .navigationTitle(target.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .environment(\.CC_navigationController, navigationController)
        .task {
            guard !didApplyInitialItem, let initialItem else { return }
            didApplyInitialItem = true
            navigationController.push(initialItem)
        }
    }
}

private extension ProcessInfo {
    var CC_demoInitialItem: DemoItem? {
        guard
            let rawValue = environment["CORNUCOPIA_DEMO_SCREEN"],
            rawValue != "catalog"
        else {
            return nil
        }

        return DemoItem(rawValue: rawValue)
    }
}

private struct DemoCatalogRow: View {
    let item: DemoItem

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.title)
                        .font(.body)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: item.systemImage)
                .foregroundStyle(item.tint)
        }
    }
}

#Preview {
    ContentView()
}
