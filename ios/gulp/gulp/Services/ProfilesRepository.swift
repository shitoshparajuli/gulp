import Foundation
import Supabase

/// Reads against the `profiles` table. Profile rows themselves are created by
/// the `handle_new_user` trigger, so there's no insert here.
struct ProfilesRepository {
    static let shared = ProfilesRepository()

    private static let liteColumns = "id, username, display_name, avatar_url"

    /// Profiles for a set of user ids.
    func profiles(ids: [UUID]) async throws -> [ProfileLite] {
        guard !ids.isEmpty else { return [] }
        return try await supabase
            .from("profiles")
            .select(Self.liteColumns)
            .in("id", values: ids)
            .execute()
            .value
    }

    /// Most recently created profiles — used to seed follow suggestions.
    func recent(limit: Int) async throws -> [ProfileLite] {
        try await supabase
            .from("profiles")
            .select(Self.liteColumns)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// The username on a single profile, or nil if it doesn't exist yet.
    func username(for userID: UUID) async throws -> String? {
        struct Row: Decodable { let username: String? }
        let rows: [Row] = try await supabase
            .from("profiles")
            .select("username")
            .eq("id", value: userID)
            .limit(1)
            .execute()
            .value
        return rows.first?.username
    }
}
