import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class HomeViewModel {
    var feed: [FeedItem] = []
    var suggestions: [ProfileLite] = []
    var followingIds: Set<UUID> = []
    var isLoading = false
    var errorMessage: String?

    private var currentUserId: UUID?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let userId = try await supabase.auth.session.user.id
            currentUserId = userId

            let follows: [FollowRow] = try await supabase
                .from("follows")
                .select("followee_id")
                .eq("follower_id", value: userId)
                .execute()
                .value
            followingIds = Set(follows.map(\.followeeId))

            if followingIds.isEmpty {
                feed = []
                await loadSuggestions(currentUserId: userId)
                return
            }

            let ratings: [FeedRatingRow] = try await supabase
                .from("ratings")
                .select("id, user_id, score, notes, photo_path, created_at, dishes(id, display_name, cuisine, restaurants(id, name, address))")
                .in("user_id", values: Array(followingIds))
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            let userIds = Array(Set(ratings.map(\.userId)))
            let profiles: [ProfileLite] = userIds.isEmpty ? [] : try await supabase
                .from("profiles")
                .select("id, username, display_name, avatar_url")
                .in("id", values: userIds)
                .execute()
                .value

            let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
            feed = ratings.compactMap { row in
                guard let profile = profileMap[row.userId] else { return nil }
                return FeedItem(rating: row, profile: profile)
            }
            suggestions = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadSuggestions(currentUserId: UUID) async {
        do {
            let pool: [ProfileLite] = try await supabase
                .from("profiles")
                .select("id, username, display_name, avatar_url")
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            suggestions = pool
                .filter { $0.id != currentUserId && !followingIds.contains($0.id) }
                .prefix(8)
                .map { $0 }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func follow(_ profile: ProfileLite) async {
        guard let me = currentUserId else { return }
        let previous = followingIds
        followingIds.insert(profile.id)
        do {
            struct Insert: Encodable {
                let follower_id: UUID
                let followee_id: UUID
            }
            try await supabase
                .from("follows")
                .insert(Insert(follower_id: me, followee_id: profile.id))
                .execute()
            await load()
        } catch {
            followingIds = previous
            errorMessage = error.localizedDescription
        }
    }

    func unfollow(_ profile: ProfileLite) async {
        guard let me = currentUserId else { return }
        let previous = followingIds
        followingIds.remove(profile.id)
        do {
            try await supabase
                .from("follows")
                .delete()
                .eq("follower_id", value: me)
                .eq("followee_id", value: profile.id)
                .execute()
            await load()
        } catch {
            followingIds = previous
            errorMessage = error.localizedDescription
        }
    }
}
