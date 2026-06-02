import XCTest
@testable import CornucopiaSUI

final class TextFieldStepperTests: XCTestCase {

    func testDisplayTextAppendsUnitAndHonorsFractionConfiguration() {
        let configuration = TextFieldStepperConfiguration(
            unit: "V",
            minimumFractionDigits: 1,
            maximumFractionDigits: 2
        )
        let decimalSeparator = Locale.current.decimalSeparator ?? "."

        XCTAssertEqual(
            TextFieldStepperValueFormatter.displayText(for: 12.345, configuration: configuration),
            "12\(decimalSeparator)34\u{202F}V"
        )
        XCTAssertEqual(
            TextFieldStepperValueFormatter.displayText(for: 12, configuration: configuration),
            "12\(decimalSeparator)0\u{202F}V"
        )
    }

    func testResolvedValueStripsUnitAndClampsToRange() {
        let configuration = TextFieldStepperConfiguration(
            unit: "ms",
            range: 50...2_000,
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        )

        XCTAssertEqual(
            TextFieldStepperValueFormatter.resolvedValue(from: "250\u{202F}ms", fallback: 100, configuration: configuration),
            250
        )
        XCTAssertEqual(
            TextFieldStepperValueFormatter.resolvedValue(from: "5000ms", fallback: 100, configuration: configuration),
            2_000
        )
        XCTAssertEqual(
            TextFieldStepperValueFormatter.resolvedValue(from: "10ms", fallback: 100, configuration: configuration),
            50
        )
    }

    func testResolvedValueUsesFallbackForInvalidInput() {
        let configuration = TextFieldStepperConfiguration(
            unit: "%",
            range: 0...100
        )

        XCTAssertEqual(
            TextFieldStepperValueFormatter.resolvedValue(from: "abc", fallback: 42, configuration: configuration),
            42
        )
    }

    func testResolvedValueAcceptsCommaDecimalSeparators() {
        let configuration = TextFieldStepperConfiguration(
            unit: "°C",
            range: -20...60,
            minimumFractionDigits: 1,
            maximumFractionDigits: 1
        )

        XCTAssertEqual(
            TextFieldStepperValueFormatter.resolvedValue(from: "21,5°C", fallback: 0, configuration: configuration),
            21.5
        )
    }
}
