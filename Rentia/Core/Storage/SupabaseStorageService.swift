import Foundation
import UIKit

final class SupabaseStorageService: StorageServiceProtocol {
    private let projectURL: String
    private let anonKey: String
    private let bucket: String

    init(
        projectURL: String = SupabaseConfig.projectURL,
        anonKey: String = SupabaseConfig.anonKey,
        bucket: String = SupabaseConfig.bucket
    ) {
        self.projectURL = projectURL
        self.anonKey = anonKey
        self.bucket = bucket
    }

    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw SupabaseStorageError.compressionFailed
        }
        return try await upload(data: data, path: path, contentType: "image/jpeg")
    }

    func uploadData(_ data: Data, path: String, contentType: String) async throws -> String {
        try await upload(data: data, path: path, contentType: contentType)
    }

    func delete(url: String) async throws {
        guard let path = extractPath(from: url) else {
            throw SupabaseStorageError.invalidURL
        }
        try await remove(path: path)
    }

    // MARK: - Private

    private func upload(data: Data, path: String, contentType: String) async throws -> String {
        guard let url = URL(string: "\(projectURL)/storage/v1/object/\(bucket)/\(path)") else {
            throw SupabaseStorageError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let message = String(data: responseData, encoding: .utf8) ?? "Error desconocido"
            throw SupabaseStorageError.uploadFailed(message)
        }
        return publicURL(for: path)
    }

    private func remove(path: String) async throws {
        guard let url = URL(string: "\(projectURL)/storage/v1/object/\(bucket)") else {
            throw SupabaseStorageError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["prefixes": [path]])

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let message = String(data: responseData, encoding: .utf8) ?? "Error desconocido"
            throw SupabaseStorageError.deleteFailed(message)
        }
    }

    private func publicURL(for path: String) -> String {
        "\(projectURL)/storage/v1/object/public/\(bucket)/\(path)"
    }

    /// Extrae el path relativo dentro del bucket desde una URL pública de Supabase.
    /// Formato: {projectURL}/storage/v1/object/public/{bucket}/{path}
    private func extractPath(from urlString: String) -> String? {
        let prefix = "\(projectURL)/storage/v1/object/public/\(bucket)/"
        guard urlString.hasPrefix(prefix) else { return nil }
        let path = String(urlString.dropFirst(prefix.count))
        return path.isEmpty ? nil : path
    }
}

// MARK: - Errors

enum SupabaseStorageError: LocalizedError {
    case compressionFailed
    case uploadFailed(String)
    case deleteFailed(String)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .compressionFailed: String(localized: "storage.error.compression_failed")
        case .uploadFailed(let msg): msg
        case .deleteFailed(let msg): msg
        case .invalidURL: String(localized: "storage.error.invalid_url")
        }
    }
}
