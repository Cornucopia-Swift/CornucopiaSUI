//
//  VINIdentity.swift
//  CornucopiaSUI
//

import Foundation
import VIN

/// Standardized identity information derived from a VIN's World Manufacturer
/// Identifier (positions 1–3) per ISO 3779/3780.
///
/// This is a thin SwiftUI-facing wrapper over the `VIN` package: the region and
/// manufacturer come from `VIN`, while the country name (via `Locale`) and the
/// flag emoji are derived from the ISO region code.
public struct VINIdentity: Equatable, Sendable {

    /// ISO 3166-1 alpha-2 region code of the manufacturer's country.
    public let regionCode: String

    /// Manufacturer name for the WMI, or `nil` when the WMI is not in the
    /// directory (the country is still known from the region code).
    public let manufacturer: String?

    public init(regionCode: String, manufacturer: String?) {
        self.regionCode = regionCode
        self.manufacturer = manufacturer
    }

    /// Localized country name for the region code, falling back to the raw code.
    public var countryName: String {
        Locale.current.localizedString(forRegionCode: regionCode) ?? regionCode
    }

    /// Flag emoji built from the region code's regional indicator symbols.
    public var flag: String {
        regionCode.uppercased().unicodeScalars.reduce(into: "") { result, scalar in
            guard scalar.value >= 0x41, scalar.value <= 0x5A,
                  let indicator = Unicode.Scalar(0x1F1E6 + scalar.value - 0x41) else { return }
            result.unicodeScalars.append(indicator)
        }
    }

    /// Decodes the country and (when known) the manufacturer from a VIN prefix.
    ///
    /// At least two valid characters are required to identify a country; the
    /// manufacturer is resolved once three characters are present.
    public static func decoding(_ vin: String) -> VINIdentity? {
        let normalized = String(vin.uppercased().filter(isValidVINCharacter).prefix(17))
        let model = VIN(content: normalized)
        guard let regionCode = model.regionCode else { return nil }
        let manufacturer = normalized.count >= 3 ? model.manufacturer : nil
        return VINIdentity(regionCode: regionCode, manufacturer: manufacturer)
    }
}
