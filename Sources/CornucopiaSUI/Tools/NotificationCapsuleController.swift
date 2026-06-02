//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI
import SFSafeSymbols
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum NotificationCapsuleStyle: Hashable {
    case info
    case success
    case warning
    case error
    case activity
}

public enum NotificationCapsulePosition: Hashable {
    case top
    case bottom
}

public enum NotificationCapsuleBackground: Hashable {
    case `default`
    case standard
    case glass

    var resolved: Self {
        switch self {
            case .default:
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                    .glass
                } else {
                    .standard
                }
            case .standard, .glass:
                self
        }
    }
}

public enum NotificationCapsuleDuration: Equatable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    case recommended
    case seconds(TimeInterval)
    case persistent

    public init(floatLiteral value: TimeInterval) {
        self = .seconds(value)
    }

    public init(integerLiteral value: Int) {
        self = .seconds(TimeInterval(value))
    }

    var timeInterval: TimeInterval? {
        switch self {
            case .recommended:
                2.0
            case .seconds(let seconds):
                abs(seconds)
            case .persistent:
                nil
        }
    }
}

public struct NotificationCapsuleAction {
    let icon: SFSymbol?
    let accessibilityLabel: String?
    let handler: @MainActor () -> Void

    public init(icon: SFSymbol? = nil, accessibilityLabel: String? = nil, handler: @escaping @MainActor () -> Void) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.handler = handler
    }
}

public struct NotificationCapsuleMessage: ExpressibleByStringLiteral {
    public var title: String
    public var titleNumberOfLines: Int
    public var titleColor: Color?
    public var subtitle: String?
    public var subtitleNumberOfLines: Int
    public var subtitleColor: Color?
    public var style: NotificationCapsuleStyle
    public var icon: SFSymbol?
    public var iconColor: Color?
    public var background: NotificationCapsuleBackground
    public var action: NotificationCapsuleAction?
    public var position: NotificationCapsulePosition
    public var duration: NotificationCapsuleDuration
    public var accessibilityMessage: String?

    public init(
        title: String,
        titleNumberOfLines: Int = 1,
        titleColor: Color? = nil,
        subtitle: String? = nil,
        subtitleNumberOfLines: Int = 1,
        subtitleColor: Color? = nil,
        style: NotificationCapsuleStyle = .info,
        icon: SFSymbol? = nil,
        iconColor: Color? = nil,
        background: NotificationCapsuleBackground = .default,
        action: NotificationCapsuleAction? = nil,
        position: NotificationCapsulePosition = .top,
        duration: NotificationCapsuleDuration = .recommended,
        accessibilityMessage: String? = nil
    ) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.titleNumberOfLines = titleNumberOfLines
        self.titleColor = titleColor
        if let subtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines), !subtitle.isEmpty {
            self.subtitle = subtitle
        }
        self.subtitleNumberOfLines = subtitleNumberOfLines
        self.subtitleColor = subtitleColor
        self.style = style
        self.icon = icon
        self.iconColor = iconColor
        self.background = background
        self.action = action
        self.position = position
        self.duration = duration
        self.accessibilityMessage = accessibilityMessage
    }

    public init(stringLiteral title: String) {
        self.init(title: title)
    }

    var resolvedAccessibilityMessage: String {
        accessibilityMessage ?? [title, subtitle].compactMap { $0 }.joined(separator: ", ")
    }
}

public enum NotificationCapsulePresentation: Hashable {
    case enqueue
    case replaceCurrent
}

public final class NotificationCapsuleController: ObservableObject {

    struct Item: Equatable {
        let id: UUID
        let message: NotificationCapsuleMessage

        static func == (lhs: Item, rhs: Item) -> Bool { lhs.id == rhs.id }
    }

    @Published var currentItem: Item?

    private let delayBetweenNotifications: TimeInterval
    private var queue: [Item] = []
    private var dismissTask: Task<Void, Never>?

    public init(delayBetweenNotifications: TimeInterval = 0.35) {
        self.delayBetweenNotifications = delayBetweenNotifications
    }

    public func show(
        _ message: String,
        style: NotificationCapsuleStyle = .info,
        duration: TimeInterval? = 3.0,
        presentation: NotificationCapsulePresentation = .replaceCurrent
    ) {
        let effectiveDuration: NotificationCapsuleDuration = if style == .activity && duration == 3.0 {
            .persistent
        } else if let duration {
            .seconds(duration)
        } else {
            .persistent
        }
        show(
            NotificationCapsuleMessage(title: message, style: style, duration: effectiveDuration),
            presentation: presentation
        )
    }

    public func show(_ message: NotificationCapsuleMessage, presentation: NotificationCapsulePresentation = .enqueue) {
        let item = Item(id: UUID(), message: message)

        switch presentation {
            case .enqueue:
                queue.append(item)
                presentNextIfNeeded()
            case .replaceCurrent:
                queue.removeAll()
                present(item)
        }
    }

    public func dismiss() {
        dismissCurrent(advanceQueue: true)
    }

    public func dismissAll() {
        queue.removeAll()
        dismissCurrent(advanceQueue: false)
    }

    private func presentNextIfNeeded() {
        guard currentItem == nil, !queue.isEmpty else { return }
        present(queue.removeFirst())
    }

    private func present(_ item: Item) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            currentItem = item
        }

        announce(item.message)

        if let effectiveDuration = item.message.duration.timeInterval {
            dismissTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(effectiveDuration))
                guard !Task.isCancelled else { return }
                self?.dismissCurrent(advanceQueue: true)
            }
        }
    }

    private func dismissCurrent(advanceQueue: Bool) {
        guard currentItem != nil else {
            if advanceQueue {
                presentNextAfterDelay()
            }
            return
        }
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            currentItem = nil
        }
        if advanceQueue {
            presentNextAfterDelay()
        }
    }

    private func presentNextAfterDelay() {
        guard !queue.isEmpty else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            if delayBetweenNotifications > 0 {
                try? await Task.sleep(for: .seconds(delayBetweenNotifications))
            }
            guard self.currentItem == nil else { return }
            self.presentNextIfNeeded()
        }
    }

    private func announce(_ message: NotificationCapsuleMessage) {
        #if os(iOS) || os(tvOS) || os(visionOS)
        UIAccessibility.post(notification: .announcement, argument: message.resolvedAccessibilityMessage)
        #elseif os(macOS)
        NSAccessibility.post(
            element: NSApp as Any,
            notification: .announcementRequested,
            userInfo: [
                .announcement: message.resolvedAccessibilityMessage,
                .priority: NSAccessibilityPriorityLevel.high.rawValue
            ]
        )
        #endif
    }
}

extension NotificationCapsuleController.Item {
    var position: NotificationCapsulePosition {
        message.position
    }

    var alignment: Alignment {
        switch message.position {
            case .top: .top
            case .bottom: .bottom
        }
    }
}
