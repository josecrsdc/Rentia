import MapKit

@Observable
final class AddressSearchViewModel: NSObject, MKLocalSearchCompleterDelegate {
    var results: [MKLocalSearchCompletion] = []
    var isSearching = false

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.resultTypes = .address
        completer.delegate = self
    }

    func updateQuery(_ query: String) {
        guard !query.isEmpty else {
            results = []
            isSearching = false
            return
        }
        isSearching = true
        completer.queryFragment = query
    }

    func selectCompletion(_ completion: MKLocalSearchCompletion) async -> Address? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            guard let placemark = response.mapItems.first?.placemark else { return nil }

            return Address(
                street: [placemark.subThoroughfare, placemark.thoroughfare]
                    .compactMap { $0 }
                    .joined(separator: " "),
                city: placemark.locality ?? "",
                state: placemark.administrativeArea ?? "",
                postalCode: placemark.postalCode ?? "",
                country: placemark.country ?? "",
                latitude: placemark.coordinate.latitude,
                longitude: placemark.coordinate.longitude
            )
        } catch {
            return nil
        }
    }

    // MARK: - MKLocalSearchCompleterDelegate

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let completions = completer.results
        Task { @MainActor in
            results = completions
            isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            results = []
            isSearching = false
        }
    }
}
