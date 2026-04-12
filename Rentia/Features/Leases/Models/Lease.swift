import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Lease Status

enum LeaseStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case active
    case expired
    case ended

    var localizedName: LocalizedStringKey {
        switch self {
        case .draft: "leases.status.draft"
        case .active: "leases.status.active"
        case .expired: "leases.status.expired"
        case .ended: "leases.status.ended"
        }
    }

    var isTerminal: Bool {
        self == .ended || self == .expired
    }

    var allowedTransitions: [Self] {
        switch self {
        case .draft: [.active, .ended]
        case .active: [.ended, .expired]
        case .ended, .expired: []
        }
    }
}

// MARK: - Utilities Mode

enum UtilitiesMode: String, Codable, CaseIterable, Sendable {
    case included
    case manual
    case none

    var localizedName: LocalizedStringKey {
        switch self {
        case .included: "leases.utilities.included"
        case .manual: "leases.utilities.manual"
        case .none: "leases.utilities.none"
        }
    }
}

// MARK: - Lease Model

struct Lease: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var ownerId: String
    var propertyId: String
    var tenantId: String
    var startDate: Date
    var endDate: Date?
    var rentAmount: Double
    var depositAmount: Double
    /// Código ISO de moneda. Opcional para retrocompatibilidad con documentos
    /// existentes en Firestore que no tienen el campo; nil se trata como "EUR".
    var currency: String?
    var billingDay: Int
    var utilitiesMode: UtilitiesMode
    var status: LeaseStatus
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    /// Devuelve siempre un código válido aunque el campo no exista en Firestore.
    var currencyCode: String { currency ?? "EUR" }
}
