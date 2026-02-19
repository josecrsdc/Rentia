import FirebaseFirestore
import Foundation

final class FirestoreService: Sendable {
    private let database = Firestore.firestore()

    nonisolated func create<T: Codable>(
        _ item: T,
        in collection: String
    ) async throws -> String {
        let document = database.collection(collection).document()
        try document.setData(from: item)
        return document.documentID
    }

    nonisolated func createWithID<T: Codable>(
        _ item: T,
        id: String,
        in collection: String
    ) async throws {
        let document = database.collection(collection).document(id)
        try document.setData(from: item)
    }

    nonisolated func read<T: Codable>(
        id: String,
        from collection: String
    ) async throws -> T {
        let document = try await database.collection(collection).document(id).getDocument()
        return try document.data(as: T.self)
    }

    nonisolated func readAll<T: Codable>(
        from collection: String,
        whereField field: String,
        isEqualTo value: Any
    ) async throws -> [T] {
        let snapshot = try await database
            .collection(collection)
            .whereField(field, isEqualTo: value)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            try? document.data(as: T.self)
        }
    }

    nonisolated func update<T: Codable>(
        _ item: T,
        id: String,
        in collection: String
    ) async throws {
        let document = database.collection(collection).document(id)
        try document.setData(from: item, merge: true)
    }

    nonisolated func delete(
        id: String,
        from collection: String
    ) async throws {
        try await database.collection(collection).document(id).delete()
    }
}
