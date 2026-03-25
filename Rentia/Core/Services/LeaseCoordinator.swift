import Foundation

final class LeaseCoordinator: Sendable {
    private let firestoreService: any FirestoreServiceProtocol
    private let paymentGenerationService: any PaymentGenerationServiceProtocol

    init(
        firestoreService: any FirestoreServiceProtocol = FirestoreService(),
        paymentGenerationService: any PaymentGenerationServiceProtocol = PaymentGenerationService()
    ) {
        self.firestoreService = firestoreService
        self.paymentGenerationService = paymentGenerationService
    }

    nonisolated func onActivated(lease: Lease, ownerId: String) async throws {
        guard let leaseId = lease.id else { return }

        // generatePayments skips months already covered internally
        _ = try await paymentGenerationService.generatePayments(
            for: lease,
            leaseId: leaseId,
            ownerId: ownerId
        )

        // Update property status to .rented
        if let property: Property = try? await firestoreService.read(
            id: lease.propertyId,
            from: "properties"
        ) {
            var updatedProperty = property
            updatedProperty.status = .rented
            try? await firestoreService.update(
                updatedProperty,
                id: lease.propertyId,
                in: "properties"
            )
        }

        // Update tenant status to .active and add propertyId if missing
        if let tenant: Tenant = try? await firestoreService.read(
            id: lease.tenantId,
            from: "tenants"
        ) {
            var updatedTenant = tenant
            updatedTenant.status = .active
            if !updatedTenant.propertyIds.contains(lease.propertyId) {
                updatedTenant.propertyIds.append(lease.propertyId)
            }
            try? await firestoreService.update(
                updatedTenant,
                id: lease.tenantId,
                in: "tenants"
            )
        }
    }

    nonisolated func onDeactivated(
        lease: Lease,
        ownerId: String,
        skipPaymentCancellation: Bool = false
    ) async throws {
        guard let leaseId = lease.id else { return }

        if !skipPaymentCancellation {
            let paymentsToCancel: [Payment] = (
                try? await firestoreService.readAll(
                    from: "payments",
                    whereField: "leaseId",
                    isEqualTo: leaseId
                )
            ) ?? []

            for payment in paymentsToCancel where payment.status == .pending || payment.status == .overdue {
                guard let paymentId = payment.id else { continue }
                var cancelled = payment
                cancelled.status = .cancelled
                try? await firestoreService.update(cancelled, id: paymentId, in: "payments")
            }
        }

        // Check if property has another active lease
        let propertyLeases: [Lease] = (
            try? await firestoreService.readAll(
                from: "leases",
                whereField: "propertyId",
                isEqualTo: lease.propertyId,
                whereField: "ownerId",
                isEqualTo: ownerId
            )
        ) ?? []
        let hasOtherActiveLease = propertyLeases.contains { $0.status == .active && $0.id != leaseId }

        if !hasOtherActiveLease,
           let property: Property = try? await firestoreService.read(
               id: lease.propertyId,
               from: "properties"
           ) {
            var updatedProperty = property
            updatedProperty.status = .available
            try? await firestoreService.update(
                updatedProperty,
                id: lease.propertyId,
                in: "properties"
            )
        }

        // Check if tenant has another active lease
        let tenantLeases: [Lease] = (
            try? await firestoreService.readAll(
                from: "leases",
                whereField: "tenantId",
                isEqualTo: lease.tenantId,
                whereField: "ownerId",
                isEqualTo: ownerId
            )
        ) ?? []
        let hasOtherActiveTenantLease = tenantLeases.contains { $0.status == .active && $0.id != leaseId }

        if !hasOtherActiveTenantLease,
           let tenant: Tenant = try? await firestoreService.read(
               id: lease.tenantId,
               from: "tenants"
           ) {
            var updatedTenant = tenant
            updatedTenant.status = .inactive
            updatedTenant.propertyIds.removeAll { $0 == lease.propertyId }
            try? await firestoreService.update(
                updatedTenant,
                id: lease.tenantId,
                in: "tenants"
            )
        }
    }
}
