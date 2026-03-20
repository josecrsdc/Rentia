import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Document Type

enum DocumentType: String, Codable, CaseIterable, Sendable {
    case receipt
    case contract
    case identity
    case other

    var localizedName: LocalizedStringKey {
        switch self {
        case .receipt: "documents.type.receipt"
        case .contract: "documents.type.contract"
        case .identity: "documents.type.identity"
        case .other: "documents.type.other"
        }
    }

    var icon: String {
        switch self {
        case .receipt: "doc.text"
        case .contract: "doc.richtext"
        case .identity: "person.text.rectangle"
        case .other: "doc"
        }
    }
}

// MARK: - Associated Entity Type

enum AssociatedEntityType: String, Codable, CaseIterable, Sendable {
    case property
    case tenant
    case lease
}

// MARK: - Document Model

struct RentiaDocument: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var ownerId: String
    var name: String
    var type: DocumentType
    var fileURL: String
    var associatedEntityId: String
    var associatedEntityType: AssociatedEntityType
    var createdAt: Date
}
