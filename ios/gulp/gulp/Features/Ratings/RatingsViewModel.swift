import Foundation
import Observation
import Supabase

@MainActor
@Observable
class RatingsViewModel {
    var groups: [RestaurantGroup] = []
    var isLoading = false
    var errorMessage: String?

    private let ratings = RatingsRepository.shared

    func load(userId targetUserId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let userId: UUID
            if let targetUserId {
                userId = targetUserId
            } else {
                userId = try await Session.currentUserID()
            }

            let rows = try await ratings.myRatings(for: userId)

            var map: [UUID: RestaurantGroup] = [:]
            for row in rows {
                let r = row.dish.restaurant
                if map[r.id] == nil {
                    map[r.id] = RestaurantGroup(restaurant: r, ratings: [])
                }
                map[r.id]!.ratings.append(row)
            }

            groups = map.values.sorted { $0.restaurant.name < $1.restaurant.name }
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }

    func deleteRating(_ rating: RatingResponse) async {
        do {
            let affected = try await ratings.softDelete(ids: [rating.id])
            guard affected > 0 else {
                errorMessage = "Couldn't delete this rating."
                return
            }
            remove(ids: [rating.id])   // optimistic: reflect immediately
            await load()               // reconcile (a cancelled reload is fine)
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }

    func removeRestaurant(_ group: RestaurantGroup) async {
        do {
            let ids = group.ratings.map(\.id)
            let affected = try await ratings.softDelete(ids: ids)
            guard affected > 0 else {
                errorMessage = "Couldn't remove this restaurant."
                return
            }
            remove(ids: ids)
            await load()
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Drops the given ratings from the in-memory groups so the list updates
    /// even if the follow-up reload gets cancelled.
    private func remove(ids: [UUID]) {
        let idSet = Set(ids)
        for index in groups.indices {
            groups[index].ratings.removeAll { idSet.contains($0.id) }
        }
        groups.removeAll { $0.ratings.isEmpty }
    }
}

func dishPhotoURL(path: String) -> URL? {
    URL(string: "https://rheqemyqgahwstphguxn.supabase.co/storage/v1/object/public/dish-photos/\(path)")
}
