import XCTest
@testable import CornucopiaSUI

final class VINIdentityTests: XCTestCase {

    func testCountryAndManufacturerForKnownWMIs() {
        let cases: [(vin: String, region: String, manufacturer: String)] = [
            ("WVWZZZ1KZ", "DE", "Volkswagen"),
            ("WAUZZZ", "DE", "Audi"),
            ("WBADT4", "DE", "BMW"),
            ("WDB123", "DE", "Mercedes-Benz"),
            ("1HGCM82633A123456", "US", "Honda"),
            ("1G1ZT5", "US", "Chevrolet"),
            ("JHMEG8", "JP", "Honda"),
            ("JF1GG", "JP", "Subaru"),
            ("KMHEM4", "KR", "Hyundai"),
            ("KNADM4", "KR", "Kia"),
            ("VF1AB", "FR", "Renault"),
            ("ZFA312", "IT", "Fiat"),
            ("SALGA2", "GB", "Land Rover"),
            ("YV1AB", "SE", "Volvo"),
            ("5YJSA1", "US", "Tesla"),
        ]

        for testCase in cases {
            let identity = VINIdentity.decoding(testCase.vin)
            XCTAssertEqual(identity?.regionCode, testCase.region, "region for \(testCase.vin)")
            XCTAssertEqual(identity?.manufacturer, testCase.manufacturer, "manufacturer for \(testCase.vin)")
        }
    }

    func testCountryKnownButManufacturerUnknown() {
        // A valid German WMI range with a WMI not present in the curated table.
        let identity = VINIdentity.decoding("WZZ999")
        XCTAssertEqual(identity?.regionCode, "DE")
        XCTAssertNil(identity?.manufacturer)
    }

    func testRequiresAtLeastTwoCharacters() {
        XCTAssertNil(VINIdentity.decoding(""))
        XCTAssertNil(VINIdentity.decoding("W"))
        XCTAssertNotNil(VINIdentity.decoding("WV"))
    }

    func testManufacturerResolvedOnlyWithThreeCharacters() {
        XCTAssertNil(VINIdentity.decoding("WV")?.manufacturer)
        XCTAssertEqual(VINIdentity.decoding("WVW")?.manufacturer, "Volkswagen")
    }

    func testRegionRangeBoundariesAndSplits() {
        // The "S" first character splits across several countries by second char.
        XCTAssertEqual(VINIdentity.decoding("SAX123")?.regionCode, "GB") // SA-SM
        XCTAssertEqual(VINIdentity.decoding("SUX123")?.regionCode, "PL") // SU-SZ
        XCTAssertEqual(VINIdentity.decoding("SNX123")?.regionCode, "DE") // SN-ST
    }

    func testInvalidCharactersAreStrippedBeforeLookup() {
        // Lowercase and separators are normalized; I/O/Q are removed.
        XCTAssertEqual(VINIdentity.decoding("wvw zzz")?.regionCode, "DE")
        XCTAssertEqual(VINIdentity.decoding("wvw zzz")?.manufacturer, "Volkswagen")
    }

    func testFlagDerivedFromRegionCode() {
        // Germany -> regional indicators for D and E.
        XCTAssertEqual(VINIdentity.decoding("WVWZZZ")?.flag, "🇩🇪")
        XCTAssertEqual(VINIdentity.decoding("1HGCM8")?.flag, "🇺🇸")
        XCTAssertEqual(VINIdentity.decoding("JHMEG8")?.flag, "🇯🇵")
    }

    func testUnknownRegionReturnsNil() {
        // "II" normalizes away (I is invalid); "0" is not a valid leading region.
        XCTAssertNil(VINIdentity.decoding("II"))
    }
}
