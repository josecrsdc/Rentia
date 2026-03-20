import Foundation
import UIKit

protocol StorageServiceProtocol: Sendable {
    func uploadImage(_ image: UIImage, path: String) async throws -> String
    func uploadData(_ data: Data, path: String, contentType: String) async throws -> String
    func delete(url: String) async throws
}
