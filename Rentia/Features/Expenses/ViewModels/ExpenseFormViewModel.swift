import FirebaseAuth
import Foundation

@MainActor
@Observable
final class ExpenseFormViewModel {
    var amount = ""
    var category: ExpenseCategory = .other
    var description = ""
    var date = Date()
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var didSave = false

    private let firestoreService: any FirestoreServiceProtocol
    private let propertyId: String
    private var editingExpenseId: String?
    private var originalCreatedAt = Date()

    var isEditing: Bool { editingExpenseId != nil }

    var isFormValid: Bool {
        amount.isNotEmpty
            && (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
            && description.isNotEmpty
    }

    init(propertyId: String, firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.propertyId = propertyId
        self.firestoreService = firestoreService
    }

    func loadExpense(id: String) {
        editingExpenseId = id
        isLoading = true

        Task {
            do {
                let expense: Expense = try await firestoreService.read(id: id, from: "expenses")
                amount = String(format: "%.2f", expense.amount)
                category = expense.category
                description = expense.description
                date = expense.date
                originalCreatedAt = expense.createdAt
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func save() {
        guard
            let userId = Auth.auth().currentUser?.uid,
            let amountValue = Double(amount.replacingOccurrences(of: ",", with: "."))
        else { return }

        isLoading = true

        let expense = Expense(
            id: editingExpenseId,
            ownerId: userId,
            propertyId: propertyId,
            date: date,
            amount: amountValue,
            category: category,
            description: description.trimmed,
            receiptURL: nil,
            createdAt: originalCreatedAt
        )

        Task {
            do {
                if let id = editingExpenseId {
                    try await firestoreService.update(expense, id: id, in: "expenses")
                } else {
                    _ = try await firestoreService.create(expense, in: "expenses")
                }
                didSave = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
