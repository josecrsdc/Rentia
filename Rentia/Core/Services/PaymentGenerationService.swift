import Foundation

final class PaymentGenerationService: Sendable {
    private let firestoreService = FirestoreService()

    nonisolated func generatePayments(
        for lease: Lease,
        leaseId: String,
        ownerId: String
    ) async throws -> Int {
        let covered = await coveredMonths(for: leaseId)
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

            guard !covered.contains("\(year)-\(month)") else {
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? endDate
                continue
            }

            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = min(lease.billingDay, 28)

            if let dueDate = calendar.date(from: components) {
                payments.append(Payment(
                    ownerId: ownerId,
                    tenantId: lease.tenantId,
                    propertyId: lease.propertyId,
                    leaseId: leaseId,
                    amount: lease.rentAmount,
                    date: dueDate,
                    dueDate: dueDate,
                    status: .pending,
                    createdAt: Date()
                ))
            }

            guard let nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        for payment in payments {
            _ = try await firestoreService.create(payment, in: "payments")
        }
        return payments.count
    }

    nonisolated private func coveredMonths(for leaseId: String) async -> Set<String> {
        let existing: [Payment] = (
            try? await firestoreService.readAll(
                from: "payments",
                whereField: "leaseId",
                isEqualTo: leaseId
            )
        ) ?? []
        let calendar = Calendar.current
        return Set(existing.map { payment in
            let comps = calendar.dateComponents([.year, .month], from: payment.dueDate)
            return "\(comps.year ?? 0)-\(comps.month ?? 0)"
        })
    }
}
