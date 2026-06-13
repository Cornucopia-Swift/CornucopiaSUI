import XCTest
@testable import CornucopiaSUI

@MainActor
final class CCAppReviewPrompterTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var now: Date!

    override func setUp() {
        super.setUp()
        suiteName = "CCAppReviewPrompterTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        now = Date(timeIntervalSince1970: 1_800_000_000)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        now = nil
        super.tearDown()
    }

    func testWaitsForEnoughEventsAndInstallAge() {
        var requestCount = 0
        let prompter = makePrompter(minimumSignificantEvents: 3, minimumDaysSinceFirstSeen: 2)

        prompter.recordSignificantEvent { requestCount += 1 }
        prompter.recordSignificantEvent { requestCount += 1 }
        XCTAssertEqual(requestCount, 0)

        now = now.addingTimeInterval(2 * 24 * 60 * 60)
        prompter.recordSignificantEvent { requestCount += 1 }

        XCTAssertEqual(requestCount, 1)
    }

    func testRequestsOnlyOncePerVersionByDefault() {
        var requestCount = 0
        let prompter = makePrompter(minimumSignificantEvents: 1, minimumDaysSinceFirstSeen: 0)

        prompter.recordSignificantEvent { requestCount += 1 }
        now = now.addingTimeInterval(365 * 24 * 60 * 60)
        prompter.recordSignificantEvent { requestCount += 1 }

        XCTAssertEqual(requestCount, 1)
    }

    func testHonorsMinimumDaysBetweenRequestsAcrossVersions() {
        var requestCount = 0
        let firstVersion = makePrompter(
            minimumSignificantEvents: 1,
            minimumDaysSinceFirstSeen: 0,
            minimumDaysBetweenRequests: 30,
            currentVersion: "1.0"
        )
        firstVersion.recordSignificantEvent { requestCount += 1 }

        now = now.addingTimeInterval(10 * 24 * 60 * 60)
        let secondVersionTooSoon = makePrompter(
            minimumSignificantEvents: 1,
            minimumDaysSinceFirstSeen: 0,
            minimumDaysBetweenRequests: 30,
            currentVersion: "1.1"
        )
        secondVersionTooSoon.recordSignificantEvent { requestCount += 1 }
        XCTAssertEqual(requestCount, 1)

        now = now.addingTimeInterval(21 * 24 * 60 * 60)
        let secondVersionEligible = makePrompter(
            minimumSignificantEvents: 1,
            minimumDaysSinceFirstSeen: 0,
            minimumDaysBetweenRequests: 30,
            currentVersion: "1.1"
        )
        secondVersionEligible.recordSignificantEvent { requestCount += 1 }
        XCTAssertEqual(requestCount, 2)
    }

    func testResetClearsPromptState() {
        var requestCount = 0
        let prompter = makePrompter(minimumSignificantEvents: 1, minimumDaysSinceFirstSeen: 0)

        prompter.recordSignificantEvent { requestCount += 1 }
        prompter.reset()
        prompter.recordSignificantEvent { requestCount += 1 }

        XCTAssertEqual(requestCount, 2)
    }

    private func makePrompter(
        minimumSignificantEvents: Int,
        minimumDaysSinceFirstSeen: Int,
        minimumDaysBetweenRequests: Int = 120,
        currentVersion: String = "1.0"
    ) -> CCAppReviewPrompter {
        CCAppReviewPrompter(
            configuration: CCAppReviewPromptConfiguration(
                storageKeyPrefix: "test.review",
                minimumSignificantEvents: minimumSignificantEvents,
                minimumDaysSinceFirstSeen: minimumDaysSinceFirstSeen,
                minimumDaysBetweenRequests: minimumDaysBetweenRequests,
                currentVersion: currentVersion
            ),
            defaults: defaults,
            dateProvider: { self.now }
        )
    }
}
