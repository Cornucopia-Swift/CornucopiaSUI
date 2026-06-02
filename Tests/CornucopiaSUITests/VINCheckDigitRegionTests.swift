import XCTest
@testable import CornucopiaSUI

/// The 9th VIN position is a mandatory ISO 3779 check digit only for North American
/// VINs (first character `1`–`5`). Non–North-American VINs — e.g. the VW `WVWZZZ3DZ…`
/// family, which carries a `Z` filler there — must not have that position gated to
/// digits/`X` by the keypad, otherwise they cannot be entered at all.
///
/// The region rule itself is owned and exercised by the `VIN` package
/// (`VIN.requiresCheckDigit`); these cover the downstream contract the keypad relies on:
/// the SwiftUI adapter delegates correctly and the camera path accepts the VW VIN.
final class VINCheckDigitRegionTests: XCTestCase {

    func testNorthAmericanVINsRequireCheckDigit() {
        for vin in ["1HGCM82633A004352", "2C4RDGEG3JR225345", "5YJ3E1EA7JF005252"] {
            XCTAssertTrue(vinRequiresCheckDigit(vin), "\(vin) is North American")
        }
    }

    func testNonNorthAmericanVINsDoNotRequireCheckDigit() {
        for vin in ["WVWZZZ3DZ88005052", "WBA3A5C50CF256736", "JTDKB20U893519073", "KMHWF35H66A023847"] {
            XCTAssertFalse(vinRequiresCheckDigit(vin), "\(vin) is not North American")
        }
    }

    func testEmptyDoesNotRequireCheckDigit() {
        XCTAssertFalse(vinRequiresCheckDigit(""))
    }

    /// The camera path already accepts the VW VIN: a `Z` at position 9 only trips the
    /// soft check-digit warning, which `isCompleteScannedVIN` treats as usable.
    func testVWVINIsAcceptedByScanner() {
        XCTAssertEqual(
            VINKeyboardInput.scannedVINCandidate(in: "FIN: WVWZZZ3DZ88005052"),
            "WVWZZZ3DZ88005052"
        )
    }
}
