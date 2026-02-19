import FirebaseAuth
import Foundation

@Observable
final class TenantListViewModel {
    var tenants: [Tenant] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let firestoreService = FirestoreService()

    var filteredTenants: [Tenant] {
        if searchText.trimmed.isEmpty {
            return tenants
        }
        let query = searchText.lowercased()
        return tenants.filter {
            $0.fullName.lowercased().contains(query)
            || $0.email.lowercased().contains(query)
        }
    }

    func loadTenants() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            do {
                tenants = try await firestoreService.readAll(
                    from: "tenants",
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

    func deleteTenant(_ tenant: Tenant) {
        guard let tenantId = tenant.id else { return }

        Task {
            do {
                try await firestoreService.delete(
                    id: tenantId,
                    from: "tenants"
                )
                tenants.removeAll { $0.id == tenantId }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
