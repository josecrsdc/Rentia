import FirebaseAuth
import Foundation

@Observable
final class LeaseFormViewModel {
    var propertyId = ""
    var tenantId = ""
    var startDate = Date()
    var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    var hasEndDate = true
    var rentAmount = ""
    var depositAmount = ""
    var billingDay = 1
    var utilitiesMode: UtilitiesMode = .none
    var status: LeaseStatus = .active
    var notes = ""
    var availableProperties: [Property] = []
    var availableTenants: [Tenant] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var didSave = false
    var savedId: String?

    var preAssignedPropertyId: String?
    var preAssignedTenantId: String?

    var hidePropertySelector: Bool {
        preAssignedPropertyId != nil
    }

    var hideTenantSelector: Bool {
        preAssignedTenantId != nil
    }

    private let firestoreService = FirestoreService()
    private var editingLeaseId: String?

    var isEditing: Bool {
        editingLeaseId != nil
    }

    var isFormValid: Bool {
        propertyId.isNotEmpty
            && tenantId.isNotEmpty
            && (Double(rentAmount) ?? 0) > 0
            && billingDay >= 1 && billingDay <= 28
    }

    func configure(
        propertyId: String,
        tenantId: String,
        rent: Double,
        currency: String
    ) {
        self.propertyId = propertyId
        self.tenantId = tenantId
        preAssignedPropertyId = propertyId
        preAssignedTenantId = tenantId
        rentAmount = String(format: "%.2f", rent)
    }

    func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                if preAssignedPropertyId == nil {
                    availableProperties = try await firestoreService.readAll(
                        from: "properties",
                        whereField: "ownerId",
                        isEqualTo: userId
                    )
                }
                if preAssignedTenantId == nil {
                    availableTenants = try await firestoreService.readAll(
                        from: "tenants",
                        whereField: "ownerId",
                        isEqualTo: userId
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    func save() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        let now = Date()
        let lease = Lease(
            id: editingLeaseId,
            ownerId: userId,
            propertyId: propertyId,
            tenantId: tenantId,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            rentAmount: Double(rentAmount) ?? 0,
            depositAmount: Double(depositAmount) ?? 0,
            billingDay: billingDay,
            utilitiesMode: utilitiesMode,
            status: status,
            notes: notes.trimmed.isEmpty ? nil : notes.trimmed,
            createdAt: now,
            updatedAt: now
        )

        Task {
            do {
                if let leaseId = editingLeaseId {
                    try await firestoreService.update(
                        lease,
                        id: leaseId,
                        in: "leases"
                    )
                } else {
                    let docId = try await firestoreService.create(
                        lease,
                        in: "leases"
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
