import FirebaseAuth
import Foundation
import UIKit

@Observable
final class InvoiceSettingsViewModel {
    var displayName = ""
    var taxId = ""
    var address = ""
    var phone = ""
    var email = ""
    var bankAccount = ""
    var invoiceCounter = 1
    var logoURL: String?
    var pendingLogoImage: UIImage?

    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var showError = false
    var didSave = false

    private let firestoreService: any FirestoreServiceProtocol
    private let storageService: any StorageServiceProtocol

    init(
        firestoreService: any FirestoreServiceProtocol = FirestoreService(),
        storageService: any StorageServiceProtocol = SupabaseStorageService()
    ) {
        self.firestoreService = firestoreService
        self.storageService = storageService
    }

    func load() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            do {
                let profile: InvoiceProfile = try await firestoreService.read(
                    id: userId,
                    from: "invoiceProfiles"
                )
                displayName = profile.displayName
                taxId = profile.taxId
                address = profile.address
                phone = profile.phone
                email = profile.email
                bankAccount = profile.bankAccount
                invoiceCounter = profile.invoiceCounter
                logoURL = profile.logoURL
            } catch {
                // Perfil aún no existe — los campos quedan vacíos con sus valores por defecto
            }
            isLoading = false
        }
    }

    func save() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isSaving = true

        Task {
            do {
                // Si hay una imagen pendiente, subirla primero
                if let image = pendingLogoImage {
                    let path = "owners/\(userId)/invoice/logo.jpg"
                    logoURL = try await storageService.uploadImage(image, path: path)
                    pendingLogoImage = nil
                }

                let profile = InvoiceProfile(
                    id: userId,
                    ownerId: userId,
                    displayName: displayName.trimmingCharacters(in: .whitespaces),
                    taxId: taxId.trimmingCharacters(in: .whitespaces),
                    address: address.trimmingCharacters(in: .whitespaces),
                    phone: phone.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces),
                    bankAccount: bankAccount.trimmingCharacters(in: .whitespaces),
                    invoiceCounter: invoiceCounter,
                    logoURL: logoURL,
                    updatedAt: Date()
                )
                try await firestoreService.update(profile, id: userId, in: "invoiceProfiles")
                didSave = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isSaving = false
        }
    }
}
