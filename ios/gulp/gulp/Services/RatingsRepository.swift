import Foundation
import Supabase

/// One rating scoped to a single dish (all users), used for community stats
/// and to locate the current user's own rating.
struct DishRatingRow: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let score: Int?
    let notes: String?
    let photoPath: String?
    let createdAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, score, notes
        case userId = "user_id"
        case photoPath = "photo_path"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
}

/// Every read and write against the `ratings` table. The single place that
/// knows the table's column list, the soft-delete contract, and ownership
/// rules — so screens can't drift apart.
struct RatingsRepository {
    static let shared = RatingsRepository()

    /// Rating + its dish + restaurant — the shape `RatingResponse` decodes.
    private static let withContext =
        "id, score, notes, photo_path, created_at, deleted_at, dishes(id, display_name, cuisine, restaurants(id, name, address))"

    private struct NewRating: Encodable {
        let user_id: String
        let dish_id: String
        let score: Int
        let notes: String?
        let photo_path: String?
    }

    private struct RatingUpdate: Encodable {
        let score: Int
        let notes: String?
        let photo_path: String?
        let updated_at: String
    }

    // MARK: - Reads

    /// A user's active ratings, newest first.
    func myRatings(for userID: UUID) async throws -> [RatingResponse] {
        let rows: [RatingResponse] = try await supabase
            .from("ratings")
            .select(Self.withContext)
            .eq("user_id", value: userID)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.filter { $0.deletedAt == nil }
    }

    /// Every rating on a dish (all users), for community stats + "my rating".
    func ratings(forDish dishID: UUID) async throws -> [DishRatingRow] {
        try await supabase
            .from("ratings")
            .select("id, user_id, score, notes, photo_path, created_at, deleted_at")
            .eq("dish_id", value: dishID)
            .execute()
            .value
    }

    /// The user's active rating for a single dish, if any.
    func myActiveRating(forDish dishID: UUID, userID: UUID) async throws -> RatingResponse? {
        let rows: [RatingResponse] = try await supabase
            .from("ratings")
            .select(Self.withContext)
            .eq("user_id", value: userID)
            .eq("dish_id", value: dishID)
            .execute()
            .value
        return rows.first { $0.deletedAt == nil }
    }

    /// Recent ratings from a set of users — the social feed, newest first.
    func feed(fromUsers userIDs: [UUID], limit: Int) async throws -> [FeedRatingRow] {
        guard !userIDs.isEmpty else { return [] }
        return try await supabase
            .from("ratings")
            .select("id, user_id, score, notes, photo_path, created_at, dishes(id, display_name, cuisine, restaurants(id, name, address))")
            .in("user_id", values: userIDs)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Which of `dishIDs` the user has an active rating on.
    func myRatedDishIDs(in dishIDs: [UUID], userID: UUID) async throws -> Set<UUID> {
        guard !dishIDs.isEmpty else { return [] }
        struct Row: Decodable {
            let dishId: UUID
            let deletedAt: Date?
            enum CodingKeys: String, CodingKey {
                case dishId = "dish_id"
                case deletedAt = "deleted_at"
            }
        }
        let rows: [Row] = try await supabase
            .from("ratings")
            .select("dish_id, deleted_at")
            .eq("user_id", value: userID)
            .in("dish_id", values: dishIDs)
            .execute()
            .value
        return Set(rows.filter { $0.deletedAt == nil }.map(\.dishId))
    }

    // MARK: - Writes

    /// Soft-deletes ratings the caller owns, via the `soft_delete_ratings`
    /// SECURITY DEFINER function. Returns the number of rows removed (0 means
    /// nothing matched / not owned).
    @discardableResult
    func softDelete(ids: [UUID]) async throws -> Int {
        guard !ids.isEmpty else { return 0 }
        return try await supabase
            .rpc("soft_delete_ratings", params: ["p_ids": ids])
            .execute()
            .value
    }

    func insert(dishID: UUID, userID: UUID, score: Int, notes: String?, photoPath: String?) async throws {
        try await supabase
            .from("ratings")
            .insert(NewRating(
                user_id: userID.uuidString,
                dish_id: dishID.uuidString,
                score: score,
                notes: notes,
                photo_path: photoPath
            ))
            .execute()
    }

    func update(id: UUID, userID: UUID, score: Int, notes: String?, photoPath: String?) async throws {
        try await supabase
            .from("ratings")
            .update(RatingUpdate(
                score: score,
                notes: notes,
                photo_path: photoPath,
                updated_at: ISO8601DateFormatter().string(from: Date())
            ))
            .eq("id", value: id)
            .eq("user_id", value: userID)
            .execute()
    }
}
