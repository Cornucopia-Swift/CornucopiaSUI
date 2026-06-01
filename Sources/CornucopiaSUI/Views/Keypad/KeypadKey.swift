//
//  KeypadKey.swift
//  CornucopiaSUI
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A single value key for a domain keypad, with optional long-press *alternates*.
///
/// A plain tap inserts the key's own value (`onTap`). When `alternates` are supplied, a
/// long press opens a tap-to-pick popover of related values (`onSelectAlternate`), mirroring
/// the system keyboard's long-press behaviour — e.g. holding `2` on the IPv4 keypad to reach
/// the subnet-mask octets, or a dedicated `.com` key revealing other TLDs. Keys with
/// alternates show a small corner dot so the affordance is discoverable.
struct KeypadKey<Role: KeypadKeyRole>: View {

    let title: String
    let role: Role
    var isEnabled: Bool = true
    var alternates: [String] = []
    var accessibilityLabel: String? = nil
    let onTap: () -> Void
    var onSelectAlternate: ((String) -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAlternates = false
    @State private var didLongPress = false

    private var hasAlternates: Bool { isEnabled && !alternates.isEmpty && onSelectAlternate != nil }

    var body: some View {
        Button {
            // A long press both opens the popover and ends with a touch-up; ignore that
            // trailing tap so holding a key never also inserts its plain value.
            guard !didLongPress else { return }
            onTap()
        } label: {
            Text(title)
                .font(.title3.monospaced().weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 42)
                .overlay(alignment: .topTrailing) { affordance }
        }
        .buttonStyle(KeypadKeyStyle(role: role))
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel ?? title)
        .modifier(LongPressAlternates(enabled: hasAlternates, show: $showingAlternates, didLongPress: $didLongPress))
        .onChange(of: showingAlternates) { presented in
            if !presented { didLongPress = false }
        }
        .popover(isPresented: $showingAlternates) { alternatesPopover }
    }

    @ViewBuilder
    private var affordance: some View {
        if !alternates.isEmpty {
            Circle()
                .fill((isEnabled ? role.colors(for: colorScheme).foreground : Color.secondary).opacity(0.4))
                .frame(width: 4, height: 4)
                .padding(5)
        }
    }

    @ViewBuilder
    private var alternatesPopover: some View {
        let chips = HStack(spacing: 6) {
            ForEach(alternates, id: \.self) { value in
                Button {
                    showingAlternates = false
                    onSelectAlternate?(value)
                } label: {
                    Text(value)
                        .font(.subheadline.monospaced().weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule(style: .continuous).fill(Color.accentColor.opacity(0.16)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(value)
            }
        }
        .padding(10)

        if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
            chips.presentationCompactAdaptation(.popover)
        } else {
            chips
        }
    }
}

/// Adds a long-press gesture (without swallowing the plain tap) that opens the alternates popover.
private struct LongPressAlternates: ViewModifier {

    let enabled: Bool
    @Binding var show: Bool
    @Binding var didLongPress: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.simultaneousGesture(
                LongPressGesture(minimumDuration: 0.35).onEnded { _ in
                    didLongPress = true
                    show = true
#if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
                }
            )
        } else {
            content
        }
    }
}
