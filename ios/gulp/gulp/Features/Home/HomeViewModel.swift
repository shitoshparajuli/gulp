import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var feed: [FeedItem] = []
    var suggestions: [ProfileLite] = []
    var followingIds: Set<UUID> = []
    var isLoading = false
    var errorMessage: String?

    private var currentUserId: UUID?
    private let follows = FollowsRepository.shared
    private let profilesRepo = ProfilesRepository.shared
    private let ratings = RatingsRepository.shared

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let userId = try await Session.currentUserID()
            currentUserId = userId

            followingIds = Set(try await follows.followeeIDs(of: userId))

            if followingIds.isEmpty {
                feed = []
            } else {
                let ratingRows = try await ratings.feed(fromUsers: Array(followingIds), limit: 50)
                let userIds = Array(Set(ratingRows.map(\.userId)))
                let profiles = try await profilesRepo.profiles(ids: userIds)
                let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
                feed = ratingRows.compactMap { row in
                    guard let profile = profileMap[row.userId] else { return nil }
                    return FeedItem(rating: row, profile: profile)
                }
            }

            await loadSuggestions(currentUserId: userId)
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }

    private func loadSuggestions(currentUserId: UUID) async {
        do {
            let pool = try await profilesRepo.recent(limit: 50)
            suggestions = Array(
                pool
                    .filter { $0.id != currentUserId && !followingIds.contains($0.id) }
                    .shuffled()
                    .prefix(5)
            )
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }

    func follow(_ profile: ProfileLite) async {
        guard let me = currentUserId else { return }
        let previous = followingIds
        followingIds.insert(profile.id)
        do {
            try await follows.follow(follower: me, followee: profile.id)
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
            try await follows.unfollow(follower: me, followee: profile.id)
            await load()
        } catch {
            followingIds = previous
            errorMessage = error.localizedDescription
        }
    }
}
