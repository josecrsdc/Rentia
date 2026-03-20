import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Expense Category

enum ExpenseCategory: String, Codable, CaseIterable, Sendable {
    case ibi
    case community
    case insurance
    case repair
    case utilities
    case mortgage
    case management
    case other

    var localizedName: LocalizedStringKey {
        switch self {
        case .ibi: "expenses.category.ibi"
        case .community: "expenses.category.community"
        case .insurance: "expenses.category.insurance"
        case .repair: "expenses.category.repair"
        case .utilities: "expenses.category.utilities"
        case .mortgage: "expenses.category.mortgage"
        case .management: "expenses.category.management"
        case .other: "expenses.category.other"
        }
    }

    var icon: String {
        switch self {
        case .ibi: "building.columns"
        case .community: "person.3"
        case .insurance: "shield"
        case .repair: "wrench.and.screwdriver"
        case .utilities: "bolt"
        case .mortgage: "house.and.flag"
        case .management: "briefcase"
        case .other: "ellipsis.circle"
        }
    }
}

// MARK: - Expense Model

struct Expense: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var ownerId: String
    var propertyId: String
    var date: Date
    var amount: Double
    var category: ExpenseCategory
    var description: String
    var receiptURL: String?
    var createdAt: Date
}
