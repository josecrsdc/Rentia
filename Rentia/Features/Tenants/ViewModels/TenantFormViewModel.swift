import FirebaseAuth
import Foundation

@Observable
final class TenantFormViewModel {
    var firstName = ""
    var lastName = ""
    var email = ""
    var phone = ""
    var idNumber = ""
    var status: TenantStatus = .active
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var didSave = false
    var savedId: String?
    private let firestoreService: any FirestoreServiceProtocol
    private var editingTenantId: String?
    private var existingPropertyIds: [String] = []

    init(firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    var isEditing: Bool {
        editingTenantId != nil
    }

    var isFormValid: Bool {
        firstName.isNotEmpty
        && lastName.isNotEmpty
        && email.isValidEmail
        && phone.isNotEmpty
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
                status = tenant.status
                existingPropertyIds = tenant.propertyIds
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func delete(tenantId: String) {
        let userId = Auth.auth().currentUser?.uid ?? ""
        isLoading = true

        Task {
            do {
                let activeLeases: [Lease] = try await firestoreService.readAll(
                    from: "leases",
                    whereField: "tenantId",
                    isEqualTo: tenantId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )

                let hasActiveLease = activeLeases.contains { $0.status == .active }
                if hasActiveLease {
                    errorMessage = String(localized: "tenants.error.delete_has_active_lease")
                    showError = true
                    isLoading = false
                    return
                }

                try await firestoreService.delete(id: tenantId, from: "tenants")
                didSave = true
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

        let tenant = Tenant(
            id: editingTenantId,
            ownerId: userId,
            propertyIds: existingPropertyIds,
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
