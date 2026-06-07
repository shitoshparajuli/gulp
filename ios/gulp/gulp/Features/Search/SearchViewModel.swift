import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var searchText = ""
    var dishResults: [DishSearchResult] = []
    var restaurantResults: [RestaurantResponse] = []
    var isSearching = false
    var errorMessage: String?

    private let dishes = DishesRepository.shared
    private let restaurants = RestaurantsRepository.shared

    /// Whether the trimmed query is long enough to search on.
    var hasQuery: Bool {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    var hasResults: Bool {
        !dishResults.isEmpty || !restaurantResults.isEmpty
    }

    /// Searches dishes and restaurants in parallel. Debounced by the caller's
    /// `.task(id: searchText)`, which cancels the previous run on each keystroke —
    /// the cancellation fires during the sleep below. Short/blank queries clear the
    /// results without hitting the network.
    func search() async {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        // Need ≥2 chars, and they must survive sanitizing — an all-wildcard query
        // (e.g. "%%") would otherwise escape to an empty pattern and match everything.
        guard q.count >= 2, q.ilikeEscaped.count >= 2 else {
            dishResults = []
            restaurantResults = []
            isSearching = false
            return
        }

        do { try await Task.sleep(for: .milliseconds(250)) } catch { return } // debounce

        isSearching = true
        defer { isSearching = false }

        do {
            async let dishRows = dishes.search(matching: q)
            async let restRows = restaurants.search(matching: q)
            let (rows, rests) = try await (dishRows, restRows)
            dishResults = Self.ranked(rows)
            restaurantResults = rests
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Aggregates each row's active ratings into a community average + count, then
    /// orders rated dishes by average (desc, ties broken by count) ahead of unrated
    /// ones — the same ranking `RestaurantDetailViewModel` uses.
    private static func ranked(_ rows: [DishSearchRow]) -> [DishSearchResult] {
        let results = rows.map { row -> DishSearchResult in
            let active = row.ratings.filter { $0.deletedAt == nil }
            let scores = active.compactMap(\.score)
            let avg = scores.isEmpty
                ? nil
                : Double(scores.reduce(0, +)) / Double(scores.count)
            return DishSearchResult(
                id: row.id,
                displayName: row.displayName,
                cuisine: row.cuisine,
                restaurant: row.restaurant,
                communityAvg: avg,
                communityCount: scores.count
            )
        }

        return results.sorted { a, b in
            switch (a.communityAvg, b.communityAvg) {
            case let (lhs?, rhs?):
                if lhs != rhs { return lhs > rhs }
                return a.communityCount > b.communityCount
            case (.some, .none): return true
            case (.none, .some): return false
            case (.none, .none):
                return a.displayName.localizedCaseInsensitiveCompare(b.displayName) == .orderedAscending
            }
        }
    }
}
