import Foundation
import Observation
import Supabase

struct DishAggregate: Identifiable {
    let id: UUID
    let displayName: String
    let cuisine: String?
    let communityAvg: Double?
    let communityCount: Int
    let myScore: Int?

    func asDishResponse(restaurant: RestaurantResponse) -> DishResponse {
        DishResponse(
            id: id,
            displayName: displayName,
            cuisine: cuisine,
            restaurant: restaurant
        )
    }
}

@MainActor
@Observable
final class RestaurantDetailViewModel {
    let restaurant: RestaurantResponse
    var dishes: [DishAggregate] = []
    var isLoading = false
    var errorMessage: String?

    private let dishRepo = DishesRepository.shared

    init(restaurant: RestaurantResponse) {
        self.restaurant = restaurant
    }

    var totalRatings: Int {
        dishes.reduce(0) { $0 + $1.communityCount }
    }

    var ratedDishCount: Int {
        dishes.filter { $0.communityCount > 0 }.count
    }

    /// Dishes the current user has personally rated, best (own score) first.
    var triedDishes: [DishAggregate] {
        dishes
            .filter { $0.myScore != nil }
            .sorted { ($0.myScore ?? 0) > ($1.myScore ?? 0) }
    }

    /// Dishes the current user hasn't rated yet, keeping the community-avg sort.
    var untriedDishes: [DishAggregate] {
        dishes.filter { $0.myScore == nil }
    }

    var restaurantAvg: Double? {
        let weighted = dishes.reduce(into: (sum: 0.0, count: 0)) { acc, dish in
            if let avg = dish.communityAvg {
                acc.sum += avg * Double(dish.communityCount)
                acc.count += dish.communityCount
            }
        }
        return weighted.count == 0 ? nil : weighted.sum / Double(weighted.count)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let me = try await Session.currentUserID()

            let rows = try await dishRepo.dishesWithRatings(forRestaurant: restaurant.id)

            let aggregates = rows.map { dish -> DishAggregate in
                let active = dish.ratings.filter { $0.deletedAt == nil }
                let scores = active.compactMap(\.score)
                let avg = scores.isEmpty
                    ? nil
                    : Double(scores.reduce(0, +)) / Double(scores.count)
                let myScore = active.first { $0.userId == me }?.score
                return DishAggregate(
                    id: dish.id,
                    displayName: dish.displayName,
                    cuisine: dish.cuisine,
                    communityAvg: avg,
                    communityCount: scores.count,
                    myScore: myScore
                )
            }

            dishes = aggregates.sorted { a, b in
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
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }
}
