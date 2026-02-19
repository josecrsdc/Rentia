import FirebaseAuth
import Foundation

@Observable
final class PropertyListViewModel {
    var properties: [Property] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let firestoreService = FirestoreService()

    var filteredProperties: [Property] {
        if searchText.trimmed.isEmpty {
            return properties
        }
        let query = searchText.lowercased()
        return properties.filter {
            $0.name.lowercased().contains(query)
            || $0.address.lowercased().contains(query)
        }
    }

    func loadProperties() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            do {
                properties = try await firestoreService.readAll(
                    from: "properties",
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

    func deleteProperty(_ property: Property) {
        guard let propertyId = property.id else { return }

        Task {
            do {
                try await firestoreService.delete(
                    id: propertyId,
                    from: "properties"
                )
                properties.removeAll { $0.id == propertyId }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
