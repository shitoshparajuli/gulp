import Foundation

struct FeedRatingRow: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let score: Int?
    let notes: String?
    let photoPath: String?
    let createdAt: Date
    let dish: DishResponse

    enum CodingKeys: String, CodingKey {
        case id, score, notes
        case userId = "user_id"
        case photoPath = "photo_path"
        case createdAt = "created_at"
        case dish = "dishes"
    }
}

struct ProfileLite: Decodable, Identifiable, Hashable {
    let id: UUID
    let username: String
    let displayName: String?
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarURL = "avatar_url"
    }

    var resolvedName: String { displayName?.isEmpty == false ? displayName! : username }
}

struct FeedItem: Identifiable {
    let rating: FeedRatingRow
    let profile: ProfileLite

    var id: UUID { rating.id }
}

struct FollowRow: Decodable {
    let followeeId: UUID

    enum CodingKeys: String, CodingKey {
        case followeeId = "followee_id"
    }
}
