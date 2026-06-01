import Foundation
import MapKit
import Observation

struct PlaceResult: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
}

@MainActor
@Observable
final class RestaurantSearchService {
    var suggestions: [SearchSuggestion] = []

    private let coordinator = SearchCoordinator()

    init() {
        coordinator.onUpdate = { [weak self] results in
            self?.suggestions = results.map(SearchSuggestion.init)
        }
    }

    func update(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            coordinator.completer.cancel()
            return
        }
        coordinator.completer.queryFragment = trimmed
    }

    func resolve(_ suggestion: SearchSuggestion) async throws -> PlaceResult {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        guard let item = response.mapItems.first else {
            throw SearchError.notFound
        }

        let coord = item.placemark.coordinate
        let name = item.name ?? suggestion.title
        let address = composeAddress(from: item.placemark) ?? suggestion.subtitle

        let placeId = item.identifier?.rawValue ?? "\(name)|\(coord.latitude)|\(coord.longitude)"

        return PlaceResult(
            id: placeId,
            name: name,
            address: address.isEmpty ? nil : address,
            latitude: coord.latitude,
            longitude: coord.longitude
        )
    }

    private func composeAddress(from placemark: MKPlacemark) -> String? {
        let parts = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

enum SearchError: Error {
    case notFound
}

struct SearchSuggestion: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let completion: MKLocalSearchCompletion

    init(_ completion: MKLocalSearchCompletion) {
        self.title = completion.title
        self.subtitle = completion.subtitle
        self.completion = completion
    }

    static func == (lhs: SearchSuggestion, rhs: SearchSuggestion) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class SearchCoordinator: NSObject, MKLocalSearchCompleterDelegate {
    let completer = MKLocalSearchCompleter()
    var onUpdate: (([MKLocalSearchCompletion]) -> Void)?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .pointOfInterest
        completer.pointOfInterestFilter = MKPointOfInterestFilter(
            including: [.restaurant, .cafe, .bakery, .nightlife, .brewery, .winery]
        )
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate?(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onUpdate?([])
    }
}
