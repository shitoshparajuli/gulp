import Foundation
import Observation
import Supabase

@MainActor
@Observable
class RatingsViewModel {
    var groups: [RestaurantGroup] = []
    var isLoading = false
    var errorMessage: String?

    func load(userId targetUserId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let userId: UUID
            if let targetUserId {
                userId = targetUserId
            } else {
                userId = try await supabase.auth.session.user.id
            }

            let rows: [RatingResponse] = try await supabase
                .from("ratings")
                .select("id, score, notes, photo_path, created_at, deleted_at, dishes(id, display_name, cuisine, restaurants(id, name, address))")
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            var map: [UUID: RestaurantGroup] = [:]
            for row in rows where row.deletedAt == nil {
                let r = row.dish.restaurant
                if map[r.id] == nil {
                    map[r.id] = RestaurantGroup(restaurant: r, ratings: [])
                }
                map[r.id]!.ratings.append(row)
            }

            groups = map.values.sorted { $0.restaurant.name < $1.restaurant.name }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteRating(_ rating: RatingResponse) async {
        do {
            let userId = try await supabase.auth.session.user.id
            try await supabase
                .from("ratings")
                .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: rating.id)
                .eq("user_id", value: userId)
                .execute()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeRestaurant(_ group: RestaurantGroup) async {
        do {
            let userId = try await supabase.auth.session.user.id
            let ratingIds = group.ratings.map(\.id)
            try await supabase
                .from("ratings")
                .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
                .in("id", values: ratingIds)
                .eq("user_id", value: userId)
                .execute()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

func dishPhotoURL(path: String) -> URL? {
    URL(string: "https://rheqemyqgahwstphguxn.supabase.co/storage/v1/object/public/dish-photos/\(path)")
}
