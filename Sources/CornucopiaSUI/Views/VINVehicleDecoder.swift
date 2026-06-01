//
//  VINVehicleDecoder.swift
//  CornucopiaSUI
//
//  Optional online enrichment of a decoded VIN with make/model/year/type details.
//

import Foundation

/// The richer, online-decoded facts about a vehicle that cannot be derived from the static
/// ISO tables alone (which only yield country and manufacturer, see ``VINIdentity``).
public struct VINVehicleDetails: Equatable, Sendable {

    public let make: String?
    public let model: String?
    public let modelYear: String?
    public let vehicleType: String?
    public let bodyClass: String?

    public init(
        make: String?,
        model: String?,
        modelYear: String?,
        vehicleType: String?,
        bodyClass: String?
    ) {
        self.make = make
        self.model = model
        self.modelYear = modelYear
        self.vehicleType = vehicleType
        self.bodyClass = bodyClass
    }

    public var isEmpty: Bool {
        make == nil && model == nil && modelYear == nil && vehicleType == nil && bodyClass == nil
    }
}

/// A pluggable, asynchronous source of ``VINVehicleDetails`` for a complete VIN.
///
/// The control accepts one of these as an opt-in dependency; when absent, no network access ever
/// happens. A decoder may legitimately return `nil` to mean "no details for this VIN".
public struct VINVehicleDecoder: Sendable {

    public typealias Decode = @Sendable (_ vin: String) async throws -> VINVehicleDetails?

    private let decode: Decode

    public init(_ decode: @escaping Decode) {
        self.decode = decode
    }

    public func callAsFunction(_ vin: String) async throws -> VINVehicleDetails? {
        try await decode(vin)
    }
}

public extension VINVehicleDecoder {

    /// Decodes a VIN (or VIN prefix) through the free NHTSA vPIC service.
    ///
    /// NHTSA is US-focused but frequently resolves makes and even models for vehicles sold
    /// outside the United States, so the VIN is always sent and the caller decides what to do
    /// with a sparse result. The service also accepts partial VINs, so a prefix that already
    /// carries the descriptor and model-year positions is enough to start decoding.
    static var nhtsa: VINVehicleDecoder {
        VINVehicleDecoder { vin in
            guard let escaped = vin.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let url = URL(string: "https://vpic.nhtsa.dot.gov/api/vehicles/decodevin/\(escaped)?format=json") else {
                return nil
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(NHTSAResponse.self, from: data)
            let values = response.valuesByVariable
            let details = VINVehicleDetails(
                make: values["Make"],
                model: values["Model"],
                modelYear: values["Model Year"],
                vehicleType: values["Vehicle Type"],
                bodyClass: values["Body Class"]
            )
            return details.isEmpty ? nil : details
        }
    }
}

private struct NHTSAResponse: Decodable {

    let results: [Item]

    enum CodingKeys: String, CodingKey {
        case results = "Results"
    }

    struct Item: Decodable {
        let variable: String?
        let value: String?

        enum CodingKeys: String, CodingKey {
            case variable = "Variable"
            case value = "Value"
        }
    }

    var valuesByVariable: [String: String] {
        results.reduce(into: [:]) { result, item in
            guard let key = item.variable, let value = item.value, !value.isEmpty else { return }
            result[key] = value
        }
    }
}
