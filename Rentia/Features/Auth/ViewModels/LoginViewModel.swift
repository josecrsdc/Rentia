import AuthenticationServices
import SwiftUI

@Observable
final class LoginViewModel {
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var currentNonce: String?

    private let authService: AuthenticationService

    init(authService: AuthenticationService) {
        self.authService = authService
    }

    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await authService.signInWithGoogle()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func prepareAppleSignIn() -> (nonce: String, hashedNonce: String) {
        let nonce = authService.generateNonce()
        currentNonce = nonce
        let hashedNonce = authService.sha256(nonce)
        return (nonce, hashedNonce)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            guard let nonce = currentNonce else {
                errorMessage = String(localized: "auth.error.internal_authentication")
                showError = true
                isLoading = false
                return
            }

            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = credential.identityToken,
                  let idToken = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = AuthError.missingIDToken.localizedDescription
                showError = true
                isLoading = false
                return
            }

            Task {
                do {
                    _ = try await authService.signInWithApple(
                        idToken: idToken,
                        nonce: nonce
                    )
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                isLoading = false
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
