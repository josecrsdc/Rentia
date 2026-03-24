import Foundation
@testable import Rentia

enum TestError: Error {
    case generic
}

final class MockFirestoreService: FirestoreServiceProtocol, @unchecked Sendable {
    // MARK: - Configurable results (readAll)

    var propertiesResult: [Property] = []
    var tenantsResult: [Tenant] = []
    var paymentsResult: [Payment] = []
    var leasesResult: [Lease] = []
    var expensesResult: [Expense] = []

    // MARK: - Configurable results (read single)

    var leaseReadResult: Lease?
    var tenantReadResult: Tenant?
    var propertyReadResult: Property?
    var paymentReadResult: Payment?

    // MARK: - Error control

    var shouldThrow = false
    var errorToThrow: Error = TestError.generic

    // MARK: - Call tracking

    var readAllCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var lastDeletedId: String?
    var lastUpdatedId: String?

    // MARK: - Protocol

    func create<T: Codable>(_ item: T, in collection: String) async throws -> String {
        if shouldThrow { throw errorToThrow }
        return UUID().uuidString
    }

    func createWithID<T: Codable>(_ item: T, id: String, in collection: String) async throws {
        if shouldThrow { throw errorToThrow }
    }

    func read<T: Codable>(id: String, from collection: String) async throws -> T {
        if shouldThrow { throw errorToThrow }
        switch collection {
        case "leases":
            if let result = leaseReadResult as? T { return result }
        case "tenants":
            if let result = tenantReadResult as? T { return result }
        case "properties":
            if let result = propertyReadResult as? T { return result }
        case "payments":
            if let result = paymentReadResult as? T { return result }
        default:
            break
        }
        throw TestError.generic
    }

    func readAll<T: Codable>(
        from collection: String,
        whereField field: String,
        isEqualTo value: Any
    ) async throws -> [T] {
        readAllCallCount += 1
        if shouldThrow { throw errorToThrow }
        return try typedResult(for: collection)
    }

    func readAll<T: Codable>(
        from collection: String,
        whereField field: String,
        arrayContains value: Any
    ) async throws -> [T] {
        readAllCallCount += 1
        if shouldThrow { throw errorToThrow }
        return try typedResult(for: collection)
    }

    func readAll<T: Codable>(
        from collection: String,
        whereField field1: String,
        isEqualTo value1: Any,
        whereField field2: String,
        isEqualTo value2: Any
    ) async throws -> [T] {
        readAllCallCount += 1
        if shouldThrow { throw errorToThrow }
        return try typedResult(for: collection)
    }

    func readAll<T: Codable>(
        from collection: String,
        whereField field1: String,
        arrayContains value1: Any,
        whereField field2: String,
        isEqualTo value2: Any
    ) async throws -> [T] {
        readAllCallCount += 1
        if shouldThrow { throw errorToThrow }
        return try typedResult(for: collection)
    }

    func update<T: Codable>(_ item: T, id: String, in collection: String) async throws {
        updateCallCount += 1
        lastUpdatedId = id
        if shouldThrow { throw errorToThrow }
    }

    func delete(id: String, from collection: String) async throws {
        deleteCallCount += 1
        lastDeletedId = id
        if shouldThrow { throw errorToThrow }
    }

    // MARK: - Private dispatch

    private func typedResult<T: Codable>(for collection: String) throws -> [T] {
        switch collection {
        case "properties":
            return (propertiesResult as? [T]) ?? []
        case "tenants":
            return (tenantsResult as? [T]) ?? []
        case "payments":
            return (paymentsResult as? [T]) ?? []
        case "leases":
            return (leasesResult as? [T]) ?? []
        case "expenses":
            return (expensesResult as? [T]) ?? []
        default:
            return []
        }
    }
}
