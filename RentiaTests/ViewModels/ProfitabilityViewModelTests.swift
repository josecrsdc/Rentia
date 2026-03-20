import Foundation
import Testing
@testable import Rentia

@Suite("ProfitabilityViewModel")
@MainActor
struct ProfitabilityViewModelTests {
    private func makeVM(period: ReportPeriod = .month) -> ProfitabilityViewModel {
        let vm = ProfitabilityViewModel(propertyId: "p1", firestoreService: MockFirestoreService())
        vm.selectedPeriod = period
        return vm
    }

    private func payment(status: PaymentStatus, amount: Double, date: Date = Date()) -> Payment {
        Payment(
            id: UUID().uuidString,
            ownerId: "o1",
            tenantId: "t1",
            propertyId: "p1",
            amount: amount,
            date: date,
            dueDate: date,
            status: status,
            paymentMethod: nil,
            notes: nil,
            createdAt: Date()
        )
    }

    private func expense(amount: Double, date: Date = Date()) -> Expense {
        Expense(
            id: UUID().uuidString,
            ownerId: "o1",
            propertyId: "p1",
            date: date,
            amount: amount,
            category: .repair,
            description: "Test",
            receiptURL: nil,
            createdAt: Date()
        )
    }

    // MARK: - totalIncome (.month)

    @Test func totalIncomeMonthOnlyCountsPaidThisMonth() {
        let vm = makeVM(period: .month)
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        vm.payments = [
            payment(status: .paid, amount: 800),
            payment(status: .paid, amount: 500),
            payment(status: .pending, amount: 300),
            payment(status: .paid, amount: 200, date: lastYear),
        ]
        #expect(vm.totalIncome == 1300)
    }

    @Test func totalIncomeEmptyIsZero() {
        let vm = makeVM(period: .month)
        vm.payments = []
        #expect(vm.totalIncome == 0)
    }

    // MARK: - totalExpenses (.month)

    @Test func totalExpensesMonthOnlyCurrentMonth() {
        let vm = makeVM(period: .month)
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        vm.expenses = [
            expense(amount: 200),
            expense(amount: 100, date: lastYear),
        ]
        #expect(vm.totalExpenses == 200)
    }

    // MARK: - result

    @Test func resultIsIncomeMinusExpenses() {
        let vm = makeVM(period: .month)
        vm.payments = [payment(status: .paid, amount: 1000)]
        vm.expenses = [expense(amount: 300)]
        #expect(vm.result == 700)
    }

    // MARK: - resultIsPositive

    @Test func resultIsPositiveWhenPositive() {
        let vm = makeVM()
        vm.payments = [payment(status: .paid, amount: 1000)]
        vm.expenses = [expense(amount: 300)]
        #expect(vm.resultIsPositive == true)
    }

    @Test func resultIsPositiveWhenZero() {
        let vm = makeVM()
        vm.payments = [payment(status: .paid, amount: 500)]
        vm.expenses = [expense(amount: 500)]
        #expect(vm.resultIsPositive == true)
    }

    @Test func resultIsNotPositiveWhenNegative() {
        let vm = makeVM()
        vm.payments = [payment(status: .paid, amount: 200)]
        vm.expenses = [expense(amount: 500)]
        #expect(vm.resultIsPositive == false)
    }

    // MARK: - totalIncome (.year)

    @Test func totalIncomeYearIncludesWholeYear() {
        let vm = makeVM(period: .year)
        let currentYear = Calendar.current.component(.year, from: Date())
        let sameYearEarlier = Calendar.current.date(
            from: DateComponents(year: currentYear, month: 1, day: 15)
        )!
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        vm.payments = [
            payment(status: .paid, amount: 800, date: sameYearEarlier),
            payment(status: .paid, amount: 500),
            payment(status: .paid, amount: 200, date: lastYear),
        ]
        #expect(vm.totalIncome == 1300)
    }
}
