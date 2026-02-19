import AuthenticationServices
import SwiftUI

@Observable
final class LoginViewModel {
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var currentNonce: String?

    private let authService: AuthenticationService
    private let authState: AuthenticationState

    init(authService: AuthenticationService, authState: AuthenticationState) {
        self.authService = authService
        self.authState = authState
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
                errorMessage = String(localized: "auth.error_interno_de_autenticacion")
                showError = true
                isLoading = false
                return
            }

            Task {
                do {
                    _ = try await authService.signInWithApple(
                        authorization: authorization,
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
