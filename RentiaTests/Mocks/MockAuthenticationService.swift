import Foundation
@testable import Rentia

enum MockAuthError: Error {
    case generic
}

final class MockAuthenticationService: AuthenticationService, @unchecked Sendable {
    var shouldThrow = false
    var errorToThrow: Error = MockAuthError.generic
    var signInGoogleCallCount = 0
    var signInAppleCallCount = 0
    var signOutCallCount = 0

    func signInWithGoogle() async throws -> Bool {
        signInGoogleCallCount += 1
        if shouldThrow { throw errorToThrow }
        return true
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> Bool {
        signInAppleCallCount += 1
        if shouldThrow { throw errorToThrow }
        return true
    }

    func signOut() throws {
        signOutCallCount += 1
        if shouldThrow { throw errorToThrow }
    }

    func deleteAccount() async throws {
        if shouldThrow { throw errorToThrow }
    }

    func generateNonce() -> String {
        "fixed-nonce-for-testing"
    }

    func sha256(_ input: String) -> String {
        "hashed-\(input)"
    }
}
