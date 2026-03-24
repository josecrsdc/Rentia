import Foundation

protocol PaymentGenerationServiceProtocol: Sendable {
    func generatePayments(for lease: Lease, leaseId: String, ownerId: String) async throws -> Int
}

extension PaymentGenerationService: PaymentGenerationServiceProtocol {}
