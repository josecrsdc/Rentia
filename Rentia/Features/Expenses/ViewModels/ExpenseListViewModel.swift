import FirebaseAuth
import Foundation

@MainActor
@Observable
final class ExpenseListViewModel {
    var expenses: [Expense] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var selectedCategory: ExpenseCategory?

    private let firestoreService: any FirestoreServiceProtocol
    private var loadTask: Task<Void, Never>?
    let propertyId: String

    init(propertyId: String, firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.propertyId = propertyId
        self.firestoreService = firestoreService
    }

    var filteredExpenses: [Expense] {
        guard let category = selectedCategory else { return expenses }
        return expenses.filter { $0.category == category }
    }

    var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    func loadExpenses() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        loadTask?.cancel()
        isLoading = true

        loadTask = Task {
            let result: [Expense] = (
                try? await firestoreService.readAll(
                    from: "expenses",
                    whereField: "propertyId",
                    isEqualTo: propertyId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            guard !Task.isCancelled else { return }
            expenses = result.sorted { $0.date > $1.date }
            isLoading = false
        }
    }

    func delete(expense: Expense) {
        guard let id = expense.id else { return }

        Task {
            do {
                try await firestoreService.delete(id: id, from: "expenses")
                expenses.removeAll { $0.id == id }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
