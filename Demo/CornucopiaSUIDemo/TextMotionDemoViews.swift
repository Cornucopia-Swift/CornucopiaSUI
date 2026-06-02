//
//  TextMotionDemoViews.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import SwiftUI

struct MarqueeDemoView: View {
    @State private var longTitle = "Battery diagnostic capture - extended CAN trace from drivetrain controller with repeated status packets"
    @State private var isPausedExample = false

    var body: some View {
        DemoScroll {
            DemoPanel("MarqueeText", subtitle: "Use for one-line labels that must preserve the full value without wrapping.") {
                VStack(alignment: .leading, spacing: 12) {
                    MarqueeText(longTitle, startDelay: 0.8)
                        .font(.headline)
                        .frame(height: 28)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .demoID("marquee.text")

                    TextField("Long title", text: $longTitle)
                        .textFieldStyle(.roundedBorder)
                }
            }

            DemoPanel("MarqueeScrollView", subtitle: "Works with arbitrary content such as icons, tags and metrics.") {
                VStack(alignment: .leading, spacing: 12) {
                    MarqueeScrollView(startDelay: isPausedExample ? 4 : 0.6, loopPause: 1.0) {
                        HStack(spacing: 12) {
                            Label("Live trace", systemImage: "waveform.path.ecg")
                            DemoPill("7E8", color: .green)
                            DemoPill("62 F1 90", color: .blue)
                            Text("Vehicle speed 48 km/h, coolant 91 C, voltage 13.9 V")
                        }
                        .font(.subheadline)
                    }
                    .frame(height: 32)
                    .demoID("marquee.scrollview")

                    Toggle("Longer initial delay", isOn: $isPausedExample)
                }
            }
        }
    }
}

struct BlendingDemoView: View {
    @State private var synchronized = true
    @State private var fixedLayout = true

    var body: some View {
        DemoScroll {
            DemoPanel("BlendingTextLabel", subtitle: "Cycles short status words when the available space should stay compact.") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Capture")
                            .foregroundStyle(.secondary)
                        Spacer()
                        BlendingTextLabel(["Idle", "Armed", "Capturing"], duration: 1.2)
                            .font(.title3.weight(.semibold))
                    }

                    HStack {
                        Text("VIN section")
                            .foregroundStyle(.secondary)
                        Spacer()
                        BlendingTextLabel(["WMI", "VDS", "VIS"], duration: 0.8)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .demoID("blending.independent")
            }

            DemoPanel("SynchronizedBlendingTextLabel", subtitle: "Keeps repeated labels in phase across a list or dashboard.") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Use synchronization group", isOn: $synchronized)
                    ForEach(0..<5, id: \.self) { index in
                        HStack {
                            Text("Row \(index + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            if synchronized {
                                SynchronizedBlendingTextLabel(["Waiting", "Checking", "Ready"], duration: 1.4)
                            } else {
                                BlendingTextLabel(["Waiting", "Checking", "Ready"], duration: 1.4)
                            }
                        }
                        .padding(10)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .CC_blendingSyncGroup("demo.rows", duration: 1.4)
                .demoID("blending.synchronized")
            }

            DemoPanel("SynchronizedBlendingContainer", subtitle: "Cycles heterogenous view content while optionally reserving the maximum size.") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Fixed layout", isOn: $fixedLayout)
                    SynchronizedBlendingContainer(duration: 1.5, dynamicLayout: !fixedLayout) {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } _: {
                        Label("Scanning adapters", systemImage: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.orange)
                    } _: {
                        HStack {
                            ProgressView()
                            Text("Resolving host")
                        }
                    }
                    .font(.headline)
                    .padding(10)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .CC_blendingSyncGroup("demo.container", duration: 1.5)
                    .demoID("blending.container")
                }
            }
        }
    }
}
