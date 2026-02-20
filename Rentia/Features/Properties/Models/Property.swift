import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Property Type

enum PropertyType: String, Codable, CaseIterable, Sendable {
    case apartment
    case house
    case commercial
    case garage
    case land

    var localizedName: LocalizedStringKey {
        switch self {
        case .apartment: "properties.type.apartment"
        case .house: "properties.type.house"
        case .commercial: "properties.type.commercial"
        case .garage: "properties.type.garage"
        case .land: "properties.type.land"
        }
    }

    var icon: String {
        switch self {
        case .apartment: "building.2"
        case .house: "house"
        case .commercial: "storefront"
        case .garage: "car.fill"
        case .land: "leaf"
        }
    }

    var supportsRoomsBathrooms: Bool {
        self != .garage && self != .land
    }
}

// MARK: - Property Status

enum PropertyStatus: String, Codable, CaseIterable, Sendable {
    case available
    case maintenance

    var localizedName: LocalizedStringKey {
        switch self {
        case .available: "properties.status.available"
        case .maintenance: "properties.status.maintenance"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .available
    }
}

// MARK: - Property Model

struct Property: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var ownerId: String
    var name: String
    var address: String
    var type: PropertyType
    var monthlyRent: Double
    var currency: String
    var status: PropertyStatus
    var description: String?
    var rooms: Int
    var bathrooms: Int
    var area: Double?
    var imageURLs: [String]
    var createdAt: Date
}
