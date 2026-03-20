import FirebaseAuth
import Foundation

struct TenantDebt: Identifiable, Sendable {
    let id: String
    let tenant: Tenant
    let payments: [Payment]

    init(tenant: Tenant, payments: [Payment]) {
        self.id = tenant.id ?? UUID().uuidString
        self.tenant = tenant
        self.payments = payments
    }

    var totalDebt: Double {
        payments
            .filter { $0.status == .pending || $0.status == .overdue || $0.status == .partial }
            .reduce(0) { $0 + $1.amount }
    }

    var overdueCount: Int {
        payments.filter { $0.status == .overdue }.count
    }

    var pendingCount: Int {
        payments.filter { $0.status == .pending || $0.status == .partial }.count
    }
}

@MainActor
@Observable
final class DebtReportViewModel {
    var tenantDebts: [TenantDebt] = []
    var isLoading = false

    private let firestoreService: any FirestoreServiceProtocol

    init(firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    var totalDebt: Double {
        tenantDebts.reduce(0) { $0 + $1.totalDebt }
    }

    var tenantsWithDebt: [TenantDebt] {
        tenantDebts.filter { $0.totalDebt > 0 }.sorted { $0.totalDebt > $1.totalDebt }
    }

    func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            async let tenantsResult: [Tenant] = (
                try? await firestoreService.readAll(
                    from: "tenants",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            async let paymentsResult: [Payment] = (
                try? await firestoreService.readAll(
                    from: "payments",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            let tenants = await tenantsResult
            let payments = await paymentsResult

            tenantDebts = tenants.map { tenant in
                let tenantPayments = payments.filter { $0.tenantId == tenant.id }
                return TenantDebt(tenant: tenant, payments: tenantPayments)
            }
            .filter { $0.totalDebt > 0 }
            .sorted { $0.totalDebt > $1.totalDebt }

            isLoading = false
        }
    }
}
