//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI
import SFSafeSymbols

struct NotificationCapsule: View {
    let item: NotificationCapsuleController.Item
    let dismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: stackSpacing) {
            iconView
                .frame(width: 25, height: 25)
                .opacity(iconSymbol == nil && item.message.style != .activity ? 0 : 1)

            VStack(spacing: -1) {
                Text(item.message.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(item.message.titleColor ?? .primary)
                    .lineLimit(item.message.titleNumberOfLines)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)

                if let subtitle = item.message.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(item.message.subtitleColor ?? .secondary)
                        .lineLimit(item.message.subtitleNumberOfLines)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.82)
                }
            }

            actionView
                .frame(width: 35, height: 35)
                .opacity(item.message.action?.icon == nil ? 0 : 1)
        }
        .padding(contentInsets)
        .frame(maxWidth: 380)
        .notificationCapsuleBackground(item.message.background, tint: tintColor, colorScheme: colorScheme)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.38 : 0.15), radius: 25)
        .offset(y: dragOffset)
        .gesture(dismissDragGesture)
        .contentShape(Capsule(style: .continuous))
        .onTapGesture {
            guard let action = item.message.action, action.icon == nil else { return }
            action.handler()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.message.resolvedAccessibilityMessage)
    }

    @ViewBuilder
    private var iconView: some View {
        switch item.message.style {
            case .activity:
                ProgressView()
                    .controlSize(.small)
                    .tint(tintColor)
            default:
                if let iconSymbol {
                    Image(systemSymbol: iconSymbol)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(item.message.iconColor ?? tintColor)
                        .imageScale(.medium)
                }
        }
    }

    @ViewBuilder
    private var actionView: some View {
        if let action = item.message.action, let icon = action.icon {
            Button {
                action.handler()
            } label: {
                Image(systemSymbol: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 35, height: 35)
                    .background(tintColor, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(action.accessibilityLabel ?? "Action")
        }
    }

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let translation = value.translation.height
                let signedTranslation = item.position == .top ? min(0, translation) : max(0, translation)
                dragOffset = signedTranslation
            }
            .onEnded { value in
                let translation = value.translation.height
                let velocity = value.predictedEndTranslation.height
                let shouldDismiss = switch item.position {
                    case .top:
                        translation < -45 || velocity < -90
                    case .bottom:
                        translation > 45 || velocity > 90
                }

                if shouldDismiss {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private var contentInsets: EdgeInsets {
        let hasSubtitle = item.message.subtitle != nil
        let hasIcon = iconSymbol != nil || item.message.style == .activity
        let hasActionIcon = item.message.action?.icon != nil

        if !hasIcon && !hasActionIcon {
            return EdgeInsets(top: hasSubtitle ? 8 : 15, leading: 50, bottom: hasSubtitle ? 8 : 15, trailing: 50)
        }

        return EdgeInsets(
            top: hasSubtitle ? 8 : (hasActionIcon ? 10 : 15),
            leading: hasIcon ? 12 : 40,
            bottom: hasSubtitle ? 8 : (hasActionIcon ? 10 : 15),
            trailing: hasActionIcon ? 10 : 40
        )
    }

    private var stackSpacing: CGFloat {
        if iconSymbol != nil, item.message.action?.icon != nil {
            return 20
        }
        return 15
    }

    private var iconSymbol: SFSymbol? {
        if let icon = item.message.icon {
            return icon
        }

        switch item.message.style {
            case .info:     return .infoCircleFill
            case .success:  return .checkmarkCircleFill
            case .warning:  return .exclamationmarkTriangleFill
            case .error:    return .xmarkCircleFill
            case .activity: return nil
        }
    }

    private var tintColor: Color {
        switch item.message.style {
            case .info:     .accentColor
            case .success:  .green
            case .warning:  .orange
            case .error:    .red
            case .activity: .accentColor
        }
    }
}

private extension View {
    @ViewBuilder
    func notificationCapsuleBackground(
        _ background: NotificationCapsuleBackground,
        tint: Color,
        colorScheme: ColorScheme
    ) -> some View {
        switch background.resolved {
            case .glass:
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                    self
                        .background {
                            Capsule(style: .continuous)
                                .fill(tint.opacity(colorScheme == .dark ? 0.10 : 0.08))
                        }
                        .glassEffect(.regular.tint(tint.opacity(0.08)), in: Capsule(style: .continuous))
                } else {
                    materialCapsuleBackground(tint: tint, colorScheme: colorScheme)
                }
            case .standard, .default:
                self
                    .background {
                        Capsule(style: .continuous)
                            .fill(Self.standardBackgroundColor)
                            .overlay {
                                Capsule(style: .continuous)
                                    .fill(tint.opacity(colorScheme == .dark ? 0.08 : 0.06))
                            }
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(Self.borderGradient(colorScheme: colorScheme), lineWidth: 0.5)
                            }
                    }
        }
    }

    private func materialCapsuleBackground(tint: Color, colorScheme: ColorScheme) -> some View {
        background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(tint.opacity(colorScheme == .dark ? 0.12 : 0.10))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(Self.borderGradient(colorScheme: colorScheme), lineWidth: 0.5)
                }
        }
    }

    private static var standardBackgroundColor: Color {
        #if os(iOS) || os(tvOS) || os(visionOS)
        Color(.secondarySystemBackground)
        #elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.secondary.opacity(0.18)
        #endif
    }

    private static func borderGradient(colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.18 : 0.5),
                Color.black.opacity(colorScheme == .dark ? 0.2 : 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
                controller.show(NotificationCapsuleMessage(title: message, style: style, icon: icon))
            } label: {
                Label(message, systemSymbol: icon)
            }
        }
    }

    return NotificationCapsuleDemo()
}
#endif
