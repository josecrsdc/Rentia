import FirebaseFirestore
import Foundation

struct UserProfile: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var uid: String
    var email: String
    var displayName: String
    var photoURL: String?
    var authProvider: String
    var createdAt: Date
    var updatedAt: Date
}
