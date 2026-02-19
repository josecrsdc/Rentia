import FirebaseAuth

@Observable
final class AuthenticationState {
    var isAuthenticated = false
    var currentUser: User?
    var isLoading = true

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    func startListening() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
            self?.isLoading = false
        }
    }

    func stopListening() {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateHandle = nil
        }
    }
}
