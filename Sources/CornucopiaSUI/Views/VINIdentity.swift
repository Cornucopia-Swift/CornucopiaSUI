//
//  VINIdentity.swift
//  CornucopiaSUI
//

import Foundation

/// Standardized identity information derived from a VIN's World Manufacturer
/// Identifier (positions 1–3) per ISO 3779/3780.
///
/// The country is keyed by the first one or two WMI characters (a geographic
/// region range), the manufacturer by the full three-character WMI. Country
/// names are resolved through `Locale` so they localize automatically, and the
/// flag is derived from the region code, so only ISO country codes and the
/// manufacturer table need to be maintained here.
public struct VINIdentity: Equatable, Sendable {

    /// ISO 3166-1 alpha-2 region code of the manufacturer's country.
    public let regionCode: String

    /// Manufacturer name for the full WMI, or `nil` when the WMI is not in the
    /// curated directory (the country is still known from the region range).
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
    /// At least two valid characters are required to identify a country, since a
    /// single leading character is ambiguous for several regions. The
    /// manufacturer is resolved once three characters are present.
    public static func decoding(_ vin: String) -> VINIdentity? {
        let normalized = String(vin.uppercased().filter(isValidVINCharacter).prefix(17))
        guard normalized.count >= 2 else { return nil }

        let characters = Array(normalized)
        guard let regionCode = vinRegionCode(forPrefix: String(characters[0...1])) else { return nil }

        let manufacturer = normalized.count >= 3 ? manufacturerName(forWMI: String(characters[0...2])) : nil
        return VINIdentity(regionCode: regionCode, manufacturer: manufacturer)
    }
}

// MARK: - Region (country) lookup

/// VIN character collation used by ISO 3780 region ranges: letters (excluding
/// I, O, Q) first, then digits 1–9 and finally 0.
private let vinCharacterOrder = "ABCDEFGHJKLMNPRSTUVWXYZ1234567890"

private func vinRank(_ prefix: String) -> Int? {
    let characters = Array(prefix.prefix(2))
    guard characters.count == 2,
          let first = vinCharacterOrder.firstIndex(of: characters[0]),
          let second = vinCharacterOrder.firstIndex(of: characters[1]) else { return nil }
    let firstRank = vinCharacterOrder.distance(from: vinCharacterOrder.startIndex, to: first)
    let secondRank = vinCharacterOrder.distance(from: vinCharacterOrder.startIndex, to: second)
    return firstRank * 100 + secondRank
}

private func vinRegionCode(forPrefix prefix: String) -> String? {
    guard let rank = vinRank(prefix) else { return nil }
    return vinRegionRanges.first { rank >= $0.low && rank <= $0.high }?.regionCode
}

private struct VINRegionRange {
    let low: Int
    let high: Int
    let regionCode: String

    init(_ low: String, _ high: String, _ regionCode: String) {
        self.low = vinRank(low) ?? 0
        self.high = vinRank(high) ?? 0
        self.regionCode = regionCode
    }
}

