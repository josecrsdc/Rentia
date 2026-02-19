import FirebaseAuth
import Foundation

@Observable
final class PaymentFormViewModel {
    var tenantId = ""
    var propertyId = ""
    var amount = ""
    var date = Date()
    var dueDate = Date()
    var status: PaymentStatus = .pending
    var paymentMethod = ""
    var notes = ""
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var didSave = false

    var tenants: [Tenant] = []
    var properties: [Property] = []

    private let firestoreService = FirestoreService()
    private var editingPaymentId: String?

    var isEditing: Bool {
        editingPaymentId != nil
    }

    var isFormValid: Bool {
        tenantId.isNotEmpty
        && propertyId.isNotEmpty
        && (Double(amount) ?? 0) > 0
    }

    func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                async let tenantsResult: [Tenant] = firestoreService.readAll(
                    from: "tenants",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                async let propertiesResult: [Property] = firestoreService.readAll(
                    from: "properties",
                    whereField: "ownerId",
                    isEqualTo: userId
                )

                tenants = try await tenantsResult
                properties = try await propertiesResult
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    func loadPayment(id: String) {
        editingPaymentId = id
        isLoading = true

        Task {
            do {
                let payment: Payment = try await firestoreService.read(
                    id: id,
                    from: "payments"
                )
                tenantId = payment.tenantId
                propertyId = payment.propertyId
                amount = String(format: "%.2f", payment.amount)
                date = payment.date
                dueDate = payment.dueDate
                status = payment.status
                paymentMethod = payment.paymentMethod ?? ""
                notes = payment.notes ?? ""
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func save() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        let payment = Payment(
            id: editingPaymentId,
            ownerId: userId,
            tenantId: tenantId,
            propertyId: propertyId,
            amount: Double(amount) ?? 0,
            date: date,
            dueDate: dueDate,
            status: status,
            paymentMethod: paymentMethod.trimmed.isEmpty
                ? nil : paymentMethod.trimmed,
            notes: notes.trimmed.isEmpty ? nil : notes.trimmed,
            createdAt: Date()
        )

        Task {
            do {
                if let paymentId = editingPaymentId {
                    try await firestoreService.update(
                        payment,
                        id: paymentId,
                        in: "payments"
                    )
                } else {
                    _ = try await firestoreService.create(
                        payment,
                        in: "payments"
                    )
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
