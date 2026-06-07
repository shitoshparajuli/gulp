import Foundation
import Observation

@MainActor
@Observable
final class UserProfileViewModel {
    var isFollowing = false
    var didLoad = false
    var errorMessage: String?

    private var currentUserId: UUID?
    let profile: ProfileLite
    private let follows = FollowsRepository.shared

    init(profile: ProfileLite) {
        self.profile = profile
    }

    func load() async {
        do {
            let me = try await Session.currentUserID()
            currentUserId = me

            if me == profile.id {
                isFollowing = false
                didLoad = true
                return
            }

            isFollowing = try await follows.isFollowing(follower: me, followee: profile.id)
            didLoad = true
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }

    func toggleFollow() async {
        guard let me = currentUserId, me != profile.id else { return }
        let wasFollowing = isFollowing
        isFollowing.toggle()
        do {
            if wasFollowing {
                try await follows.unfollow(follower: me, followee: profile.id)
            } else {
                try await follows.follow(follower: me, followee: profile.id)
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
