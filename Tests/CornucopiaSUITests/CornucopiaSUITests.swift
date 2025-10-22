import XCTest
@testable import CornucopiaSUI

final class MarqueeScrollViewLogicTests: XCTestCase {

    func testShouldAnimateRequiresContentExceedingThreshold() {
        XCTAssertFalse(MarqueeScrollLogic.shouldAnimate(contentWidth: 200, containerWidth: 199.5, threshold: 1))
        XCTAssertTrue(MarqueeScrollLogic.shouldAnimate(contentWidth: 220, containerWidth: 200, threshold: 1))
    }

    func testShouldAnimateHandlesZeroSizes() {
        XCTAssertFalse(MarqueeScrollLogic.shouldAnimate(contentWidth: 0, containerWidth: 200, threshold: 1))
        XCTAssertFalse(MarqueeScrollLogic.shouldAnimate(contentWidth: 150, containerWidth: 0, threshold: 1))
    }

    func testAnimationOffsetResetsEachCycle() {
        let calculator = MarqueeAnimationCalculator(cycleLength: 120, pointsPerSecond: 30, loopPause: 0.5)
        XCTAssertEqual(calculator.offset(for: 1), CGFloat(-15), accuracy: CGFloat(0.0001)) // elapsed accounts for pause
        XCTAssertEqual(calculator.offset(for: 4.5), CGFloat(0), accuracy: CGFloat(0.0001)) // travelDuration = 4.0, + pause
        XCTAssertEqual(calculator.offset(for: 5.5), CGFloat(-15), accuracy: CGFloat(0.0001))
    }

    func testAnimationOffsetStaysZeroBeforeMovement() {
        let calculator = MarqueeAnimationCalculator(cycleLength: 150, pointsPerSecond: 25, loopPause: 0.6)
        XCTAssertEqual(calculator.offset(for: 0), CGFloat(0), accuracy: CGFloat(0.0001))
        XCTAssertEqual(calculator.offset(for: -1), CGFloat(0), accuracy: CGFloat(0.0001))
    }

    func testAnimationHonorsPauseAtLoopStart() {
        let cycleLength: CGFloat = 100
        let speed: CGFloat = 20 // -> travelDuration = 5
        let pause: Double = 0.8
        let calculator = MarqueeAnimationCalculator(cycleLength: cycleLength, pointsPerSecond: speed, loopPause: pause)

        XCTAssertEqual(calculator.offset(for: 0.2), CGFloat(0), accuracy: CGFloat(0.0001))
        XCTAssertEqual(calculator.offset(for: pause - 0.1), CGFloat(0), accuracy: CGFloat(0.0001))

        let tickAfterPause = pause + 0.1
        let expectedOffset = -CGFloat(tickAfterPause - pause) * speed
        XCTAssertEqual(calculator.offset(for: tickAfterPause), expectedOffset, accuracy: CGFloat(0.0001))

        let fullCycle = pause + Double(cycleLength / speed)
        XCTAssertEqual(calculator.offset(for: fullCycle + 0.2), CGFloat(0), accuracy: CGFloat(0.0001))
    }
}
