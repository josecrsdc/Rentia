import Testing
import Foundation
@testable import Rentia

@Suite("TenantDebt")
struct TenantDebtTests {
    private func makeTenant() -> Tenant {
        Tenant(
            id: "t1",
            ownerId: "owner1",
            firstName: "Ana",
            lastName: "García",
            email: "ana@test.com",
            phone: "600000000",
            status: .active,
            createdAt: Date()
        )
    }

    private func makePayment(status: PaymentStatus, amount: Double = 500) -> Payment {
        Payment(
            id: UUID().uuidString,
            ownerId: "owner1",
            tenantId: "t1",
            propertyId: "p1",
            amount: amount,
            date: Date(),
            dueDate: Date(),
            status: status,
            paymentMethod: nil,
            notes: nil,
            createdAt: Date()
        )
    }

    // MARK: - totalDebt

    @Test func totalDebtSumsPendingAndOverdueAndPartial() {
        let debt = TenantDebt(tenant: makeTenant(), payments: [
            makePayment(status: .pending, amount: 500),
            makePayment(status: .overdue, amount: 300),
            makePayment(status: .partial, amount: 200),
            makePayment(status: .paid, amount: 1000),
        ])
        #expect(debt.totalDebt == 1000)
    }

    @Test func totalDebtExcludesPaid() {
        let debt = TenantDebt(tenant: makeTenant(), payments: [
            makePayment(status: .paid, amount: 1000),
        ])
        #expect(debt.totalDebt == 0)
    }

    @Test func totalDebtEmptyPayments() {
        let debt = TenantDebt(tenant: makeTenant(), payments: [])
        #expect(debt.totalDebt == 0)
    }

    // MARK: - overdueCount

    @Test func overdueCountOnlyCountsOverdue() {
        let debt = TenantDebt(tenant: makeTenant(), payments: [
            makePayment(status: .overdue),
            makePayment(status: .overdue),
            makePayment(status: .pending),
            makePayment(status: .paid),
        ])
        #expect(debt.overdueCount == 2)
    }

    // MARK: - pendingCount

    @Test func pendingCountIncludesPendingAndPartial() {
        let debt = TenantDebt(tenant: makeTenant(), payments: [
            makePayment(status: .pending),
            makePayment(status: .partial),
            makePayment(status: .overdue),
            makePayment(status: .paid),
        ])
        #expect(debt.pendingCount == 2)
    }

    @Test func pendingCountZeroWhenNone() {
        let debt = TenantDebt(tenant: makeTenant(), payments: [
            makePayment(status: .paid),
        ])
        #expect(debt.pendingCount == 0)
    }
}
