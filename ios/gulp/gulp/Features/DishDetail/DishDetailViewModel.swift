import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class DishDetailViewModel {
    let dish: DishResponse
    var myRating: RatingResponse?
    var photos: [DishPhoto] = []
    var communityAvg: Double?
    var communityCount: Int = 0
    var isLoading = false
    var errorMessage: String?

    init(dish: DishResponse) {
        self.dish = dish
    }

    private struct Row: Decodable {
        let id: UUID
        let userId: UUID
        let score: Int?
        let notes: String?
        let photoPath: String?
        let createdAt: Date
        let deletedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, score, notes
            case userId = "user_id"
            case photoPath = "photo_path"
            case createdAt = "created_at"
            case deletedAt = "deleted_at"
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let me = try await supabase.auth.session.user.id

            let rows: [Row] = try await supabase
                .from("ratings")
                .select("id, user_id, score, notes, photo_path, created_at, deleted_at")
                .eq("dish_id", value: dish.id)
                .execute()
                .value

            photos = try await supabase
                .from("dish_photos")
                .select("id, photo_path, user_id, created_at")
                .eq("dish_id", value: dish.id)
                .order("created_at", ascending: false)
                .execute()
                .value

            let active = rows.filter { $0.deletedAt == nil }
            let scores = active.compactMap(\.score)
            communityCount = scores.count
            communityAvg = scores.isEmpty
                ? nil
                : Double(scores.reduce(0, +)) / Double(scores.count)

            if let mine = active.first(where: { $0.userId == me }) {
                myRating = RatingResponse(
                    id: mine.id,
                    score: mine.score,
                    notes: mine.notes,
                    photoPath: mine.photoPath,
                    createdAt: mine.createdAt,
                    deletedAt: nil,
                    dish: dish
                )
            } else {
                myRating = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
