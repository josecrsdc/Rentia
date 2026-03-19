import FirebaseAuth
import Foundation

@Observable
final class AdministratorFormViewModel {
    var name = ""
    var phone = ""
    var landlinePhone = ""
    var email = ""
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var didSave = false
    var savedId: String?

    private let firestoreService = FirestoreService()
    private var editingAdministratorId: String?

    var isEditing: Bool {
        editingAdministratorId != nil
    }

    var isFormValid: Bool {
        name.isNotEmpty
        && phone.isNotEmpty
        && email.isValidEmail
    }

    func loadAdministrator(id: String) {
        editingAdministratorId = id
        isLoading = true

        Task {
            do {
                let administrator: Administrator = try await firestoreService.read(
                    id: id,
                    from: "administrators"
                )
                name = administrator.name
                phone = administrator.phone
                landlinePhone = administrator.landlinePhone ?? ""
                email = administrator.email
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func save() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        let administrator = Administrator(
            id: editingAdministratorId,
            ownerId: userId,
            name: name.trimmed,
            phone: phone.trimmed,
            landlinePhone: landlinePhone.trimmed.isEmpty ? nil : landlinePhone.trimmed,
            email: email.trimmed,
            createdAt: Date()
        )

        Task {
            do {
                if let administratorId = editingAdministratorId {
                    try await firestoreService.update(
                        administrator,
                        id: administratorId,
                        in: "administrators"
                    )
                } else {
                    let docId = try await firestoreService.create(
                        administrator,
                        in: "administrators"
                    )
                    savedId = docId
                }
                didSave = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
