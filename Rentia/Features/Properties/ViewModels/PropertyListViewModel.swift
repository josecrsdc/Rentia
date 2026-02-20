import FirebaseAuth
import Foundation

@Observable
final class PropertyListViewModel {
    var properties: [Property] = []
    var leases: [Lease] = []
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

    func isRented(_ property: Property) -> Bool {
        guard let propertyId = property.id else { return false }
        return leases.contains {
            $0.propertyId == propertyId && $0.status == .active
        }
    }

    func loadProperties() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            do {
                async let propertiesResult: [Property] = firestoreService.readAll(
                    from: "properties",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                async let leasesResult: [Lease] = firestoreService.readAll(
                    from: "leases",
                    whereField: "ownerId",
                    isEqualTo: userId
                )

                properties = try await propertiesResult
                leases = try await leasesResult
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
