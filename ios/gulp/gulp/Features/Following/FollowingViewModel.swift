import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class FollowingViewModel {
    var profiles: [ProfileLite] = []
    var isLoading = false
    var errorMessage: String?

    private var currentUserId: UUID?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let me = try await supabase.auth.session.user.id
            currentUserId = me

            let follows: [FollowRow] = try await supabase
                .from("follows")
                .select("followee_id")
                .eq("follower_id", value: me)
                .execute()
                .value

            let ids = follows.map(\.followeeId)
            guard !ids.isEmpty else {
                profiles = []
                return
            }

            let rows: [ProfileLite] = try await supabase
                .from("profiles")
                .select("id, username, display_name, avatar_url")
                .in("id", values: ids)
                .execute()
                .value

            profiles = rows.sorted {
                $0.resolvedName.localizedCaseInsensitiveCompare($1.resolvedName) == .orderedAscending
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unfollow(_ profile: ProfileLite) async {
        guard let me = currentUserId else { return }
        let previous = profiles
        profiles.removeAll { $0.id == profile.id }
        do {
            try await supabase
                .from("follows")
                .delete()
                .eq("follower_id", value: me)
                .eq("followee_id", value: profile.id)
                .execute()
        } catch {
            profiles = previous
            errorMessage = error.localizedDescription
        }
    }
}
