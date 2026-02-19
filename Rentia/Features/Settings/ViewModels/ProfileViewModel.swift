import FirebaseAuth
import Foundation

@Observable
final class ProfileViewModel {
    var userProfile: UserProfile?
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var showSignOutConfirmation = false
    var showDeleteConfirmation = false

    private let authService: AuthenticationService
    private let firestoreService = FirestoreService()

    init(authService: AuthenticationService) {
        self.authService = authService
    }

    var displayName: String {
        userProfile?.displayName
            ?? Auth.auth().currentUser?.displayName
            ?? String(localized: "settings.user.fallback_name")
    }

    var email: String {
        userProfile?.email
            ?? Auth.auth().currentUser?.email
            ?? ""
    }

    var photoURL: String? {
        userProfile?.photoURL
            ?? Auth.auth().currentUser?.photoURL?.absoluteString
    }

    func loadProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            do {
                userProfile = try await firestoreService.read(
                    id: userId,
                    from: "users"
                )
            } catch {
                // Profile may not exist yet
            }
            isLoading = false
        }
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func deleteAccount() {
        isLoading = true

        Task {
            do {
                if let userId = Auth.auth().currentUser?.uid {
                    try await firestoreService.delete(
                        id: userId,
                        from: "users"
                    )
                }
                try await authService.deleteAccount()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
