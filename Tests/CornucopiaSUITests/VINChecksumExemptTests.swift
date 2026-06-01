import XCTest
@testable import CornucopiaSUI
import VIN

/// Many Asian (and other non-North-American) markets issue structurally valid
/// VINs that do not satisfy the ISO 3779 check-digit algorithm. These must be
/// treated as usable — surfaced as a *warning*, never rejected. This guards the
/// data structures the VIN UI components render from against that case.
final class VINChecksumExemptTests: XCTestCase {

    /// Real-world Asian VINs that are syntactically valid but whose position-9
    /// digit does not match the computed checksum (verified offline).
    private let checksumExemptVINs: [(vin: String, region: String, makeContains: String)] = [
        ("JN1TFNT32A0041590", "JP", "Nissan"),
        ("JF1GD70566L512345", "JP", "Subaru"),
        ("JTDKB20U893519073", "JP", "Toyota"),
        ("KMHWF35H66A023847", "KR", "Hyundai"),
        ("KNADN4A33A6123456", "KR", "Kia"),
        ("JM1BK32F581808742", "JP", "Mazda"),
    ]

    /// The `VIN` model reports these as syntactically valid, checksum-invalid,
    /// and still decodes region / manufacturer / model year.
    func testVINModelTreatsThemAsValidWithoutChecksum() {
        for (string, region, make) in checksumExemptVINs {
            let vin = VIN(content: string)
            XCTAssertEqual(vin.validity, .valid, "\(string) should be syntactically valid")
            XCTAssertTrue(vin.isValid, "\(string) should be valid")
            XCTAssertFalse(vin.isChecksumValid, "\(string) should fail the checksum")
            XCTAssertEqual(vin.regionCode, region, "\(string) region")
            XCTAssertEqual(vin.manufacturer, make, "\(string) manufacturer")
            XCTAssertNotNil(vin.modelYear, "\(string) model year")
            XCTAssertNotNil(vin.expectedCheckDigit, "\(string) expected check digit computable")
            XCTAssertNotEqual(vin.actualCheckDigit, vin.expectedCheckDigit, "\(string) digits differ")
        }
    }

    /// `validateVIN` (the state machine the GUI renders from) surfaces them as
    /// `.validWithCheckDigitWarning` with fully populated components — not as
    /// `.invalidCharacters` or any rejecting state.
    func testValidationStateIsCheckDigitWarning() {
        for (string, _, _) in checksumExemptVINs {
            guard case let .validWithCheckDigitWarning(text, components, expected) = validateVIN(string) else {
                XCTFail("\(string) should be .validWithCheckDigitWarning, got \(validateVIN(string))")
                continue
            }
            XCTAssertEqual(text, string)
            XCTAssertEqual(components.wmi, String(string.prefix(3)))
            XCTAssertEqual(components.vds.count, 6)
            XCTAssertEqual(components.vis.count, 8)
            XCTAssertNotNil(components.modelYear, "\(string) model year for the components display")
            XCTAssertTrue(expected.isHexDigit || expected == "X", "\(string) expected digit is a real value, not '?'")
        }
    }

    /// The identity preview (`VINIdentity`) the keyboard shows resolves country,
    /// flag, and manufacturer for these VINs.
    func testIdentityPreviewResolves() {
        for (string, region, make) in checksumExemptVINs {
            let identity = VINIdentity.decoding(string)
            XCTAssertNotNil(identity, "\(string) should decode an identity")
            XCTAssertEqual(identity?.regionCode, region)
            XCTAssertEqual(identity?.manufacturer, make)
            XCTAssertFalse(identity?.flag.isEmpty ?? true, "\(string) should have a flag")
            XCTAssertFalse(identity?.countryName.isEmpty ?? true, "\(string) should have a country name")
        }
    }
}
