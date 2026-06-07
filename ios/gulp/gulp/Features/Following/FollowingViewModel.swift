import Foundation
import Observation

@MainActor
@Observable
final class FollowingViewModel {
    var profiles: [ProfileLite] = []
    var isLoading = false
    var errorMessage: String?

    private var currentUserId: UUID?
    private let follows = FollowsRepository.shared
    private let profilesRepo = ProfilesRepository.shared

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let me = try await Session.currentUserID()
            currentUserId = me

            let ids = try await follows.followeeIDs(of: me)
            guard !ids.isEmpty else {
                profiles = []
                return
            }

            let rows = try await profilesRepo.profiles(ids: ids)
            profiles = rows.sorted {
                $0.resolvedName.localizedCaseInsensitiveCompare($1.resolvedName) == .orderedAscending
            }
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }

    func unfollow(_ profile: ProfileLite) async {
        guard let me = currentUserId else { return }
        let previous = profiles
        profiles.removeAll { $0.id == profile.id }
        do {
            try await follows.unfollow(follower: me, followee: profile.id)
        } catch {
            profiles = previous
            errorMessage = error.localizedDescription
        }
    }
}
