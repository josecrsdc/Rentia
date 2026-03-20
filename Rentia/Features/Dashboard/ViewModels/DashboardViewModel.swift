import FirebaseAuth
import Foundation

@Observable
final class DashboardViewModel {
    var properties: [Property] = []
    var tenants: [Tenant] = []
    var payments: [Payment] = []
    var leases: [Lease] = []
    var isLoading = false
    var errorMessage: String?

    private let firestoreService: any FirestoreServiceProtocol

    init(firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    var totalMonthlyIncome: Double {
        payments
            .filter { $0.status == .paid }
            .reduce(0) { $0 + $1.amount }
    }

    var pendingPaymentsCount: Int {
        payments.filter { $0.status == .pending || $0.status == .overdue }.count
    }

    var occupancyRate: Double {
        guard !properties.isEmpty else { return 0 }
        let activeLeasePropertyIds = Set(
            leases.filter { $0.status == .active }.map(\.propertyId)
        )
        let rented = properties.filter { property in
            guard let id = property.id else { return false }
            return activeLeasePropertyIds.contains(id)
        }.count
        return Double(rented) / Double(properties.count) * 100
    }

    var activeTenants: Int {
        tenants.filter { $0.status == .active }.count
    }

    var recentPayments: [Payment] {
        Array(payments.sorted { $0.date > $1.date }.prefix(5))
    }

    func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            do {
                async let propertiesResult: [Property] = firestoreService.readAll(
                    from: "properties",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                async let tenantsResult: [Tenant] = firestoreService.readAll(
                    from: "tenants",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                async let paymentsResult: [Payment] = firestoreService.readAll(
                    from: "payments",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                async let leasesResult: [Lease] = firestoreService.readAll(
                    from: "leases",
                    whereField: "ownerId",
                    isEqualTo: userId
                )

                properties = try await propertiesResult
                tenants = try await tenantsResult
                payments = try await paymentsResult
                leases = try await leasesResult
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
