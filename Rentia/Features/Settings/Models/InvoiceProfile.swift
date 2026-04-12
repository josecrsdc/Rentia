import FirebaseFirestore
import Foundation

struct InvoiceProfile: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var ownerId: String
    var displayName: String
    var taxId: String
    var address: String
    var phone: String
    var email: String
    var bankAccount: String
    var invoiceCounter: Int
    var logoURL: String?
    var updatedAt: Date
}
