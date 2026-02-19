import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Tenant Status

enum TenantStatus: String, Codable, CaseIterable, Sendable {
    case active
    case inactive

    var displayNameKey: LocalizedStringKey {
        switch self {
        case .active: "tenants.status.active"
        case .inactive: "tenants.status.inactive"
        }
    }
}

// MARK: - Tenant Model

struct Tenant: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var ownerId: String
    var propertyIds: [String]
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

    init(
        id: String? = nil,
        ownerId: String,
        propertyIds: [String] = [],
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        idNumber: String? = nil,
        leaseStartDate: Date? = nil,
        leaseEndDate: Date? = nil,
        monthlyRent: Double,
        depositAmount: Double,
        status: TenantStatus,
        createdAt: Date
    ) {
        self.id = id
        self.ownerId = ownerId
        self.propertyIds = propertyIds
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.idNumber = idNumber
        self.leaseStartDate = leaseStartDate
        self.leaseEndDate = leaseEndDate
        self.monthlyRent = monthlyRent
        self.depositAmount = depositAmount
        self.status = status
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        propertyIds = (try? container.decode([String].self, forKey: .propertyIds)) ?? []
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decode(String.self, forKey: .phone)
        idNumber = try container.decodeIfPresent(String.self, forKey: .idNumber)
        leaseStartDate = try container.decodeIfPresent(Date.self, forKey: .leaseStartDate)
        leaseEndDate = try container.decodeIfPresent(Date.self, forKey: .leaseEndDate)
        monthlyRent = try container.decode(Double.self, forKey: .monthlyRent)
        depositAmount = try container.decode(Double.self, forKey: .depositAmount)
        status = try container.decode(TenantStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
