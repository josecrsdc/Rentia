import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Payment Status

enum PaymentStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case paid
    case overdue
    case partial
    case cancelled

    var localizedName: LocalizedStringKey {
        switch self {
        case .pending: "payments.status.pending"
        case .paid: "payments.status.paid"
        case .overdue: "payments.status.overdue"
        case .partial: "payments.status.partial"
        case .cancelled: "payments.status.cancelled"
        }
    }

    var icon: String {
        switch self {
        case .pending: "clock"
        case .paid: "checkmark.circle.fill"
        case .overdue: "exclamationmark.triangle.fill"
        case .partial: "chart.pie"
        case .cancelled: "slash.circle"
        }
    }
}

// MARK: - Payment Model

struct Payment: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var ownerId: String
    var tenantId: String
    var propertyId: String
    var leaseId: String?
    var amount: Double
    var date: Date
    var dueDate: Date
    var status: PaymentStatus
    var paymentMethod: String?
    var notes: String?
    var createdAt: Date
}
