import AuthenticationServices
import CryptoKit
import FirebaseAuth
import GoogleSignIn
import UIKit

// MARK: - Protocol

protocol AuthenticationService: Sendable {
    func signInWithGoogle() async throws -> AuthDataResult
    func signInWithApple(
        authorization: ASAuthorization,
        nonce: String
    ) async throws -> AuthDataResult
    func signOut() throws
    func deleteAccount() async throws
    func generateNonce() -> String
    func sha256(_ input: String) -> String
}

// MARK: - Firebase Implementation

final class FirebaseAuthService: AuthenticationService {
    nonisolated func signInWithGoogle() async throws -> AuthDataResult {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw AuthError.missingRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingIDToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        return try await Auth.auth().signIn(with: credential)
    }

    nonisolated func signInWithApple(
        authorization: ASAuthorization,
        nonce: String
    ) async throws -> AuthDataResult {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.missingIDToken
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        return try await Auth.auth().signIn(with: credential)
    }

    nonisolated func signOut() throws {
        try Auth.auth().signOut()
    }

    nonisolated func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }
        try await user.delete()
    }

    nonisolated func generateNonce() -> String {
        let length = 32
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce.")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    nonisolated func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case missingRootViewController
    case missingIDToken
    case noCurrentUser

    var errorDescription: String? {
        switch self {
        case .missingRootViewController:
            String(localized: "No se pudo encontrar la ventana principal.")
        case .missingIDToken:
            String(localized: "No se pudo obtener el token de autenticacion.")
        case .noCurrentUser:
            String(localized: "No hay usuario autenticado.")
        }
    }
}
