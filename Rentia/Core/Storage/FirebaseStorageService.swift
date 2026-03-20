import FirebaseStorage
import Foundation
import UIKit

final class FirebaseStorageService: Sendable {
    private let storage = Storage.storage()

    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw FirebaseStorageError.compressionFailed
        }
        return try await uploadData(data, path: path, contentType: "image/jpeg")
    }

    func uploadData(_ data: Data, path: String, contentType: String) async throws -> String {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    func delete(url: String) async throws {
        let ref = storage.reference(forURL: url)
        try await ref.delete()
    }
}

enum FirebaseStorageError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed: String(localized: "storage.error.compression_failed")
        }
    }
}
