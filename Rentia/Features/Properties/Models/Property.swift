import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Property Type

enum PropertyType: String, Codable, CaseIterable, Sendable {
    case apartment
    case house
    case studio
    case commercial
    case garage
    case land

    var localizedName: LocalizedStringKey {
        switch self {
        case .apartment: "properties.type.apartment"
        case .house: "properties.type.house"
        case .studio: "properties.type.studio"
        case .commercial: "properties.type.commercial"
        case .garage: "properties.type.garage"
        case .land: "properties.type.land"
        }
    }

    var icon: String {
        switch self {
        case .apartment: "building.2"
        case .house: "house"
        case .studio: "bed.double"
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
    case rented

    var localizedName: LocalizedStringKey {
        switch self {
        case .available: "properties.status.available"
        case .maintenance: "properties.status.maintenance"
        case .rented: "properties.status.rented"
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
    var address: Address
    var cadastralReference: String?
    var type: PropertyType
    var currency: String
    var status: PropertyStatus
    var description: String?
    var rooms: Int
    var bathrooms: Int
    var area: Double?
    var administratorId: String?
    var imageURLs: [String]
    var createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, ownerId, name, address, cadastralReference, type, currency, status
        case description, rooms, bathrooms, area, administratorId, imageURLs, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        _id = try c.decode(DocumentID<String>.self, forKey: .id)
        ownerId = try c.decode(String.self, forKey: .ownerId)
        name = try c.decode(String.self, forKey: .name)
        address = try c.decode(Address.self, forKey: .address)
        cadastralReference = try c.decodeIfPresent(String.self, forKey: .cadastralReference)
        type = try c.decode(PropertyType.self, forKey: .type)
        currency = try c.decode(String.self, forKey: .currency)
        status = try c.decode(PropertyStatus.self, forKey: .status)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        rooms = try c.decode(Int.self, forKey: .rooms)
        bathrooms = try c.decode(Int.self, forKey: .bathrooms)
        area = try c.decodeIfPresent(Double.self, forKey: .area)
        administratorId = try c.decodeIfPresent(String.self, forKey: .administratorId)
        imageURLs = (try? c.decode([String].self, forKey: .imageURLs)) ?? []
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    init(
        id: String? = nil,
        ownerId: String,
        name: String,
        address: Address,
        cadastralReference: String? = nil,
        type: PropertyType,
        currency: String,
        status: PropertyStatus,
        description: String? = nil,
        rooms: Int,
        bathrooms: Int,
        area: Double? = nil,
        administratorId: String? = nil,
        imageURLs: [String] = [],
        createdAt: Date
    ) {
        self._id = DocumentID(wrappedValue: id)
        self.ownerId = ownerId
        self.name = name
        self.address = address
        self.cadastralReference = cadastralReference
        self.type = type
        self.currency = currency
        self.status = status
        self.description = description
        self.rooms = rooms
        self.bathrooms = bathrooms
        self.area = area
        self.administratorId = administratorId
        self.imageURLs = imageURLs
        self.createdAt = createdAt
    }
}
