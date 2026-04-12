import FirebaseAuth
import Foundation

// MARK: - Dashboard Period

enum DashboardPeriod: Equatable {
    case month(Date)
    case year(Int)
}

// MARK: - ViewModel

@Observable
final class DashboardViewModel {
    var properties: [Property] = []
    var tenants: [Tenant] = []
    var payments: [Payment] = []
    var leases: [Lease] = []
    var isLoading = false
    var errorMessage: String?

    var selectedPeriod: DashboardPeriod = .month(Calendar.current.startOfMonth(for: Date()))

    private let firestoreService: any FirestoreServiceProtocol

    init(firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    // MARK: - Period navigation

    var periodTitle: String {
        switch selectedPeriod {
        case .month(let date):
            Self.monthFormatter.string(from: date).capitalized
        case .year(let year):
            String(year)
        }
    }

    var isMonthMode: Bool {
        if case .month = selectedPeriod { return true }
        return false
    }

    func previousPeriod() {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .month(let date):
            let prev = calendar.date(byAdding: .month, value: -1, to: date) ?? date
            selectedPeriod = .month(calendar.startOfMonth(for: prev))
        case .year(let year):
            selectedPeriod = .year(year - 1)
        }
    }

    func nextPeriod() {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .month(let date):
            let next = calendar.date(byAdding: .month, value: 1, to: date) ?? date
            selectedPeriod = .month(calendar.startOfMonth(for: next))
        case .year(let year):
            selectedPeriod = .year(year + 1)
        }
    }

    func switchToMonthMode() {
        guard case .year = selectedPeriod else { return }
        selectedPeriod = .month(Calendar.current.startOfMonth(for: Date()))
    }

    func switchToYearMode() {
        guard case .month = selectedPeriod else { return }
        selectedPeriod = .year(Calendar.current.component(.year, from: Date()))
    }

    // MARK: - Computed metrics (respetan selectedPeriod)

    var totalMonthlyIncome: Double {
        payments
            .filter { $0.status == .paid && isInPeriod($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var pendingPaymentsCount: Int {
        payments
            .filter {
                ($0.status == .pending || $0.status == .overdue)
                    && isInPeriod($0.dueDate)
            }
            .count
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
        Array(
            payments
                .filter { isInPeriod($0.date) }
                .sorted { $0.date > $1.date }
                .prefix(5)
        )
    }

    // MARK: - Data loading

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

    // MARK: - Helpers

    private func isInPeriod(_ date: Date) -> Bool {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .month(let periodDate):
            return calendar.isDate(date, equalTo: periodDate, toGranularity: .month)
        case .year(let year):
            return calendar.component(.year, from: date) == year
        }
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return f
    }()
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
