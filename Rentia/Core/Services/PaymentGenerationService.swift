import Foundation

final class PaymentGenerationService: Sendable {
    private let firestoreService = FirestoreService()

    nonisolated func generatePayments(
        for lease: Lease,
        leaseId: String,
        ownerId: String
    ) async throws -> Int {
        let calendar = Calendar.current
        let startDate = lease.startDate
        let endDate = lease.endDate
            ?? calendar.date(byAdding: .month, value: 12, to: startDate)
            ?? startDate

        var payments: [Payment] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let billingDay = min(lease.billingDay, 28)

            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = billingDay

            guard let dueDate = calendar.date(from: components) else {
                currentDate = calendar.date(
                    byAdding: .month,
                    value: 1,
                    to: currentDate
                ) ?? endDate
                continue
            }

            let payment = Payment(
                ownerId: ownerId,
                tenantId: lease.tenantId,
                propertyId: lease.propertyId,
                leaseId: leaseId,
                amount: lease.rentAmount,
                date: dueDate,
                dueDate: dueDate,
                status: .pending,
                createdAt: Date()
            )
            payments.append(payment)

            guard let nextDate = calendar.date(
                byAdding: .month,
                value: 1,
                to: currentDate
            ) else {
                break
            }
            currentDate = nextDate
        }

        for payment in payments {
            _ = try await firestoreService.create(
                payment,
                in: "payments"
            )
        }

        return payments.count
    }
}
