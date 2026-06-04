import XCTest
@testable import CornucopiaSUI

/// Verifies the package ships a working localization bundle: English is the
/// development value and German resolves to the FIN-based translations. Loads each
/// `.lproj` directly (the `locale:` argument of `String(localized:)` only affects
/// formatting, not which table a bundle picks), which also guards against the strings
/// being shipped in the wrong bundle — the classic SwiftPM `.module` mistake.
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
        XCTAssertEqual(de.localizedString(forKey: "Clear VIN", value: "?", table: nil), "FIN löschen")
        XCTAssertEqual(de.localizedString(forKey: "Scan VIN", value: "?", table: nil), "FIN scannen")
        XCTAssertEqual(de.localizedString(forKey: "No vehicle details", value: "?", table: nil), "Keine Fahrzeugdaten")
        XCTAssertEqual(de.localizedString(forKey: "VIN %@", value: "?", table: nil), "FIN %@")
        // VoiceOver announcement strings
        XCTAssertEqual(de.localizedString(forKey: "VIN", value: "?", table: nil), "FIN")
        XCTAssertEqual(de.localizedString(forKey: "Valid VIN", value: "?", table: nil), "Gültige FIN")
        XCTAssertEqual(de.localizedString(forKey: "empty", value: "?", table: nil), "leer")
    }
}
