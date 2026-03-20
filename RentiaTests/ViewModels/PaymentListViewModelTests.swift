import Foundation
import Testing
@testable import Rentia

@Suite("PaymentListViewModel")
@MainActor
struct PaymentListViewModelTests {
    private func makeVM() -> PaymentListViewModel {
        PaymentListViewModel(firestoreService: MockFirestoreService())
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

    // MARK: - filteredPayments

    @Test func filteredPaymentsNilFilterReturnsAll() {
        let vm = makeVM()
        vm.payments = [payment(status: .paid), payment(status: .pending), payment(status: .overdue)]
        vm.selectedFilter = nil
        #expect(vm.filteredPayments.count == 3)
    }

    @Test func filteredPaymentsByPaid() {
        let vm = makeVM()
        vm.payments = [payment(status: .paid), payment(status: .paid), payment(status: .pending)]
        vm.selectedFilter = .paid
        #expect(vm.filteredPayments.count == 2)
    }

    @Test func filteredPaymentsByOverdue() {
        let vm = makeVM()
        vm.payments = [payment(status: .overdue), payment(status: .paid), payment(status: .pending)]
        vm.selectedFilter = .overdue
        #expect(vm.filteredPayments.count == 1)
    }

    @Test func filteredPaymentsNoMatchReturnsEmpty() {
        let vm = makeVM()
        vm.payments = [payment(status: .paid), payment(status: .pending)]
        vm.selectedFilter = .partial
        #expect(vm.filteredPayments.isEmpty)
    }

    // MARK: - Ordering

    @Test func filteredPaymentsSortedDescending() {
        let vm = makeVM()
        vm.payments = [
            payment(status: .paid, daysAgo: 5),
            payment(status: .paid, daysAgo: 1),
            payment(status: .paid, daysAgo: 3),
        ]
        vm.selectedFilter = nil
        let dates = vm.filteredPayments.map(\.date)
        #expect(dates == dates.sorted(by: >))
    }

    @Test func filteredPaymentsSortedDescendingWithFilter() {
        let vm = makeVM()
        vm.payments = [
            payment(status: .paid, daysAgo: 10),
            payment(status: .paid, daysAgo: 2),
            payment(status: .overdue, daysAgo: 5),
        ]
        vm.selectedFilter = .paid
        let dates = vm.filteredPayments.map(\.date)
        #expect(dates == dates.sorted(by: >))
    }
}
