import Foundation
import UIKit
import Observation
import Supabase

struct DishOption: Identifiable, Decodable, Hashable {
    let id: UUID
    let displayName: String
    let cuisine: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case cuisine
    }
}

@MainActor
@Observable
final class AddRatingViewModel {
    private let restaurants = RestaurantsRepository.shared
    private let dishesRepo = DishesRepository.shared
    private let ratings = RatingsRepository.shared

    var pickedRestaurant: PlaceResult?
    var pickedRestaurantId: UUID?
    var existingDishes: [DishOption] = []
    var myRatedDishes: [DishOption] = []
    var otherDishes: [DishOption] = []
    var pickedDish: DishOption?
    var newDishName: String = ""
    var newDishCuisine: String = ""
    var selectedPhoto: UIImage?
    var existingPhotoPath: String?
    var score: Int = 8
    var notes: String = ""
    var isWorking = false
    var errorMessage: String?

    var editingRatingId: UUID?

    var canProceedToScore: Bool {
        pickedDish != nil || !newDishName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isEditing: Bool { editingRatingId != nil }

    // MARK: - Mode setup

    func configureForAddToRestaurant(restaurant: RestaurantResponse) async {
        pickedRestaurantId = restaurant.id
        pickedRestaurant = PlaceResult(
            id: "",
            name: restaurant.name,
            address: restaurant.address,
            latitude: 0,
            longitude: 0
        )
        await loadDishes()
    }

    func configureForEdit(rating: RatingResponse) {
        editingRatingId = rating.id
        score = rating.score ?? 8
        notes = rating.notes ?? ""
        existingPhotoPath = rating.photoPath
        pickedRestaurantId = rating.dish.restaurant.id
        pickedRestaurant = PlaceResult(
            id: "",
            name: rating.dish.restaurant.name,
            address: rating.dish.restaurant.address,
            latitude: 0,
            longitude: 0
        )
        pickedDish = DishOption(
            id: rating.dish.id,
            displayName: rating.dish.displayName,
            cuisine: rating.dish.cuisine
        )
    }

    // MARK: - Restaurant selection (new from scratch)

    func selectRestaurant(_ place: PlaceResult) async {
        pickedRestaurant = place
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let userId = try await Session.currentUserID()
            pickedRestaurantId = try await restaurants.upsert(place: place, addedBy: userId)
            await loadDishes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadDishes() async {
        guard let restaurantId = pickedRestaurantId else { return }
        do {
            let allDishes = try await dishesRepo.dishes(forRestaurant: restaurantId)
            existingDishes = allDishes

            guard !allDishes.isEmpty else {
                myRatedDishes = []
                otherDishes = []
                return
            }

            let userId = try await Session.currentUserID()
            let ratedIds = try await ratings.myRatedDishIDs(in: allDishes.map(\.id), userID: userId)
            myRatedDishes = allDishes.filter { ratedIds.contains($0.id) }
            otherDishes = allDishes.filter { !ratedIds.contains($0.id) }
        } catch {
            if error.isCancellation { return }
            errorMessage = error.localizedDescription
        }
    }

    func selectExistingDish(_ dish: DishOption) async {
        pickedDish = dish
        newDishName = ""
        newDishCuisine = ""
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let userId = try await Session.currentUserID()
            if let existing = try await ratings.myActiveRating(forDish: dish.id, userID: userId) {
                editingRatingId = existing.id
                score = existing.score ?? 8
                notes = existing.notes ?? ""
                existingPhotoPath = existing.photoPath
            } else {
                editingRatingId = nil
                existingPhotoPath = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearDishSelection() {
        pickedDish = nil
        editingRatingId = nil
        existingPhotoPath = nil
    }

    /// Clears everything specific to the dish just rated so the user can rate
    /// another at the same restaurant. The restaurant selection is intentionally
    /// kept. Synchronous so callers can batch it with the navigation pop (no
    /// intermediate frame of the score screen showing reset values); refresh the
    /// dish list separately with `loadDishes()`.
    func clearForNextDish() {
        selectedPhoto = nil
        existingPhotoPath = nil
        pickedDish = nil
        newDishName = ""
        newDishCuisine = ""
        score = 8
        notes = ""
        editingRatingId = nil
        errorMessage = nil
    }

    // MARK: - Save

    func save() async -> Bool {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let userId = try await Session.currentUserID()

            var photoPath: String? = existingPhotoPath
            if let image = selectedPhoto {
                photoPath = try await uploadPhoto(image, userId: userId)
            }

            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanNotes: String? = trimmedNotes.isEmpty ? nil : trimmedNotes

            if let editingId = editingRatingId {
                try await ratings.update(
                    id: editingId,
                    userID: userId,
                    score: score,
                    notes: cleanNotes,
                    photoPath: photoPath
                )
            } else {
                guard let restaurantId = pickedRestaurantId else { return false }

                let dishId: UUID
                if let picked = pickedDish {
                    dishId = picked.id
                } else {
                    let cuisine = newDishCuisine.trimmingCharacters(in: .whitespaces)
                    dishId = try await dishesRepo.insert(
                        restaurantID: restaurantId,
                        displayName: newDishName.trimmingCharacters(in: .whitespaces),
                        cuisine: cuisine.isEmpty ? nil : cuisine,
                        addedBy: userId
                    )
                }

                try await ratings.insert(
                    dishID: dishId,
                    userID: userId,
                    score: score,
                    notes: cleanNotes,
                    photoPath: photoPath
                )
            }

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func uploadPhoto(_ image: UIImage, userId: UUID) async throws -> String {
        // Camera images come in at full sensor resolution (multi-MB). Downscale
        // to a max long edge that's still sharp on any phone screen, then JPEG it.
        let resized = image.downscaled(maxDimension: 1280)
        guard let data = resized.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "Photo", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not encode photo"])
        }
        let filename = "\(UUID().uuidString.lowercased()).jpg"
        let path = "\(userId.uuidString.lowercased())/\(filename)"
        _ = try await supabase.storage
            .from("dish-photos")
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: "image/jpeg", upsert: false)
            )
        return path
    }
}

func scoreLabel(_ score: Int) -> String {
    switch score {
    case 10: return "Best meal of my life"
    case 9:  return "Phenomenal"
    case 8:  return "Really great"
    case 7:  return "Solid, would reorder"
    case 6:  return "Decent"
    case 5:  return "Meh"
    case 4:  return "Disappointing"
    case 3:  return "Not it"
    case 2:  return "Pretty bad"
    case 1:  return "Worst I've had"
    default: return ""
    }
}
