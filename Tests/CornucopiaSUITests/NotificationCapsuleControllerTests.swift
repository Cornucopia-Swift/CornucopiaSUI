import XCTest
@testable import CornucopiaSUI

final class NotificationCapsuleControllerTests: XCTestCase {

    @MainActor
    func testRichMessagesQueueUntilDismissed() async {
        let controller = NotificationCapsuleController(delayBetweenNotifications: 0)

        controller.show(NotificationCapsuleMessage(title: "First", duration: .persistent))
        controller.show(NotificationCapsuleMessage(title: "Second", duration: .persistent))

        XCTAssertEqual(controller.currentItem?.message.title, "First")

        controller.dismiss()
        await Task.yield()

        XCTAssertEqual(controller.currentItem?.message.title, "Second")
    }

    @MainActor
    func testLegacyActivityDefaultIsPersistent() {
        let controller = NotificationCapsuleController(delayBetweenNotifications: 0)

        controller.show("Loading", style: .activity)

        XCTAssertEqual(controller.currentItem?.message.duration, .persistent)
    }

    @MainActor
    func testReplaceCurrentClearsQueuedMessages() async {
        let controller = NotificationCapsuleController(delayBetweenNotifications: 0)

        controller.show(NotificationCapsuleMessage(title: "Queued", duration: .persistent))
        controller.show(NotificationCapsuleMessage(title: "Waiting", duration: .persistent))
        controller.show(NotificationCapsuleMessage(title: "Replacement", duration: .persistent), presentation: .replaceCurrent)

        XCTAssertEqual(controller.currentItem?.message.title, "Replacement")

        controller.dismiss()
        await Task.yield()

        XCTAssertNil(controller.currentItem)
    }

    func testMessageTrimsEmptySubtitle() {
        let message = NotificationCapsuleMessage(title: "  Saved  ", subtitle: "   ")

        XCTAssertEqual(message.title, "Saved")
        XCTAssertNil(message.subtitle)
        XCTAssertEqual(message.resolvedAccessibilityMessage, "Saved")
    }
}
