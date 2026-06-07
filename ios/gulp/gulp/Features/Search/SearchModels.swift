import Foundation

/// A dish search result with its community aggregate, ready for the results list.
/// Built from `DishSearchRow` by `SearchViewModel`, navigates into `DishDetailView`.
struct DishSearchResult: Identifiable {
    let id: UUID
    let displayName: String
    let cuisine: String?
    let restaurant: RestaurantResponse
    let communityAvg: Double?
    let communityCount: Int

    func asDishResponse() -> DishResponse {
        DishResponse(
            id: id,
            displayName: displayName,
            cuisine: cuisine,
            restaurant: restaurant
        )
    }
}
