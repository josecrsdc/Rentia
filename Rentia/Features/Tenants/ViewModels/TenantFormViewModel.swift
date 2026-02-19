import FirebaseAuth
import Foundation

@Observable
final class TenantFormViewModel {
    var firstName = ""
    var lastName = ""
    var email = ""
    var phone = ""
    var idNumber = ""
    var propertyId: String?
    var leaseStartDate = Date()
    var leaseEndDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
    var monthlyRent = ""
    var depositAmount = ""
    var status: TenantStatus = .active
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var didSave = false

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
                propertyId = tenant.propertyId
                leaseStartDate = tenant.leaseStartDate ?? Date()
                leaseEndDate = tenant.leaseEndDate
                    ?? Date().addingTimeInterval(365 * 24 * 60 * 60)
                monthlyRent = String(format: "%.2f", tenant.monthlyRent)
                depositAmount = String(format: "%.2f", tenant.depositAmount)
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

        let tenant = Tenant(
            id: editingTenantId,
            ownerId: userId,
            propertyId: propertyId,
            firstName: firstName.trimmed,
            lastName: lastName.trimmed,
            email: email.trimmed,
            phone: phone.trimmed,
            idNumber: idNumber.trimmed.isEmpty ? nil : idNumber.trimmed,
            leaseStartDate: leaseStartDate,
            leaseEndDate: leaseEndDate,
            monthlyRent: Double(monthlyRent) ?? 0,
            depositAmount: Double(depositAmount) ?? 0,
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
                    _ = try await firestoreService.create(
                        tenant,
                        in: "tenants"
                    )
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
