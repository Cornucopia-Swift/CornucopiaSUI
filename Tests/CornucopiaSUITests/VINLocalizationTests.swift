import XCTest
@testable import CornucopiaSUI

/// Verifies the package ships working localization: English is the development value and
/// German resolves to the translations. Loads each `.lproj` directly (the `locale:`
/// argument of `String(localized:)` only affects formatting, not which table a bundle
/// picks), which also guards against the classic SwiftPM wrong-`.module`-bundle mistake.
final class VINLocalizationTests: XCTestCase {

    private func bundle(_ language: String) throws -> Bundle {
        let url = try XCTUnwrap(Bundle.module.url(forResource: language, withExtension: "lproj"),
                                "\(language).lproj missing from the package bundle")
        return try XCTUnwrap(Bundle(url: url))
    }

    func testEnglishResolves() throws {
        let en = try bundle("en")
        XCTAssertEqual(en.localizedString(forKey: "Clear VIN", value: "?", table: nil), "Clear VIN")
        XCTAssertEqual(en.localizedString(forKey: "Looking up…", value: "?", table: nil), "Looking up…")
    }

    func testGermanResolves() throws {
        let de = try bundle("de")
        // VIN keyboard
        XCTAssertEqual(de.localizedString(forKey: "Clear VIN", value: "?", table: nil), "FIN löschen")
        XCTAssertEqual(de.localizedString(forKey: "Scan VIN", value: "?", table: nil), "FIN scannen")
        XCTAssertEqual(de.localizedString(forKey: "No vehicle details", value: "?", table: nil), "Keine Fahrzeugdaten")
        XCTAssertEqual(de.localizedString(forKey: "VIN %@", value: "?", table: nil), "FIN %@")
        XCTAssertEqual(de.localizedString(forKey: "Valid VIN", value: "?", table: nil), "Gültige FIN")
        XCTAssertEqual(de.localizedString(forKey: "empty", value: "?", table: nil), "leer")
    }

    func testKeypadGermanResolves() throws {
        let de = try bundle("de")
        XCTAssertEqual(de.localizedString(forKey: "Hex payload", value: "?", table: nil), "Hex-Daten")
        XCTAssertEqual(de.localizedString(forKey: "Clear IPv4 address", value: "?", table: nil), "IPv4-Adresse löschen")
        XCTAssertEqual(de.localizedString(forKey: "Submit MAC address", value: "?", table: nil), "MAC-Adresse bestätigen")
        XCTAssertEqual(de.localizedString(forKey: "Delete", value: "?", table: nil), "Löschen")
    }
}
