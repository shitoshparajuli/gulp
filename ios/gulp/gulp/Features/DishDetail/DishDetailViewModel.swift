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

    private let ratings = RatingsRepository.shared
    private let dishPhotos = DishPhotosRepository.shared

    init(dish: DishResponse) {
        self.dish = dish
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let me = try await Session.currentUserID()

            let rows = try await ratings.ratings(forDish: dish.id)
            photos = try await dishPhotos.photos(forDish: dish.id)

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
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }

    func deleteRating() async {
        guard let rating = myRating else { return }
        do {
            let affected = try await ratings.softDelete(ids: [rating.id])
            guard affected > 0 else {
                errorMessage = "Couldn't delete this rating."
                return
            }
            myRating = nil   // optimistic: flip to the unrated state immediately
            await load()
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }
}
