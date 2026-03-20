import Foundation

protocol FirestoreServiceProtocol: Sendable {
    func create<T: Codable>(_ item: T, in collection: String) async throws -> String
    func createWithID<T: Codable>(_ item: T, id: String, in collection: String) async throws
    func read<T: Codable>(id: String, from collection: String) async throws -> T
    func readAll<T: Codable>(
        from collection: String,
        whereField field: String,
        isEqualTo value: Any
    ) async throws -> [T]
    func readAll<T: Codable>(
        from collection: String,
        whereField field: String,
        arrayContains value: Any
    ) async throws -> [T]
    func readAll<T: Codable>(
        from collection: String,
        whereField field1: String,
        isEqualTo value1: Any,
        whereField field2: String,
        isEqualTo value2: Any
    ) async throws -> [T]
    func readAll<T: Codable>(
        from collection: String,
        whereField field1: String,
        arrayContains value1: Any,
        whereField field2: String,
        isEqualTo value2: Any
    ) async throws -> [T]
    func update<T: Codable>(_ item: T, id: String, in collection: String) async throws
    func delete(id: String, from collection: String) async throws
}
