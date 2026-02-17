//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI
import SFSafeSymbols

struct NotificationCapsule: View {
    let item: NotificationCapsuleController.Item
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            iconView
            Text(item.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(maxWidth: 380)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(tintColor.opacity(colorScheme == .dark ? 0.12 : 0.13))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.18 : 0.5),
                                    Color.black.opacity(colorScheme == .dark ? 0.2 : 0.06)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.08), radius: 16, y: 6)
        .shadow(color: tintColor.opacity(colorScheme == .dark ? 0.2 : 0.15), radius: 20, y: 4)
    }

    @ViewBuilder
    private var iconView: some View {
        switch item.style {
            case .activity:
                ProgressView()
                    .controlSize(.small)
                    .tint(tintColor)
            default:
                Image(systemSymbol: iconSymbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tintColor)
                    .imageScale(.medium)
        }
    }

    private var iconSymbol: SFSymbol {
        switch item.style {
            case .info:     .infoCircleFill
            case .success:  .checkmarkCircleFill
            case .warning:  .exclamationmarkTriangleFill
            case .error:    .xmarkCircleFill
            case .activity: .circleFill
        }
    }

    private var tintColor: Color {
        switch item.style {
            case .info:     .accentColor
            case .success:  .green
            case .warning:  .orange
            case .error:    .red
            case .activity: .accentColor
        }
    }
}

#if DEBUG
#Preview("Notification Capsule") {
    struct NotificationCapsuleDemo: View {
        @StateObject private var controller = NotificationCapsuleController()

        var body: some View {
            NavigationStack {
                List {
                    Section("Message Styles") {
                        button("Info Message", style: .info, icon: .infoCircle)
                        button("Data saved!", style: .success, icon: .checkmarkCircle)
                        button("Connection unstable", style: .warning, icon: .exclamationmarkTriangle)
                        button("Upload failed", style: .error, icon: .xmarkCircle)
                    }

                    Section("Activity") {
                        Button {
                            controller.show("Loading data\u{2026}", style: .activity)
                        } label: {
                            Label("Show Activity (persistent)", systemImage: "arrow.circlepath")
                        }

                        Button {
                            controller.dismiss()
                        } label: {
                            Label("Dismiss", systemImage: "xmark")
                        }
                        .disabled(controller.currentItem == nil)
                    }

                    Section("Edge Cases") {
                        Button {
                            controller.show("OK", style: .success, duration: 1.5)
                        } label: {
                            Label("Minimal text", systemImage: "text.badge.minus")
                        }

                        Button {
                            controller.show("This is a longer message that might need a second line to display properly", style: .warning, duration: 5)
                        } label: {
                            Label("Long text (5s)", systemImage: "text.badge.plus")
                        }

                        Button {
                            controller.show("First", style: .info)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                controller.show("Replaced!", style: .success)
                            }
                        } label: {
                            Label("Rapid replacement", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }

                    Section("Sequenced Demo") {
                        Button {
                            Task { @MainActor in
                                controller.show("Connecting\u{2026}", style: .activity)
                                try? await Task.sleep(for: .seconds(2))
                                controller.show("Downloading\u{2026}", style: .activity)
                                try? await Task.sleep(for: .seconds(2))
                                controller.show("Download complete!", style: .success, duration: 2.5)
                            }
                        } label: {
                            Label("Connect \u{2192} Download \u{2192} Done", systemImage: "arrow.right.circle")
                        }
                    }
                }
                .navigationTitle("Notification Capsule")
            }
            .CC_notificationCapsule(controller)
        }

        private func button(_ message: String, style: NotificationCapsuleStyle, icon: SFSymbol) -> some View {
            Button {
                controller.show(message, style: style)
            } label: {
                Label(message, systemSymbol: icon)
            }
        }
    }

    return NotificationCapsuleDemo()
}
#endif
