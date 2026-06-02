import XCTest
@testable import CornucopiaSUI

final class VINScannerTests: XCTestCase {

    func testFindsVINInDashboardLabelText() {
        XCTAssertEqual(
            VINKeyboardInput.scannedVINCandidate(in: "VIN: 1HGCM82633A004352"),
            "1HGCM82633A004352"
        )
    }

    func testFindsVINWithDocumentSpacing() {
        XCTAssertEqual(
            VINKeyboardInput.scannedVINCandidate(in: "Fahrzeug-Identifizierungsnummer WVW ZZZ 1KZ 9W 000001"),
            "WVWZZZ1KZ9W000001"
        )
    }

    func testRejectsIncompleteCandidate() {
        XCTAssertNil(VINKeyboardInput.scannedVINCandidate(in: "VIN 1HGCM82633A00435"))
    }

    func testRejectsInvalidVINCharacters() {
        XCTAssertNil(VINKeyboardInput.scannedVINCandidate(in: "VIN 1HGCM82633A00I352"))
    }

    func testRejectsKnownWMIWithoutEnoughDigits() {
        XCTAssertNil(VINKeyboardInput.scannedVINCandidate(in: "WVWZZZABCDEFGHJK"))
    }

    func testRejectsUnknownWMI() {
        XCTAssertNil(VINKeyboardInput.scannedVINCandidate(in: "ABC12345678901234"))
    }
}