/// First/second WMI character ranges mapped to ISO 3166-1 alpha-2 codes,
/// following the ISO 3780 Annex A geographic allocation. Whole-letter regions
/// span `xA`…`x0`; single-point assignments use identical bounds.
private let vinRegionRanges: [VINRegionRange] = [
    // Africa
    .init("AA", "AH", "ZA"), .init("AJ", "AK", "CI"), .init("AL", "AM", "LS"),
    .init("AN", "AP", "BW"), .init("AR", "AS", "NA"), .init("AT", "AU", "MG"),
    .init("AV", "AW", "MU"), .init("AX", "AY", "TN"), .init("AZ", "A1", "CY"),
    .init("A2", "A3", "ZW"), .init("A4", "A5", "MZ"),
    .init("BA", "BB", "AO"), .init("BC", "BC", "ET"), .init("BF", "BG", "KE"),
    .init("BH", "BH", "RW"), .init("BL", "BL", "NG"), .init("BR", "BR", "DZ"),
    .init("BT", "BT", "SZ"), .init("BU", "BU", "UG"), .init("B3", "B4", "LY"),
    .init("CA", "CB", "EG"), .init("CF", "CG", "MA"), .init("CL", "CM", "ZM"),
    // Asia
    .init("HA", "H0", "CN"),
    .init("JA", "J0", "JP"),
    .init("KF", "KH", "IL"), .init("KL", "KR", "KR"), .init("KS", "KT", "JO"),
    .init("K1", "K3", "KR"), .init("K5", "K5", "KG"),
    .init("LA", "L0", "CN"),
    .init("MA", "ME", "IN"), .init("MF", "MK", "ID"), .init("ML", "MR", "TH"),
    .init("MS", "MS", "MM"), .init("MU", "MU", "MN"), .init("MX", "MX", "KZ"),
    .init("MY", "M0", "IN"),
    .init("NA", "NE", "IR"), .init("NF", "NG", "PK"), .init("NJ", "NJ", "IQ"),
    .init("NL", "NR", "TR"), .init("NS", "NT", "UZ"), .init("NV", "NV", "AZ"),
    .init("NX", "NX", "TJ"), .init("NY", "NY", "AM"), .init("N1", "N5", "IR"),
    .init("N7", "N8", "TR"),
    .init("PA", "PC", "PH"), .init("PF", "PG", "SG"), .init("PL", "PR", "MY"),
    .init("PS", "PT", "BD"), .init("PV", "PV", "KH"), .init("P5", "P0", "IN"),
    .init("RA", "RB", "AE"), .init("RF", "RK", "TW"), .init("RL", "RN", "VN"),
    .init("RP", "RP", "LA"), .init("RS", "RT", "SA"), .init("R1", "R7", "HK"),
    // Europe
    .init("EA", "E0", "RU"),
    .init("SA", "SM", "GB"), .init("SN", "ST", "DE"), .init("SU", "SZ", "PL"),
    .init("S1", "S2", "LV"), .init("S3", "S3", "GE"), .init("S4", "S4", "IS"),
    .init("TA", "TH", "CH"), .init("TJ", "TP", "CZ"), .init("TR", "TV", "HU"),
    .init("TW", "T2", "PT"), .init("T3", "T5", "RS"), .init("T6", "T6", "AD"),
    .init("T7", "T8", "NL"),
    .init("UA", "UC", "ES"), .init("UH", "UM", "DK"), .init("UN", "UR", "IE"),
    .init("UU", "UX", "RO"), .init("U1", "U2", "MK"), .init("U5", "U7", "SK"),
    .init("U8", "U0", "BA"),
    .init("VA", "VE", "AT"), .init("VF", "VR", "FR"), .init("VS", "VW", "ES"),
    .init("VX", "V2", "FR"), .init("V3", "V5", "HR"), .init("V6", "V8", "EE"),
    .init("WA", "W0", "DE"),
    .init("XA", "XC", "BG"), .init("XD", "XE", "RU"), .init("XF", "XH", "GR"),
    .init("XJ", "XK", "RU"), .init("XL", "XR", "NL"), .init("XS", "XW", "RU"),
    .init("XX", "XY", "LU"), .init("XZ", "X1", "RU"),
    .init("YA", "YE", "BE"), .init("YF", "YK", "FI"), .init("YN", "YN", "MT"),
    .init("YS", "YW", "SE"), .init("YX", "Y2", "NO"), .init("Y3", "Y5", "BY"),
    .init("Y6", "Y9", "UA"),
    .init("ZA", "ZU", "IT"), .init("ZX", "ZZ", "SI"), .init("Z1", "Z1", "SM"),
    .init("Z3", "Z5", "LT"), .init("Z6", "Z0", "RU"),
    // North America
    .init("1A", "10", "US"), .init("2A", "20", "CA"),
    .init("3A", "3X", "MX"), .init("34", "34", "NI"), .init("35", "35", "DO"),
    .init("36", "36", "HN"), .init("37", "37", "PA"), .init("38", "39", "PR"),
    .init("4A", "40", "US"), .init("5A", "50", "US"), .init("7A", "70", "US"),
    // Oceania
    .init("6A", "6X", "AU"), .init("6Y", "61", "NZ"),
    // South America
    .init("8A", "8E", "AR"), .init("8F", "8G", "CL"), .init("8L", "8N", "EC"),
    .init("8S", "8W", "PE"), .init("8X", "8Z", "VE"), .init("82", "82", "BO"),
    .init("84", "84", "CR"),
    .init("9A", "9E", "BR"), .init("9F", "9G", "CO"), .init("9S", "9V", "UY"),
    .init("91", "90", "BR"),
]

// MARK: - Manufacturer lookup

private func manufacturerName(forWMI wmi: String) -> String? {
    vinManufacturers[String(wmi.prefix(3))]
}

