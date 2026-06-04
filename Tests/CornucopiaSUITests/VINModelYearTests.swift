import XCTest
@testable import CornucopiaSUI

/// The offline model-year preview must disambiguate the 30-year cycle via position 7
/// (so the keyboard shows e.g. 1991, not 2021, for the canonical sample VIN).
final class VINModelYearTests: XCTestCase {
    func testFullVINDisambiguates() {
        XCTAssertEqual(VINTextField.modelYear(for: "1HGBH41JXMN109186"), "1991") // digit pos7
        XCTAssertEqual(VINTextField.modelYear(for: "1HGCM82633A004352"), "2003") // digit pos7
        XCTAssertEqual(VINTextField.modelYear(for: "5YJ3E1EA7JF005252"), "2018") // letter pos7
        XCTAssertEqual(VINTextField.modelYear(for: "WBA3A5C50CF256736"), "2012") // letter pos7
    }
}
