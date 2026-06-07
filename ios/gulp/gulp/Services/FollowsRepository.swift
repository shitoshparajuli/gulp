import Foundation
import Supabase

/// Reads and writes against the `follows` table (the social graph).
struct FollowsRepository {
    static let shared = FollowsRepository()

    private struct FolloweeRow: Decodable {
        let followeeId: UUID
        enum CodingKeys: String, CodingKey { case followeeId = "followee_id" }
    }

    private struct Edge: Encodable {
        let follower_id: UUID
        let followee_id: UUID
    }

    /// Ids of everyone `userID` follows.
    func followeeIDs(of userID: UUID) async throws -> [UUID] {
        let rows: [FolloweeRow] = try await supabase
            .from("follows")
            .select("followee_id")
            .eq("follower_id", value: userID)
            .execute()
            .value
        return rows.map(\.followeeId)
    }

    /// Whether `follower` currently follows `followee`.
    func isFollowing(follower: UUID, followee: UUID) async throws -> Bool {
        let rows: [FolloweeRow] = try await supabase
            .from("follows")
            .select("followee_id")
            .eq("follower_id", value: follower)
            .eq("followee_id", value: followee)
            .execute()
            .value
        return !rows.isEmpty
    }

    func follow(follower: UUID, followee: UUID) async throws {
        try await supabase
            .from("follows")
            .insert(Edge(follower_id: follower, followee_id: followee))
            .execute()
    }

    func unfollow(follower: UUID, followee: UUID) async throws {
        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: follower)
            .eq("followee_id", value: followee)
            .execute()
    }
}
