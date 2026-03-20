import Testing
import Foundation
@testable import Rentia

@Suite("ExpenseListViewModel")
@MainActor
struct ExpenseListViewModelTests {
    private func makeVM() -> ExpenseListViewModel {
        ExpenseListViewModel(propertyId: "p1", firestoreService: MockFirestoreService())
    }

    private func expense(category: ExpenseCategory, amount: Double = 100) -> Expense {
        Expense(
            id: UUID().uuidString,
            ownerId: "o1",
            propertyId: "p1",
            date: Date(),
            amount: amount,
            category: category,
            description: "Test expense",
            receiptURL: nil,
            createdAt: Date()
        )
    }

    // MARK: - filteredExpenses

    @Test func filteredExpensesNilCategoryReturnsAll() {
        let vm = makeVM()
        vm.expenses = [expense(category: .repair), expense(category: .ibi), expense(category: .utilities)]
        vm.selectedCategory = nil
        #expect(vm.filteredExpenses.count == 3)
    }

    @Test func filteredExpensesWithCategoryFiltersCorrectly() {
        let vm = makeVM()
        vm.expenses = [expense(category: .repair), expense(category: .ibi), expense(category: .repair)]
        vm.selectedCategory = .repair
        #expect(vm.filteredExpenses.count == 2)
    }

    @Test func filteredExpensesWithNoMatchReturnsEmpty() {
        let vm = makeVM()
        vm.expenses = [expense(category: .repair), expense(category: .ibi)]
        vm.selectedCategory = .mortgage
        #expect(vm.filteredExpenses.isEmpty)
    }

    // MARK: - totalAmount

    @Test func totalAmountSumsFilteredExpenses() {
        let vm = makeVM()
        vm.expenses = [expense(category: .repair, amount: 200), expense(category: .ibi, amount: 300)]
        vm.selectedCategory = nil
        #expect(vm.totalAmount == 500)
    }

    @Test func totalAmountEmptyIsZero() {
        let vm = makeVM()
        vm.expenses = []
        #expect(vm.totalAmount == 0)
    }

    @Test func totalAmountWithFilteredCategory() {
        let vm = makeVM()
        vm.expenses = [
            expense(category: .repair, amount: 200),
            expense(category: .ibi, amount: 300),
        ]
        vm.selectedCategory = .repair
        #expect(vm.totalAmount == 200)
    }

    @Test func totalAmountNilCategorySumsAll() {
        let vm = makeVM()
        vm.expenses = [
            expense(category: .repair, amount: 100),
            expense(category: .ibi, amount: 200),
            expense(category: .utilities, amount: 50),
        ]
        vm.selectedCategory = nil
        #expect(vm.totalAmount == 350)
    }
}
