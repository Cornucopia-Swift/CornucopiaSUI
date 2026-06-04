//
//  Localization.swift
//  CornucopiaSUI
//

import Foundation

/// Resolves a localized string from this package's own resource bundle.
///
/// Library code must look strings up in `Bundle.module`, not the app bundle:
/// SwiftUI's `Text("key")` and `String(localized:)` default to the *main* bundle,
/// so a string shipped inside the package would never be found there. Route every
/// user-visible literal in CornucopiaSUI through this helper (or `Text(_:bundle:)`).
///
/// `@usableFromInline` so it can be used in public initializers' default argument
/// expressions (e.g. a localized `placeholder` default), which the compiler emits into
/// callers and therefore forbids from referencing plain internal symbols.
@usableFromInline
func CC_localized(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}
