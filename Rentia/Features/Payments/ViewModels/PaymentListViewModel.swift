import FirebaseAuth
import Foundation

@Observable
final class PaymentListViewModel {
    var payments: [Payment] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var selectedFilter: PaymentStatus?

    private let firestoreService = FirestoreService()

    var filteredPayments: [Payment] {
        var result = payments

        if let filter = selectedFilter {
            result = result.filter { $0.status == filter }
        }

        return result.sorted { $0.date > $1.date }
    }

    func loadPayments() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            do {
                payments = try await firestoreService.readAll(
                    from: "payments",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func deletePayment(_ payment: Payment) {
        guard let paymentId = payment.id else { return }

        Task {
            do {
                try await firestoreService.delete(
                    id: paymentId,
                    from: "payments"
                )
                payments.removeAll { $0.id == paymentId }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
