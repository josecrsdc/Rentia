import FirebaseFirestore
import Foundation

// MARK: - Tenant Status

enum TenantStatus: String, Codable, CaseIterable, Sendable {
    case active
    case inactive

    var displayName: String {
        switch self {
        case .active: String(localized: "Activo")
        case .inactive: String(localized: "Inactivo")
        }
    }
}

// MARK: - Tenant Model

struct Tenant: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var ownerId: String
    var propertyId: String?
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var idNumber: String?
    var leaseStartDate: Date?
    var leaseEndDate: Date?
    var monthlyRent: Double
    var depositAmount: Double
    var status: TenantStatus
    var createdAt: Date

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
