import Foundation
import Supabase

/// A dish with every rating inlined — for restaurant-level aggregates.
struct DishWithRatings: Decodable, Identifiable {
    let id: UUID
    let displayName: String
    let cuisine: String?
    let ratings: [Rating]

    struct Rating: Decodable {
        let score: Int?
        let userId: UUID
        let deletedAt: Date?

        enum CodingKeys: String, CodingKey {
            case score
            case userId = "user_id"
            case deletedAt = "deleted_at"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, cuisine, ratings
        case displayName = "display_name"
    }
}

/// A name-matched dish with its restaurant and every rating inlined — the shape
/// global search decodes, then ranks by community average.
struct DishSearchRow: Decodable, Identifiable {
    let id: UUID
    let displayName: String
    let cuisine: String?
    let restaurant: RestaurantResponse
    let ratings: [Rating]

    struct Rating: Decodable {
        let score: Int?
        let deletedAt: Date?

        enum CodingKeys: String, CodingKey {
            case score
            case deletedAt = "deleted_at"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, cuisine, ratings
        case displayName = "display_name"
        case restaurant = "restaurants"
    }
}

/// Reads and writes against the `dishes` table. Dishes are a shared,
/// append-only resource owned by a restaurant.
struct DishesRepository {
    static let shared = DishesRepository()

    private struct IDOnly: Decodable { let id: UUID }

    private struct NewDish: Encodable {
        let restaurant_id: String
        let display_name: String
        let cuisine: String?
        let added_by: String
    }

    /// Dishes at a restaurant (name + cuisine only), alphabetical.
    func dishes(forRestaurant restaurantID: UUID) async throws -> [DishOption] {
        try await supabase
            .from("dishes")
            .select("id, display_name, cuisine")
            .eq("restaurant_id", value: restaurantID)
            .order("display_name")
            .execute()
            .value
    }

    /// Dishes at a restaurant with every rating inlined, for aggregates.
    func dishesWithRatings(forRestaurant restaurantID: UUID) async throws -> [DishWithRatings] {
        try await supabase
            .from("dishes")
            .select("id, display_name, cuisine, ratings(score, user_id, deleted_at)")
            .eq("restaurant_id", value: restaurantID)
            .execute()
            .value
    }

    /// Dishes whose name matches `query` (case-insensitive substring), each with
    /// its restaurant and every rating inlined so the caller can rank by community
    /// average. `query` is sanitized for the `ilike` pattern via `ilikeEscaped`.
    func search(matching query: String, limit: Int = 30) async throws -> [DishSearchRow] {
        try await supabase
            .from("dishes")
            .select("id, display_name, cuisine, restaurants(id, name, address), ratings(score, deleted_at)")
            .ilike("display_name", pattern: "%\(query.ilikeEscaped)%")
            .limit(limit)
            .execute()
            .value
    }

    /// Inserts a dish and returns its new id.
    func insert(restaurantID: UUID, displayName: String, cuisine: String?, addedBy userID: UUID) async throws -> UUID {
        let inserted: IDOnly = try await supabase
            .from("dishes")
            .insert(NewDish(
                restaurant_id: restaurantID.uuidString,
                display_name: displayName,
                cuisine: cuisine,
                added_by: userID.uuidString
            ))
            .select("id")
            .single()
            .execute()
            .value
        return inserted.id
    }
}
