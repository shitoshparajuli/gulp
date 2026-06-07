import Foundation
import Supabase

/// Reads and writes against the `restaurants` table. Restaurants are a shared,
/// append-only resource keyed by the MapKit `place_id`.
struct RestaurantsRepository {
    static let shared = RestaurantsRepository()

    private struct IDOnly: Decodable { let id: UUID }

    private struct NewRestaurant: Encodable {
        let place_id: String
        let name: String
        let latitude: Double
        let longitude: Double
        let address: String?
        let added_by: String
    }

    /// The existing restaurant row id for a MapKit place id, if we've seen it.
    func id(forPlaceID placeID: String) async throws -> UUID? {
        let rows: [IDOnly] = try await supabase
            .from("restaurants")
            .select("id")
            .eq("place_id", value: placeID)
            .execute()
            .value
        return rows.first?.id
    }

    /// Restaurants whose name matches `query` (case-insensitive substring),
    /// alphabetical. `query` is sanitized for the `ilike` pattern via `ilikeEscaped`.
    func search(matching query: String, limit: Int = 15) async throws -> [RestaurantResponse] {
        try await supabase
            .from("restaurants")
            .select("id, name, address")
            .ilike("name", pattern: "%\(query.ilikeEscaped)%")
            .order("name")
            .limit(limit)
            .execute()
            .value
    }

    /// Inserts a restaurant and returns its new id.
    func insert(place: PlaceResult, addedBy userID: UUID) async throws -> UUID {
        let inserted: IDOnly = try await supabase
            .from("restaurants")
            .insert(NewRestaurant(
                place_id: place.id,
                name: place.name,
                latitude: place.latitude,
                longitude: place.longitude,
                address: place.address,
                added_by: userID.uuidString
            ))
            .select("id")
            .single()
            .execute()
            .value
        return inserted.id
    }

    /// Returns the restaurant for this place, creating it if it's new.
    func upsert(place: PlaceResult, addedBy userID: UUID) async throws -> UUID {
        if let existing = try await id(forPlaceID: place.id) { return existing }
        return try await insert(place: place, addedBy: userID)
    }
}
