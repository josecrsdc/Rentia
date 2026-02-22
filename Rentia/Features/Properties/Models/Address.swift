import Foundation

struct Address: Codable, Sendable, Hashable {
    var street: String
    var city: String
    var state: String
    var postalCode: String
    var country: String
    var latitude: Double?
    var longitude: Double?

    static let empty = Self(
        street: "",
        city: "",
        state: "",
        postalCode: "",
        country: ""
    )

    var formattedAddress: String {
        [street, city, state, postalCode, country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var formattedShort: String {
        [street, city, country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    func matchesSearch(_ query: String) -> Bool {
        let lowered = query.lowercased()
        return street.lowercased().contains(lowered)
            || city.lowercased().contains(lowered)
            || state.lowercased().contains(lowered)
            || postalCode.lowercased().contains(lowered)
            || country.lowercased().contains(lowered)
    }
}
