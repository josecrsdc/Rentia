import FirebaseFirestore
import Foundation

// MARK: - Property Type

enum PropertyType: String, Codable, CaseIterable, Sendable {
    case apartment
    case house
    case commercial
    case garage
    case land

    var displayName: String {
        switch self {
        case .apartment: String(localized: "Apartamento")
        case .house: String(localized: "Casa")
        case .commercial: String(localized: "Comercial")
        case .garage: String(localized: "Plaza de garaje")
        case .land: String(localized: "Terreno")
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
    case rented
    case maintenance

    var displayName: String {
        switch self {
        case .available: String(localized: "Disponible")
        case .rented: String(localized: "Alquilada")
        case .maintenance: String(localized: "Mantenimiento")
        }
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
