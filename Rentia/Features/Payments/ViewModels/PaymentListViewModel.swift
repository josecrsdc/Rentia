import FirebaseAuth
import Foundation

@Observable
final class PaymentListViewModel {
    var payments: [Payment] = []
    var properties: [Property] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var selectedFilter: PaymentStatus?
    var selectedPropertyIds: Set<String> = []
    var isSelecting = false
    var selectedPaymentIds: Set<String> = []

    private let firestoreService: any FirestoreServiceProtocol

    init(firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    var filteredPayments: [Payment] {
        var result = payments

        if let filter = selectedFilter {
            result = result.filter { $0.status == filter }
        }

        if !selectedPropertyIds.isEmpty {
            result = result.filter { selectedPropertyIds.contains($0.propertyId) }
        }

        return result.sorted { $0.date > $1.date }
    }

    func loadPayments() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            do {
                async let fetchedPayments: [Payment] = firestoreService.readAll(
                    from: "payments",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                async let fetchedProperties: [Property] = firestoreService.readAll(
                    from: "properties",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                payments = try await fetchedPayments
                properties = try await fetchedProperties
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

    func togglePaymentSelection(_ payment: Payment) {
        guard let paymentId = payment.id else { return }
        if selectedPaymentIds.contains(paymentId) {
            selectedPaymentIds.remove(paymentId)
        } else {
            selectedPaymentIds.insert(paymentId)
        }
    }

    func updateStatusForSelected(to status: PaymentStatus) {
        let idsToUpdate = selectedPaymentIds
        guard !idsToUpdate.isEmpty else { return }

        Task {
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for paymentId in idsToUpdate {
                        guard var payment = payments.first(where: { $0.id == paymentId }) else {
                            continue
                        }
                        payment.status = status
                        let capturedPayment = payment
                        group.addTask {
                            try await self.firestoreService.update(
                                capturedPayment,
                                id: paymentId,
                                in: "payments"
                            )
                        }
                    }
                    try await group.waitForAll()
                }
                for id in idsToUpdate {
                    if let index = payments.firstIndex(where: { $0.id == id }) {
                        payments[index].status = status
                    }
                }
                selectedPaymentIds = []
                isSelecting = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
