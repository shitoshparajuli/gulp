import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class UserProfileViewModel {
    var isFollowing = false
    var didLoad = false
    var errorMessage: String?

    private var currentUserId: UUID?
    let profile: ProfileLite

    init(profile: ProfileLite) {
        self.profile = profile
    }

    func load() async {
        do {
            let me = try await supabase.auth.session.user.id
            currentUserId = me

            if me == profile.id {
                isFollowing = false
                didLoad = true
                return
            }

            let rows: [FollowRow] = try await supabase
                .from("follows")
                .select("followee_id")
                .eq("follower_id", value: me)
                .eq("followee_id", value: profile.id)
                .execute()
                .value
            isFollowing = !rows.isEmpty
            didLoad = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFollow() async {
        guard let me = currentUserId, me != profile.id else { return }
        let wasFollowing = isFollowing
        isFollowing.toggle()
        do {
            if wasFollowing {
                try await supabase
                    .from("follows")
                    .delete()
                    .eq("follower_id", value: me)
                    .eq("followee_id", value: profile.id)
                    .execute()
            } else {
                struct Insert: Encodable {
                    let follower_id: UUID
                    let followee_id: UUID
                }
                try await supabase
                    .from("follows")
                    .insert(Insert(follower_id: me, followee_id: profile.id))
                    .execute()
            }
        } catch {
            isFollowing = wasFollowing
            errorMessage = error.localizedDescription
        }
    }

    var isOwnProfile: Bool {
        guard let me = currentUserId else { return false }
        return me == profile.id
    }
}
