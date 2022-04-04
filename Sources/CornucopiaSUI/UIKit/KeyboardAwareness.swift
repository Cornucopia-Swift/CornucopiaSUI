//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(UIKit)
import Combine
import UIKit

public protocol KeyboardAwareness {

    var keyboardAwarenessVisibilityPublisher: AnyPublisher<Bool, Never> { get }
}

public extension KeyboardAwareness {

    var keyboardAwarenessVisibilityPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },

            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}
#endif
