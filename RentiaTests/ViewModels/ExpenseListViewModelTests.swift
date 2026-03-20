import Testing
import Foundation
@testable import Rentia

@Suite("ExpenseListViewModel")
@MainActor
struct ExpenseListViewModelTests {
    private func makeVM() -> (ExpenseListViewModel, MockFirestoreService) {
        let firestore = MockFirestoreService()
        return (ExpenseListViewModel(propertyId: "p1", firestoreService: firestore), firestore)
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
        let (vm, _) = makeVM()
        vm.expenses = [expense(category: .repair), expense(category: .ibi), expense(category: .utilities)]
        vm.selectedCategory = nil
        #expect(vm.filteredExpenses.count == 3)
    }

    @Test func filteredExpensesWithCategoryFiltersCorrectly() {
        let (vm, _) = makeVM()
        vm.expenses = [expense(category: .repair), expense(category: .ibi), expense(category: .repair)]
        vm.selectedCategory = .repair
        #expect(vm.filteredExpenses.count == 2)
    }

    @Test func filteredExpensesWithNoMatchReturnsEmpty() {
        let (vm, _) = makeVM()
        vm.expenses = [expense(category: .repair), expense(category: .ibi)]
        vm.selectedCategory = .mortgage
        #expect(vm.filteredExpenses.isEmpty)
    }

    // MARK: - totalAmount

    @Test func totalAmountSumsFilteredExpenses() {
        let (vm, _) = makeVM()
        vm.expenses = [expense(category: .repair, amount: 200), expense(category: .ibi, amount: 300)]
        vm.selectedCategory = nil
        #expect(vm.totalAmount == 500)
    }

    @Test func totalAmountEmptyIsZero() {
        let (vm, _) = makeVM()
        vm.expenses = []
        #expect(vm.totalAmount == 0)
    }

    @Test func totalAmountWithFilteredCategory() {
        let (vm, _) = makeVM()
        vm.expenses = [
            expense(category: .repair, amount: 200),
            expense(category: .ibi, amount: 300),
        ]
        vm.selectedCategory = .repair
        #expect(vm.totalAmount == 200)
    }

    @Test func totalAmountNilCategorySumsAll() {
        let (vm, _) = makeVM()
        vm.expenses = [
            expense(category: .repair, amount: 100),
            expense(category: .ibi, amount: 200),
            expense(category: .utilities, amount: 50),
        ]
        vm.selectedCategory = nil
        #expect(vm.totalAmount == 350)
    }

    @Test func deleteExpenseWithNilIDDoesNothing() async {
        let (vm, firestore) = makeVM()
        let expenseWithoutID = Expense(
            id: nil,
            ownerId: "o1",
            propertyId: "p1",
            date: Date(),
            amount: 100,
            category: .repair,
            description: "No ID",
            receiptURL: nil,
            createdAt: Date()
        )
        vm.expenses = [expense(category: .repair)]
        vm.delete(expense: expenseWithoutID)
        await Task.yield()
        #expect(firestore.deleteCallCount == 0)
        #expect(vm.expenses.count == 1)
    }

    @Test func deleteExpenseOnSuccessRemovesItem() async {
        let (vm, firestore) = makeVM()
        let toDelete = expense(category: .repair)
        let keep = expense(category: .ibi)
        vm.expenses = [toDelete, keep]
        vm.delete(expense: toDelete)
        await Task.yield()
        #expect(firestore.deleteCallCount == 1)
        #expect(firestore.lastDeletedId == toDelete.id)
        #expect(vm.expenses.count == 1)
        #expect(vm.expenses.first?.id == keep.id)
    }

    @Test func deleteExpenseOnFailureShowsError() async {
        let (vm, firestore) = makeVM()
        firestore.shouldThrow = true
        let toDelete = expense(category: .repair)
        vm.expenses = [toDelete]
        vm.delete(expense: toDelete)
        await Task.yield()
        #expect(vm.showError == true)
        #expect(vm.errorMessage != nil)
        #expect(vm.expenses.count == 1)
    }
}
