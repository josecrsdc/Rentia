import FirebaseAuth
import Foundation

@Observable
final class PropertyFormViewModel {
    var name = ""
    var address: Address = .empty
    var cadastralReference = ""
    var type: PropertyType = .apartment
    var currency = UserDefaults.standard.string(forKey: "defaultCurrency") ?? "EUR"
    var status: PropertyStatus = .available
    var propertyDescription = ""
    var rooms = "1"
    var bathrooms = "1"
    var area = ""
    var administratorId: String?
    var administrators: [Administrator] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var didSave = false
    var savedId: String?

    private let firestoreService: any FirestoreServiceProtocol
    private var editingPropertyId: String?
    private var existingImageURLs: [String] = []

    init(firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    var isEditing: Bool {
        editingPropertyId != nil
    }

    var isFormValid: Bool {
        name.isNotEmpty
        && address.street.isNotEmpty
    }

    func normalizeRoomsBathroomsForType() {
        if type.supportsRoomsBathrooms {
            if (Int(rooms) ?? 0) <= 0 {
                rooms = "1"
            }
            if (Int(bathrooms) ?? 0) <= 0 {
                bathrooms = "1"
            }
        } else {
            rooms = "0"
            bathrooms = "0"
        }
    }

    func loadProperty(id: String) {
        editingPropertyId = id
        isLoading = true

        Task {
            do {
                let property: Property = try await firestoreService.read(
                    id: id,
                    from: "properties"
                )
                name = property.name
                address = property.address
                cadastralReference = property.cadastralReference ?? ""
                type = property.type
                currency = property.currency
                status = property.status
                propertyDescription = property.description ?? ""
                rooms = "\(property.rooms)"
                bathrooms = "\(property.bathrooms)"
                normalizeRoomsBathroomsForType()
                administratorId = property.administratorId
                existingImageURLs = property.imageURLs
                if let propertyArea = property.area {
                    area = String(format: "%.0f", propertyArea)
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func save() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        let property = Property(
            id: editingPropertyId,
            ownerId: userId,
            name: name.trimmed,
            address: address,
            cadastralReference: cadastralReference.trimmed.isEmpty ? nil : cadastralReference.trimmed,
            type: type,
            currency: currency,
            status: status,
            description: propertyDescription.trimmed.isEmpty
                ? nil : propertyDescription.trimmed,
            rooms: type.supportsRoomsBathrooms ? (Int(rooms) ?? 1) : 0,
            bathrooms: type.supportsRoomsBathrooms ? (Int(bathrooms) ?? 1) : 0,
            area: Double(area),
            administratorId: administratorId,
            imageURLs: existingImageURLs,
            createdAt: Date()
        )

        Task {
            do {
                if let propertyId = editingPropertyId {
                    try await firestoreService.update(
                        property,
                        id: propertyId,
                        in: "properties"
                    )
                } else {
                    let docId = try await firestoreService.create(
                        property,
                        in: "properties"
                    )
                    savedId = docId
                }

                didSave = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func delete(propertyId: String) {
        let userId = Auth.auth().currentUser?.uid ?? ""
        isLoading = true

        Task {
            do {
                let activeLeases: [Lease] = try await firestoreService.readAll(
                    from: "leases",
                    whereField: "propertyId",
                    isEqualTo: propertyId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )

                let hasActiveLease = activeLeases.contains { $0.status == .active }
                if hasActiveLease {
                    errorMessage = String(localized: "properties.error.delete_has_active_lease")
                    showError = true
                    isLoading = false
                    return
                }

                try await firestoreService.delete(id: propertyId, from: "properties")
                didSave = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func loadAdministrators() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            administrators = (
                try? await firestoreService.readAll(
                    from: "administrators",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []
        }
    }
}
