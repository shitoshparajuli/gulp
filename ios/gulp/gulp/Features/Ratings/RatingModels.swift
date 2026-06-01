import Foundation

struct RatingResponse: Decodable, Identifiable {
    let id: UUID
    let score: Int?
    let notes: String?
    let photoPath: String?
    let createdAt: Date
    let deletedAt: Date?
    let dish: DishResponse

    enum CodingKeys: String, CodingKey {
        case id, score, notes
        case photoPath = "photo_path"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case dish = "dishes"
    }
}

struct DishResponse: Decodable, Identifiable {
    let id: UUID
    let displayName: String
    let cuisine: String?
    let restaurant: RestaurantResponse

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case cuisine
        case restaurant = "restaurants"
    }
}

struct RestaurantResponse: Decodable, Identifiable {
    let id: UUID
    let name: String
    let address: String?
}

struct RestaurantGroup: Identifiable {
    let restaurant: RestaurantResponse
    var ratings: [RatingResponse]
    var id: UUID { restaurant.id }

    var averageScore: Double? {
        let scores = ratings.compactMap(\.score)
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
}
