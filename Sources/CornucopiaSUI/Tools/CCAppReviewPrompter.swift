//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

/// Controls when an app should ask the system review prompt to appear.
public struct CCAppReviewPromptConfiguration: Sendable {

    public var storageKeyPrefix: String
    public var minimumSignificantEvents: Int
    public var minimumDaysSinceFirstSeen: Int
    public var minimumDaysBetweenRequests: Int
    public var maximumRequestsPerVersion: Int
    public var currentVersion: String

    public init(
        storageKeyPrefix: String = "CornucopiaSUI.AppReview",
        minimumSignificantEvents: Int = 3,
        minimumDaysSinceFirstSeen: Int = 3,
        minimumDaysBetweenRequests: Int = 120,
        maximumRequestsPerVersion: Int = 1,
        currentVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    ) {
        self.storageKeyPrefix = storageKeyPrefix
        self.minimumSignificantEvents = max(1, minimumSignificantEvents)
        self.minimumDaysSinceFirstSeen = max(0, minimumDaysSinceFirstSeen)
        self.minimumDaysBetweenRequests = max(0, minimumDaysBetweenRequests)
        self.maximumRequestsPerVersion = max(0, maximumRequestsPerVersion)
        self.currentVersion = currentVersion
    }
}

/// Records positive user outcomes and gates calls to Apple's review prompt APIs.
@MainActor
public final class CCAppReviewPrompter {

    public typealias DateProvider = @MainActor () -> Date

    private enum Key {
        static let firstSeenDate = "firstSeenDate"
        static let significantEventCount = "significantEventCount"
        static let lastRequestDate = "lastRequestDate"
        static let lastRequestVersion = "lastRequestVersion"
        static let currentVersionRequestCount = "currentVersionRequestCount"
    }

    private let configuration: CCAppReviewPromptConfiguration
    private let defaults: UserDefaults
    private let dateProvider: DateProvider

    public init(
        configuration: CCAppReviewPromptConfiguration = .init(),
        defaults: UserDefaults = .standard,
        dateProvider: @escaping DateProvider = { Date() }
    ) {
        self.configuration = configuration
        self.defaults = defaults
        self.dateProvider = dateProvider
        ensureFirstSeenDate()
        resetVersionCountIfNeeded()
    }

    /// Records a successful, user-visible outcome and invokes `requestReview` if all gates pass.
    public func recordSignificantEvent(weight: Int = 1, requestReview: () -> Void) {
        guard weight > 0 else { return }

        let eventCount = significantEventCount + weight
        defaults.set(eventCount, forKey: key(Key.significantEventCount))

        guard shouldRequestReview(significantEventCount: eventCount) else { return }

        defaults.set(dateProvider(), forKey: key(Key.lastRequestDate))
        defaults.set(configuration.currentVersion, forKey: key(Key.lastRequestVersion))
        defaults.set(currentVersionRequestCount + 1, forKey: key(Key.currentVersionRequestCount))
        requestReview()
    }

    /// Returns whether the current persisted state is eligible for a review request.
    public var isEligibleForReviewRequest: Bool {
        shouldRequestReview(significantEventCount: significantEventCount)
    }

    /// Clears persisted review-prompt state for this configuration prefix.
    public func reset() {
        for key in [
            Key.firstSeenDate,
            Key.significantEventCount,
            Key.lastRequestDate,
            Key.lastRequestVersion,
            Key.currentVersionRequestCount,
        ] {
            defaults.removeObject(forKey: self.key(key))
        }
        ensureFirstSeenDate()
    }

    private var significantEventCount: Int {
        defaults.integer(forKey: key(Key.significantEventCount))
    }

    private var currentVersionRequestCount: Int {
        defaults.integer(forKey: key(Key.currentVersionRequestCount))
    }

    private var firstSeenDate: Date {
        if let date = defaults.object(forKey: key(Key.firstSeenDate)) as? Date {
            return date
        }
        let date = dateProvider()
        defaults.set(date, forKey: key(Key.firstSeenDate))
        return date
    }

    private func shouldRequestReview(significantEventCount: Int) -> Bool {
        guard configuration.maximumRequestsPerVersion > 0 else { return false }
        guard significantEventCount >= configuration.minimumSignificantEvents else { return false }
        guard currentVersionRequestCount < configuration.maximumRequestsPerVersion else { return false }
        guard days(since: firstSeenDate) >= configuration.minimumDaysSinceFirstSeen else { return false }

        if let lastRequestDate = defaults.object(forKey: key(Key.lastRequestDate)) as? Date {
            guard days(since: lastRequestDate) >= configuration.minimumDaysBetweenRequests else { return false }
        }

        return true
    }

    private func ensureFirstSeenDate() {
        guard defaults.object(forKey: key(Key.firstSeenDate)) == nil else { return }
        defaults.set(dateProvider(), forKey: key(Key.firstSeenDate))
    }

    private func resetVersionCountIfNeeded() {
        let lastVersion = defaults.string(forKey: key(Key.lastRequestVersion))
        guard lastVersion != nil, lastVersion != configuration.currentVersion else { return }
        defaults.set(0, forKey: key(Key.currentVersionRequestCount))
    }

    private func days(since date: Date) -> Int {
        Calendar(identifier: .gregorian).dateComponents([.day], from: date, to: dateProvider()).day ?? 0
    }

    private func key(_ suffix: String) -> String {
        "\(configuration.storageKeyPrefix).\(suffix)"
    }
}
