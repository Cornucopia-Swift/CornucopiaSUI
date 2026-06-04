//
//  DemoCatalog.swift
//  CornucopiaSUIDemo
//

import CornucopiaSUI
import SwiftUI

enum DemoSection: String, CaseIterable, Identifiable {
    case inputs
    case controls
    case textAndMotion
    case modifiers
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
            case .inputs: "Input"
            case .controls: "Controls"
            case .textAndMotion: "Text & Motion"
            case .modifiers: "View Modifiers"
            case .system: "System"
        }
    }

    var items: [DemoItem] {
        switch self {
            case .inputs:
                [.hexKeyboard, .vinKeyboard, .vinKeyboardInputMethod, .networkKeyboards, .textFields]
            case .controls:
                [.textFieldStepper, .busyButtons, .slideOverCard, .dialogs]
            case .textAndMotion:
                [.marquee, .blending]
            case .modifiers:
                [.modifierLab, .navigation]
            case .system:
                [.systemUtilities]
        }
    }
}

enum DemoItem: String, CaseIterable, Identifiable, Hashable {
    case hexKeyboard
    case vinKeyboard
    case vinKeyboardInputMethod
    case networkKeyboards
    case textFields
    case textFieldStepper
    case busyButtons
    case slideOverCard
    case dialogs
    case marquee
    case blending
    case modifierLab
    case navigation
    case systemUtilities

    var id: String { rawValue }

    var title: String {
        switch self {
            case .hexKeyboard: "Hex Keyboard"
            case .vinKeyboard: "VIN Keyboard"
            case .vinKeyboardInputMethod: "VIN Input Method"
            case .networkKeyboards: "Network Keyboards"
            case .textFields: "Validated Text Fields"
            case .textFieldStepper: "Text Field Stepper"
            case .busyButtons: "Busy Buttons"
            case .slideOverCard: "Slide-over Card"
            case .dialogs: "Dialogs & Capsules"
            case .marquee: "Marquee"
            case .blending: "Blending Labels"
            case .modifierLab: "Modifier Lab"
            case .navigation: "Navigation Controller"
            case .systemUtilities: "System Utilities"
        }
    }

    var summary: String {
        switch self {
            case .hexKeyboard: "Diagnostic payload entry, byte grouping, paste and send."
            case .vinKeyboard: "VIN slot input, validation, layout switching and decoder path."
            case .vinKeyboardInputMethod: "A regular text field with VINKeyboardInput installed as its inputView."
            case .networkKeyboards: "IPv4 and MAC slot input with domain-gated keys."
            case .textFields: "Styled, network-aware and VIN-aware text entry."
            case .textFieldStepper: "Editable numeric stepper with range clamping and press-and-hold controls."
            case .busyButtons: "Async actions, indicators and confirmation flows."
            case .slideOverCard: "Apple-style setup cards with drag, tap and item-driven presentation."
            case .dialogs: "Custom confirmation dialog and transient notification capsule."
            case .marquee: "Single-line overflow labels and ticker content."
            case .blending: "Independent and synchronized cycling labels."
            case .modifierLab: "Blinking, debounce, first appear, sizing and auto-height sheets."
            case .navigation: "Shared NavigationController environment and typed path state."
            case .systemUtilities: "Reachability, local network authorization, AirPlay and image picker."
        }
    }

    var systemImage: String {
        switch self {
            case .hexKeyboard: "number"
            case .vinKeyboard: "car"
            case .vinKeyboardInputMethod: "keyboard"
            case .networkKeyboards: "network"
            case .textFields: "text.cursor"
            case .textFieldStepper: "plusminus.circle"
            case .busyButtons: "button.programmable"
            case .slideOverCard: "rectangle.bottomthird.inset.filled"
            case .dialogs: "bubble.left.and.exclamationmark.bubble.right"
            case .marquee: "text.alignleft"
            case .blending: "shuffle"
            case .modifierLab: "slider.horizontal.3"
            case .navigation: "point.topleft.down.curvedto.point.bottomright.up"
            case .systemUtilities: "antenna.radiowaves.left.and.right"
        }
    }

    var tint: Color {
        switch self {
            case .hexKeyboard: .blue
            case .vinKeyboard: .green
            case .vinKeyboardInputMethod: .orange
            case .networkKeyboards: .teal
            case .textFields: .indigo
            case .textFieldStepper: .blue
            case .busyButtons: .orange
            case .slideOverCard: .blue
            case .dialogs: .red
            case .marquee: .cyan
            case .blending: .purple
            case .modifierLab: .pink
            case .navigation: .mint
            case .systemUtilities: .brown
        }
    }

    @MainActor @ViewBuilder
    var destination: some View {
        switch self {
            case .hexKeyboard:
                HexKeyboardDemoView()
            case .vinKeyboard:
                VINKeyboardDemoView()
            case .vinKeyboardInputMethod:
                VINKeyboardInputMethodDemoView()
            case .networkKeyboards:
                NetworkKeyboardDemoView()
            case .textFields:
                TextFieldsDemoView()
            case .textFieldStepper:
                TextFieldStepperDemoView()
            case .busyButtons:
                BusyButtonsDemoView()
            case .slideOverCard:
                SlideOverCardDemoView()
            case .dialogs:
                DialogsDemoView()
            case .marquee:
                MarqueeDemoView()
            case .blending:
                BlendingDemoView()
            case .modifierLab:
                ModifierLabDemoView()
            case .navigation:
                NavigationControllerDemoView()
            case .systemUtilities:
                SystemUtilitiesDemoView()
        }
    }
}
