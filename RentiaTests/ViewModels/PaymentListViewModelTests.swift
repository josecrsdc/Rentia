import Foundation
import Testing
@testable import Rentia

@Suite("PaymentListViewModel")
@MainActor
struct PaymentListViewModelTests {
    private func makeVM() -> (PaymentListViewModel, MockFirestoreService) {
        let firestore = MockFirestoreService()
        return (PaymentListViewModel(firestoreService: firestore), firestore)
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
        let (vm, _) = makeVM()
        vm.payments = [payment(status: .paid), payment(status: .pending), payment(status: .overdue)]
        vm.selectedFilter = nil
        #expect(vm.filteredPayments.count == 3)
    }

    @Test func filteredPaymentsByPaid() {
        let (vm, _) = makeVM()
        vm.payments = [payment(status: .paid), payment(status: .paid), payment(status: .pending)]
        vm.selectedFilter = .paid
        #expect(vm.filteredPayments.count == 2)
    }

    @Test func filteredPaymentsByOverdue() {
        let (vm, _) = makeVM()
        vm.payments = [payment(status: .overdue), payment(status: .paid), payment(status: .pending)]
        vm.selectedFilter = .overdue
        #expect(vm.filteredPayments.count == 1)
    }

    @Test func filteredPaymentsNoMatchReturnsEmpty() {
        let (vm, _) = makeVM()
        vm.payments = [payment(status: .paid), payment(status: .pending)]
        vm.selectedFilter = .partial
        #expect(vm.filteredPayments.isEmpty)
    }

    // MARK: - Ordering

    @Test func filteredPaymentsSortedDescending() {
        let (vm, _) = makeVM()
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
        let (vm, _) = makeVM()
        vm.payments = [
            payment(status: .paid, daysAgo: 10),
            payment(status: .paid, daysAgo: 2),
            payment(status: .overdue, daysAgo: 5),
        ]
        vm.selectedFilter = .paid
        let dates = vm.filteredPayments.map(\.date)
        #expect(dates == dates.sorted(by: >))
    }

    @Test func deletePaymentWithNilIDDoesNothing() async {
        let (vm, firestore) = makeVM()
        let paymentWithoutID = Payment(
            id: nil,
            ownerId: "o1",
            tenantId: "t1",
            propertyId: "p1",
            amount: 100,
            date: Date(),
            dueDate: Date(),
            status: .paid,
            paymentMethod: nil,
            notes: nil,
            createdAt: Date()
        )
        vm.payments = [payment(status: .paid)]
        vm.deletePayment(paymentWithoutID)
        await Task.yield()
        #expect(firestore.deleteCallCount == 0)
        #expect(vm.payments.count == 1)
    }

    @Test func deletePaymentOnSuccessRemovesItem() async {
        let (vm, firestore) = makeVM()
        let toDelete = payment(status: .paid)
        let keep = payment(status: .pending)
        vm.payments = [toDelete, keep]
        vm.deletePayment(toDelete)
        await Task.yield()
        #expect(firestore.deleteCallCount == 1)
        #expect(firestore.lastDeletedId == toDelete.id)
        #expect(vm.payments.count == 1)
        #expect(vm.payments.first?.id == keep.id)
    }

    @Test func deletePaymentOnFailureShowsError() async {
        let (vm, firestore) = makeVM()
        firestore.shouldThrow = true
        let toDelete = payment(status: .paid)
        vm.payments = [toDelete]
        vm.deletePayment(toDelete)
        await Task.yield()
        #expect(vm.showError == true)
        #expect(vm.errorMessage != nil)
        #expect(vm.payments.count == 1)
    }
}