/// Curated directory of common three-character WMIs mapped to manufacturer
/// names (passenger cars and major commercial brands). Names are kept as
/// proper nouns and are intentionally not localized.
private let vinManufacturers: [String: String] = [
    // Volkswagen Group
    "WVW": "Volkswagen", "WVG": "Volkswagen", "WV1": "Volkswagen Commercial",
    "WV2": "Volkswagen Commercial", "WV3": "Volkswagen Commercial",
    "1VW": "Volkswagen", "3VW": "Volkswagen", "9BW": "Volkswagen", "WVE": "Volkswagen Commercial",
    "WAU": "Audi", "WA1": "Audi", "WUA": "Audi Sport", "TRU": "Audi",
    "WP0": "Porsche", "WP1": "Porsche",
    "VSS": "SEAT", "TMB": "Škoda", "WAG": "Neoplan",
    // BMW
    "WBA": "BMW", "WBS": "BMW M", "WBX": "BMW", "WBY": "BMW i", "WB5": "BMW",
    "WB1": "BMW Motorrad", "4US": "BMW", "5UX": "BMW", "5YM": "BMW",
    "WMW": "MINI", "WMZ": "MINI",
    // Mercedes-Benz / Daimler
    "WDB": "Mercedes-Benz", "WDD": "Mercedes-Benz", "WDC": "Mercedes-Benz",
    "WDF": "Mercedes-Benz", "W1K": "Mercedes-Benz", "W1N": "Mercedes-Benz",
    "W1V": "Mercedes-Benz", "4JG": "Mercedes-Benz", "WME": "smart",
    "W1A": "smart", "WEB": "Mercedes-Benz (EvoBus)", "WMA": "MAN",
    // Opel / Ford Europe
    "W0L": "Opel", "W0V": "Opel", "WF0": "Ford", "WF1": "Ford",
    "VXK": "Opel", "VXE": "Opel",
    // Other German
    "WS5": "StreetScooter", "WS7": "Sono Motors", "WNA": "Next.e.GO",
    "WEL": "e.GO Mobile", "WKK": "Setra", "WJM": "Iveco Magirus",
    // France
    "VF1": "Renault", "VF2": "Renault Trucks", "VF3": "Peugeot",
    "VF7": "Citroën", "VF8": "Matra", "VR1": "DS Automobiles",
    "VR3": "Peugeot", "VR7": "Citroën", "VFA": "Alpine", "VNK": "Toyota",
    "VNV": "Nissan", "VN1": "Renault", "VLU": "Scania", "VF6": "Renault Trucks",
    // Italy
    "ZFA": "Fiat", "ZFB": "Fiat", "ZFC": "Fiat", "ZFF": "Ferrari",
    "ZHW": "Lamborghini", "ZPB": "Lamborghini", "ZAM": "Maserati",
    "ZN6": "Maserati", "ZAR": "Alfa Romeo", "ZAA": "Alfa Romeo",
    "ZLA": "Lancia", "ZCF": "Iveco", "ZGA": "Iveco", "ZDM": "Ducati",
    "ZD3": "Beta", "ZD4": "Aprilia", "ZGU": "Moto Guzzi", "ZFR": "Pininfarina",
    // United Kingdom
    "SAL": "Land Rover", "SAJ": "Jaguar", "SAD": "Jaguar", "SCA": "Rolls-Royce",
    "SLA": "Rolls-Royce", "SCB": "Bentley", "SJA": "Bentley", "SCC": "Lotus",
    "SCF": "Aston Martin", "SBM": "McLaren", "SDP": "MG", "SFA": "Ford",
    "SHH": "Honda", "SHS": "Honda", "SJN": "Nissan", "SKA": "Vauxhall",
    "SFZ": "Tesla (Lotus)", "SMT": "Triumph",
    // Sweden
    "YV1": "Volvo", "YV4": "Volvo", "YV2": "Volvo Trucks", "YV3": "Volvo Buses",
    "YS2": "Scania", "YS3": "Saab", "YSR": "Polestar", "YSC": "Cadillac (Saab)",
    "YTN": "Saab (NEVS)",
    // Spain
    "VSK": "Nissan", "VSA": "Mercedes-Benz", "VSE": "Santana", "VSX": "Opel",
    "VS6": "Ford", "VS7": "Citroën", "VS8": "Peugeot", "VWV": "Volkswagen",
    // Japan
    "JHM": "Honda", "JH1": "Honda", "JH2": "Honda", "JF1": "Subaru",
    "JM1": "Mazda", "JMZ": "Mazda", "JMA": "Mitsubishi", "JA3": "Mitsubishi",
    "JN1": "Nissan", "JNK": "Infiniti", "JTD": "Toyota", "JT1": "Toyota",
    "JT2": "Toyota", "JT3": "Toyota", "JT4": "Toyota", "JTH": "Lexus",
    "JTJ": "Lexus", "JAA": "Isuzu", "JAM": "Isuzu", "JDA": "Daihatsu",
    "JS1": "Suzuki", "JS2": "Suzuki", "JS3": "Suzuki", "JYA": "Yamaha",
    "JKA": "Kawasaki",
    // Korea
    "KMH": "Hyundai", "KMT": "Genesis", "KNA": "Kia", "KND": "Kia",
    "KNM": "Renault Korea", "KLA": "Daewoo", "KPA": "SsangYong",
    "KPT": "SsangYong",
    // China
    "LFV": "FAW-Volkswagen", "LSV": "SAIC Volkswagen", "LSG": "SAIC-GM",
    "LSJ": "MG / Roewe", "LGW": "Great Wall", "L6T": "Lynk & Co",
    "L1N": "XPeng", "LW4": "Li Auto", "HLX": "Li Auto", "HXM": "Xiaomi",
    "HAC": "GAC", "LMG": "GAC Trumpchi", "LRW": "Tesla", "LYV": "Volvo",
    "LVS": "Changan Ford", "LVR": "Changan Mazda", "LUC": "Honda",
    "LVG": "GAC Toyota", "LVH": "Dongfeng Honda", "LZZ": "Sinotruk Howo",
    "LBV": "BMW Brilliance", "LBE": "Beijing Hyundai", "LJD": "Yueda Kia",
    "LFB": "FAW Bestune",
    // India
    "MAT": "Tata", "MAB": "Mahindra", "MA1": "Mahindra", "MA3": "Maruti Suzuki",
    "MAL": "Hyundai", "MAK": "Honda", "MAJ": "Ford", "MBL": "Hero MotoCorp",
    "MD2": "Bajaj", "MD6": "TVS", "MB1": "Ashok Leyland", "MZ7": "MG",
    "MBF": "Royal Enfield", "MEX": "Škoda",
    // United States
    "1G1": "Chevrolet", "1GC": "Chevrolet", "1GB": "Chevrolet",
    "1G2": "Pontiac", "1G3": "Oldsmobile", "1G4": "Buick", "1G6": "Cadillac",
    "1GM": "Pontiac", "1GY": "Cadillac", "1G0": "GMC", "1GT": "GMC",
    "1FA": "Ford", "1FB": "Ford", "1FC": "Ford", "1FD": "Ford", "1FM": "Ford",
    "1FT": "Ford", "1FU": "Freightliner", "1FV": "Freightliner",
    "1C3": "Chrysler", "1C4": "Chrysler", "1C6": "Ram", "1C8": "Chrysler",
    "1B3": "Dodge", "1B4": "Dodge", "1B7": "Dodge", "1D3": "Dodge",
    "1D4": "Dodge", "1D7": "Dodge", "1HG": "Honda", "1HD": "Harley-Davidson",
    "1J4": "Jeep", "1J8": "Jeep", "1N4": "Nissan", "1N6": "Nissan",
    "1ME": "Mercury", "1LN": "Lincoln", "1YV": "Mazda",
    "5YJ": "Tesla", "7SA": "Tesla",
    "4T1": "Toyota", "4T3": "Toyota", "5TD": "Toyota", "5TF": "Toyota",
    "2T1": "Toyota", "2HG": "Honda", "2HK": "Honda", "5FN": "Honda",
    "19X": "Honda", "19U": "Acura", "5J6": "Honda", "JH4": "Acura",
    // Canada / Mexico (assembly)
    "2G1": "Chevrolet", "2T2": "Lexus", "3FA": "Ford",
    "3N1": "Nissan", "3GC": "Chevrolet", "3MZ": "Mazda",
    // Russia
    "XTA": "Lada", "XTC": "KamAZ", "XTH": "GAZ", "XTT": "UAZ", "EAA": "Aurus",
    // Other notable
    "ZD0": "Yamaha", "VBK": "KTM", "ZHU": "Husqvarna",
]
