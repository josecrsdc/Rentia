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

    func loadLease(id: String) {
        editingLeaseId = id
        isLoading = true

        Task {
            do {
                let lease: Lease = try await firestoreService.read(
                    id: id,
                    from: "leases"
                )
                propertyId = lease.propertyId
                tenantId = lease.tenantId
                startDate = lease.startDate
                hasEndDate = lease.endDate != nil
                endDate = lease.endDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
                rentAmount = String(format: "%.2f", lease.rentAmount)
                depositAmount = String(format: "%.2f", lease.depositAmount)
                billingDay = lease.billingDay
                utilitiesMode = lease.utilitiesMode
                status = lease.status
                notes = lease.notes ?? ""
                preAssignedPropertyId = lease.propertyId
                preAssignedTenantId = lease.tenantId
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

        Task {
            if status == .active {
                let existingLeases: [Lease] = (
                    try? await firestoreService.readAll(
                        from: "leases",
                        whereField: "propertyId",
                        isEqualTo: propertyId,
                        whereField: "ownerId",
                        isEqualTo: userId
                    )
                ) ?? []
                let hasConflict = existingLeases.contains {
                    $0.status == .active && $0.id != editingLeaseId
                }
                if hasConflict {
                    errorMessage = String(localized: "leases.error.active_exists")
                    showError = true
                    isLoading = false
                    return
                }
            }

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

            do {
                if let leaseId = editingLeaseId {
                    try await firestoreService.update(
                        lease,
                        id: leaseId,
                        in: "leases"
                    )
                    savedId = leaseId
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
