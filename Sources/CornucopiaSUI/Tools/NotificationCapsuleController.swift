//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

public enum NotificationCapsuleStyle {
    case info
    case success
    case warning
    case error
    case activity
}

public final class NotificationCapsuleController: ObservableObject {

    struct Item: Equatable {
        let id: UUID
        let message: String
        let style: NotificationCapsuleStyle
        let duration: TimeInterval?

        static func == (lhs: Item, rhs: Item) -> Bool { lhs.id == rhs.id }
    }

    @Published var currentItem: Item?

    private var dismissTask: Task<Void, Never>?

    public init() {}

    public func show(_ message: String, style: NotificationCapsuleStyle = .info, duration: TimeInterval? = 3.0) {
        let effectiveDuration: TimeInterval? = if style == .activity && duration == 3.0 { nil } else { duration }
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            self.currentItem = Item(id: UUID(), message: message, style: style, duration: effectiveDuration)
        }
        if let effectiveDuration {
            dismissTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(effectiveDuration))
                guard !Task.isCancelled else { return }
                self?.dismiss()
            }
        }
    }

    public func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            self.currentItem = nil
        }
    }
}
