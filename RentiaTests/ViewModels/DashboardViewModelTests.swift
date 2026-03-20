import Foundation
import Testing
@testable import Rentia

@Suite("DashboardViewModel")
@MainActor
struct DashboardViewModelTests {
    // MARK: - Helpers

    private func makeVM() -> DashboardViewModel {
        DashboardViewModel(firestoreService: MockFirestoreService())
    }

    private func payment(status: PaymentStatus, amount: Double = 500, daysAgo: Int = 0) -> Payment {
        Payment(
            id: UUID().uuidString,
            ownerId: "o1",
            tenantId: "t1",
            propertyId: "p1",
            amount: amount,
            date: Date(timeIntervalSinceNow: -Double(daysAgo) * 86400),
            dueDate: Date(),
            status: status,
            paymentMethod: nil,
            notes: nil,
            createdAt: Date()
        )
    }

    private func property(id: String = "p1") -> Property {
        Property(
            id: id,
            ownerId: "o1",
            name: "Piso \(id)",
            address: .empty,
            cadastralReference: nil,
            type: .apartment,
            currency: "EUR",
            status: .available,
            description: nil,
            rooms: 2,
            bathrooms: 1,
            area: nil,
            administratorId: nil,
            imageURLs: [],
            createdAt: Date()
        )
    }

    private func tenant(status: TenantStatus) -> Tenant {
        Tenant(
            id: UUID().uuidString,
            ownerId: "o1",
            firstName: "Test",
            lastName: "User",
            email: "t@test.com",
            phone: "600000000",
            status: status,
            createdAt: Date()
        )
    }

    private func lease(propertyId: String, status: LeaseStatus) -> Lease {
        Lease(
            id: UUID().uuidString,
            ownerId: "o1",
            propertyId: propertyId,
            tenantId: "t1",
            startDate: Date(),
            endDate: Date(timeIntervalSinceNow: 86400 * 365),
            rentAmount: 800,
            depositAmount: 1600,
            billingDay: 5,
            utilitiesMode: .included,
            status: status,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - totalMonthlyIncome

    @Test func totalMonthlyIncomeOnlyCountsPaid() {
        let vm = makeVM()
        vm.payments = [
            payment(status: .paid, amount: 800),
            payment(status: .paid, amount: 500),
            payment(status: .pending, amount: 300),
            payment(status: .overdue, amount: 200),
        ]
        #expect(vm.totalMonthlyIncome == 1300)
    }

    @Test func totalMonthlyIncomeEmptyReturnsZero() {
        let vm = makeVM()
        vm.payments = []
        #expect(vm.totalMonthlyIncome == 0)
    }

    // MARK: - pendingPaymentsCount

    @Test func pendingPaymentsCountIncludesPendingAndOverdue() {
        let vm = makeVM()
        vm.payments = [
            payment(status: .pending),
            payment(status: .overdue),
            payment(status: .paid),
            payment(status: .partial),
        ]
        #expect(vm.pendingPaymentsCount == 2)
    }

    @Test func pendingPaymentsCountExcludesPaidAndPartial() {
        let vm = makeVM()
        vm.payments = [
            payment(status: .paid),
            payment(status: .partial),
        ]
        #expect(vm.pendingPaymentsCount == 0)
    }

    // MARK: - occupancyRate

    @Test func occupancyRateZeroWhenNoProperties() {
        let vm = makeVM()
        vm.properties = []
        vm.leases = []
        #expect(vm.occupancyRate == 0)
    }

    @Test func occupancyRateHundredWhenAllOccupied() {
        let vm = makeVM()
        vm.properties = [property(id: "p1"), property(id: "p2")]
        vm.leases = [
            lease(propertyId: "p1", status: .active),
            lease(propertyId: "p2", status: .active),
        ]
        #expect(vm.occupancyRate == 100)
    }

    @Test func occupancyRateHalfWhenHalfOccupied() {
        let vm = makeVM()
        vm.properties = [property(id: "p1"), property(id: "p2")]
        vm.leases = [lease(propertyId: "p1", status: .active)]
        #expect(vm.occupancyRate == 50)
    }

    @Test func occupancyRateIgnoresExpiredLeases() {
        let vm = makeVM()
        vm.properties = [property(id: "p1")]
        vm.leases = [lease(propertyId: "p1", status: .expired)]
        #expect(vm.occupancyRate == 0)
    }

    // MARK: - activeTenants

    @Test func activeTenantsOnlyCountsActiveTenants() {
        let vm = makeVM()
        vm.tenants = [
            tenant(status: .active),
            tenant(status: .active),
            tenant(status: .inactive),
        ]
        #expect(vm.activeTenants == 2)
    }

    @Test func activeTenantsZeroWhenNone() {
        let vm = makeVM()
        vm.tenants = [tenant(status: .inactive)]
        #expect(vm.activeTenants == 0)
    }

    // MARK: - recentPayments

    @Test func recentPaymentsLimitedToFive() {
        let vm = makeVM()
        vm.payments = (1...8).map { payment(status: .paid, daysAgo: $0) }
        #expect(vm.recentPayments.count == 5)
    }

    @Test func recentPaymentsSortedDescending() {
        let vm = makeVM()
        vm.payments = [
            payment(status: .paid, daysAgo: 5),
            payment(status: .paid, daysAgo: 1),
            payment(status: .paid, daysAgo: 3),
        ]
        let dates = vm.recentPayments.map(\.date)
        #expect(dates == dates.sorted(by: >))
    }
}
