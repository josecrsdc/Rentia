import FirebaseAuth
import Foundation

@Observable
final class TenantFormViewModel {
    var firstName = ""
    var lastName = ""
    var email = ""
    var phone = ""
    var idNumber = ""
    var propertyIds: [String] = []
    var availableProperties: [Property] = []
    var status: TenantStatus = .active
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var didSave = false
    var savedId: String?
    var preAssignedPropertyIds: [String] = []

    var hidePropertySelector: Bool {
        !preAssignedPropertyIds.isEmpty
    }

    private let firestoreService = FirestoreService()
    private var editingTenantId: String?

    var isEditing: Bool {
        editingTenantId != nil
    }

    var isFormValid: Bool {
        firstName.isNotEmpty
        && lastName.isNotEmpty
        && email.isValidEmail
        && phone.isNotEmpty
    }

    func loadProperties() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                availableProperties = try await firestoreService.readAll(
                    from: "properties",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    func isPropertySelected(_ propertyId: String) -> Bool {
        propertyIds.contains(propertyId)
    }

    func toggleProperty(_ propertyId: String) {
        if let index = propertyIds.firstIndex(of: propertyId) {
            propertyIds.remove(at: index)
        } else {
            propertyIds.append(propertyId)
        }
    }

    func loadTenant(id: String) {
        editingTenantId = id
        isLoading = true

        Task {
            do {
                let tenant: Tenant = try await firestoreService.read(
                    id: id,
                    from: "tenants"
                )
                firstName = tenant.firstName
                lastName = tenant.lastName
                email = tenant.email
                phone = tenant.phone
                idNumber = tenant.idNumber ?? ""
                propertyIds = tenant.propertyIds
                status = tenant.status
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

        let finalPropertyIds = preAssignedPropertyIds.isEmpty
            ? propertyIds : preAssignedPropertyIds

        let tenant = Tenant(
            id: editingTenantId,
            ownerId: userId,
            propertyIds: finalPropertyIds,
            firstName: firstName.trimmed,
            lastName: lastName.trimmed,
            email: email.trimmed,
            phone: phone.trimmed,
            idNumber: idNumber.trimmed.isEmpty ? nil : idNumber.trimmed,
            status: status,
            createdAt: Date()
        )

        Task {
            do {
                if let tenantId = editingTenantId {
                    try await firestoreService.update(
                        tenant,
                        id: tenantId,
                        in: "tenants"
                    )
                } else {
                    let docId = try await firestoreService.create(
                        tenant,
                        in: "tenants"
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
