import XCTest
@testable import CornucopiaSUI

/// Pure-logic coverage for the Hex / IPv4 / MAC keypad normalizers, formatters and
/// validators — the domain rules these widgets enforce at input time. These were the
/// only keypads without tests; the parsers are public contract surface.
final class InputMethodNormalizerTests: XCTestCase {

    // MARK: Hex

    func testNormalizedHex() {
        XCTAssertEqual(HexKeyboardInput.normalizedHex("0xDEAD"), "DEAD")
        XCTAssertEqual(HexKeyboardInput.normalizedHex("de ad be ef"), "DEADBEEF")
        XCTAssertEqual(HexKeyboardInput.normalizedHex("g1h2"), "12")           // non-hex letters dropped
        XCTAssertEqual(HexKeyboardInput.normalizedHex("0Xab"), "AB")           // 0x prefix is case-insensitive
    }

    func testHexByteArray() {
        XCTAssertEqual(HexKeyboardInput.byteArray(from: "DEAD"), [0xDE, 0xAD])
        XCTAssertEqual(HexKeyboardInput.byteArray(from: "DE AD, BE"), [0xDE, 0xAD, 0xBE]) // space/comma separators
        XCTAssertNil(HexKeyboardInput.byteArray(from: "DEA"))                  // odd nibble count rejected by default
        XCTAssertEqual(HexKeyboardInput.byteArray(from: "DEA", requiresEvenNibbleCount: false), [0x0D, 0xEA])
        XCTAssertNil(HexKeyboardInput.byteArray(from: "XY"))                   // invalid characters
        XCTAssertNil(HexKeyboardInput.byteArray(from: ""))
    }

    func testGroupedHexBytes() {
        XCTAssertEqual(HexKeyboardInput.groupedHexBytes("DEADBE"), ["DE", "AD", "BE"])
        XCTAssertEqual(HexKeyboardInput.groupedHexBytes("DEAD1"), ["DE", "AD", "1"])
    }

    // MARK: IPv4

    func testNormalizedIPv4Draft() {
        XCTAssertEqual(IPv4KeyboardInput.normalizedIPv4Draft("192.168.0.1"), "192.168.0.1")
        XCTAssertEqual(IPv4KeyboardInput.normalizedIPv4Draft("192.168.0.1.5"), "192.168.0.1") // max four octets
        XCTAssertEqual(IPv4KeyboardInput.normalizedIPv4Draft("1234.56.7"), "123.56.7")        // max three digits/octet
        XCTAssertEqual(IPv4KeyboardInput.normalizedIPv4Draft("10a.0b.0.1"), "10.0.0.1")        // non-digits dropped
        XCTAssertEqual(IPv4KeyboardInput.normalizedIPv4Draft("abc"), "")
    }

    func testIsIPv4() {
        XCTAssertTrue(isIPv4("192.168.0.1"))
        XCTAssertTrue(isIPv4("0.0.0.0"))
        XCTAssertFalse(isIPv4("256.1.1.1"))   // octet > 255
        XCTAssertFalse(isIPv4("1.2.3"))       // too few octets
        XCTAssertFalse(isIPv4("01.2.3.4"))    // leading zero
        XCTAssertFalse(isIPv4(""))
    }

    // MARK: MAC

    func testNormalizedMACHex() {
        XCTAssertEqual(MACKeyboardInput.normalizedMACHex("de:ad:be:ef:00:11"), "DEADBEEF0011")
        XCTAssertEqual(MACKeyboardInput.normalizedMACHex("DE-AD-BE-EF-00-11-22-33"), "DEADBEEF0011") // capped at 12 nibbles
        XCTAssertEqual(MACKeyboardInput.normalizedMACHex("zz"), "")
    }

    func testFormattedMAC() {
        XCTAssertEqual(MACKeyboardInput.formattedMAC("deadbeef0011", separatorStyle: .colon), "DE:AD:BE:EF:00:11")
        XCTAssertEqual(MACKeyboardInput.formattedMAC("deadbeef0011", separatorStyle: .dash), "DE-AD-BE-EF-00-11")
        XCTAssertEqual(MACKeyboardInput.formattedMAC("deadbeef0011", separatorStyle: .dot), "DEAD.BEEF.0011")
        XCTAssertEqual(MACKeyboardInput.formattedMAC("deadbeef0011", separatorStyle: .compact), "DEADBEEF0011")
    }
}
