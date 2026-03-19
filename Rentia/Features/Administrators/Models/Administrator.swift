import FirebaseFirestore
import Foundation

struct Administrator: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var ownerId: String
    var name: String
    var phone: String
    var landlinePhone: String?
    var email: String
    var createdAt: Date

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1).uppercased() ?? ""
        let last = parts.count > 1 ? parts.last?.prefix(1).uppercased() ?? "" : ""
        return "\(first)\(last)"
    }
}
