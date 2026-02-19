import FirebaseFirestore
import Foundation

// MARK: - Payment Status

enum PaymentStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case paid
    case overdue
    case partial

    var displayName: String {
        switch self {
        case .pending: String(localized: "Pendiente")
        case .paid: String(localized: "Pagado")
        case .overdue: String(localized: "Vencido")
        case .partial: String(localized: "Parcial")
        }
    }

    var icon: String {
        switch self {
        case .pending: "clock"
        case .paid: "checkmark.circle.fill"
        case .overdue: "exclamationmark.triangle.fill"
        case .partial: "chart.pie"
        }
    }
}

// MARK: - Payment Model

struct Payment: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var ownerId: String
    var tenantId: String
    var propertyId: String
    var amount: Double
    var date: Date
    var dueDate: Date
    var status: PaymentStatus
    var paymentMethod: String?
    var notes: String?
    var createdAt: Date
}
