import FirebaseAuth
import Foundation

@Observable
final class AdministratorListViewModel {
    var administrators: [Administrator] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let firestoreService = FirestoreService()

    var filteredAdministrators: [Administrator] {
        if searchText.trimmed.isEmpty {
            return administrators
        }
        let query = searchText.lowercased()
        return administrators.filter {
            $0.name.lowercased().contains(query)
            || $0.email.lowercased().contains(query)
        }
    }

    func loadAdministrators() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            do {
                administrators = try await firestoreService.readAll(
                    from: "administrators",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
