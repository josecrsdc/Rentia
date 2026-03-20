import Testing
@testable import Rentia

@Suite("Address Model")
struct AddressModelTests {
    private let full = Address(
        street: "Calle Mayor 1",
        city: "Madrid",
        state: "Madrid",
        postalCode: "28001",
        country: "España"
    )

    // MARK: - formattedAddress

    @Test func formattedAddressJoinsAllNonEmpty() {
        #expect(full.formattedAddress == "Calle Mayor 1, Madrid, Madrid, 28001, España")
    }

    @Test func formattedAddressSkipsEmptyComponents() {
        let address = Address(street: "Gran Vía", city: "", state: "", postalCode: "", country: "España")
        #expect(address.formattedAddress == "Gran Vía, España")
    }

    // MARK: - formattedShort

    @Test func formattedShortUsesStreetCityCountry() {
        #expect(full.formattedShort == "Calle Mayor 1, Madrid, España")
    }

    @Test func formattedShortSkipsEmptyComponents() {
        let address = Address(street: "", city: "Barcelona", state: "", postalCode: "", country: "España")
        #expect(address.formattedShort == "Barcelona, España")
    }

    // MARK: - hasCoordinates

    @Test func hasCoordinatesFalseWhenBothNil() {
        #expect(full.hasCoordinates == false)
    }

    @Test func hasCoordinatesTrueWhenBothSet() {
        var address = full
        address.latitude = 40.4
        address.longitude = -3.7
        #expect(address.hasCoordinates == true)
    }

    @Test func hasCoordinatesFalseWhenOnlyLatitude() {
        var address = full
        address.latitude = 40.4
        #expect(address.hasCoordinates == false)
    }

    @Test func hasCoordinatesFalseWhenOnlyLongitude() {
        var address = full
        address.longitude = -3.7
        #expect(address.hasCoordinates == false)
    }

    // MARK: - matchesSearch

    @Test func matchesSearchByStreet() {
        #expect(full.matchesSearch("mayor") == true)
    }

    @Test func matchesSearchByCity() {
        #expect(full.matchesSearch("Madrid") == true)
    }

    @Test func matchesSearchByPostalCode() {
        #expect(full.matchesSearch("28001") == true)
    }

    @Test func matchesSearchCaseInsensitive() {
        #expect(full.matchesSearch("ESPAÑA") == true)
    }

    @Test func matchesSearchNoMatch() {
        #expect(full.matchesSearch("Barcelona") == false)
    }

    // MARK: - Address.empty

    @Test func emptyAddressHasEmptyFields() {
        let empty = Address.empty
        #expect(empty.street.isEmpty)
        #expect(empty.city.isEmpty)
        #expect(empty.country.isEmpty)
        #expect(empty.hasCoordinates == false)
    }

    @Test func emptyAddressFormattedIsEmpty() {
        #expect(Address.empty.formattedAddress.isEmpty)
    }
}
