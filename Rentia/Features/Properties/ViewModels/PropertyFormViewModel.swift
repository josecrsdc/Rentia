import FirebaseAuth
import Foundation

@Observable
final class PropertyFormViewModel {
    var name = ""
    var address = ""
    var type: PropertyType = .apartment
    var monthlyRent = ""
    var currency = UserDefaults.standard.string(forKey: "defaultCurrency") ?? "EUR"
    var status: PropertyStatus = .available
    var propertyDescription = ""
    var rooms = "1"
    var bathrooms = "1"
    var area = ""
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var didSave = false

    private let firestoreService = FirestoreService()
    private var editingPropertyId: String?

    var isEditing: Bool {
        editingPropertyId != nil
    }

    var isFormValid: Bool {
        name.isNotEmpty
        && address.isNotEmpty
        && (Double(monthlyRent) ?? 0) > 0
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
                type = property.type
                monthlyRent = String(format: "%.2f", property.monthlyRent)
                currency = property.currency
                status = property.status
                propertyDescription = property.description ?? ""
                rooms = "\(property.rooms)"
                bathrooms = "\(property.bathrooms)"
                normalizeRoomsBathroomsForType()
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
            address: address.trimmed,
            type: type,
            monthlyRent: Double(monthlyRent) ?? 0,
            currency: currency,
            status: status,
            description: propertyDescription.trimmed.isEmpty
                ? nil : propertyDescription.trimmed,
            rooms: type.supportsRoomsBathrooms ? (Int(rooms) ?? 1) : 0,
            bathrooms: type.supportsRoomsBathrooms ? (Int(bathrooms) ?? 1) : 0,
            area: Double(area),
            imageURLs: [],
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
                    _ = try await firestoreService.create(
                        property,
                        in: "properties"
                    )
                }

                didSave = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
