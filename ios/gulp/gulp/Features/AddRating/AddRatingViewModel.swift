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

private struct IDOnly: Decodable { let id: UUID }

private struct NewRestaurant: Encodable {
    let place_id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let added_by: String
}

private struct NewDish: Encodable {
    let restaurant_id: String
    let display_name: String
    let cuisine: String?
    let added_by: String
}

private struct NewRating: Encodable {
    let user_id: String
    let dish_id: String
    let score: Int
    let notes: String?
    let photo_path: String?
}

private struct RatingUpdate: Encodable {
    let score: Int
    let notes: String?
    let photo_path: String?
    let updated_at: String
}

@MainActor
@Observable
final class AddRatingViewModel {
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
            let userId = try await supabase.auth.session.user.id

            let existing: [IDOnly] = try await supabase
                .from("restaurants")
                .select("id")
                .eq("place_id", value: place.id)
                .execute()
                .value

            if let first = existing.first {
                pickedRestaurantId = first.id
            } else {
                let inserted: IDOnly = try await supabase
                    .from("restaurants")
                    .insert(NewRestaurant(
                        place_id: place.id,
                        name: place.name,
                        latitude: place.latitude,
                        longitude: place.longitude,
                        address: place.address,
                        added_by: userId.uuidString
                    ))
                    .select("id")
                    .single()
                    .execute()
                    .value
                pickedRestaurantId = inserted.id
            }

            await loadDishes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadDishes() async {
        guard let restaurantId = pickedRestaurantId else { return }
        do {
            let allDishes: [DishOption] = try await supabase
                .from("dishes")
                .select("id, display_name, cuisine")
                .eq("restaurant_id", value: restaurantId)
                .order("display_name")
                .execute()
                .value

            existingDishes = allDishes

            guard !allDishes.isEmpty else {
                myRatedDishes = []
                otherDishes = []
                return
            }

            let userId = try await supabase.auth.session.user.id
            let dishIds = allDishes.map(\.id)

            struct RatedRow: Decodable {
                let dishId: UUID
                enum CodingKeys: String, CodingKey { case dishId = "dish_id" }
            }
            let mine: [RatedRow] = try await supabase
                .from("ratings")
                .select("dish_id")
                .eq("user_id", value: userId)
                .in("dish_id", values: dishIds)
                .execute()
                .value

            let ratedIds = Set(mine.map(\.dishId))
            myRatedDishes = allDishes.filter { ratedIds.contains($0.id) }
            otherDishes = allDishes.filter { !ratedIds.contains($0.id) }
        } catch {
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
            let userId = try await supabase.auth.session.user.id
            let rows: [RatingResponse] = try await supabase
                .from("ratings")
                .select("id, score, notes, photo_path, created_at, deleted_at, dishes(id, display_name, cuisine, restaurants(id, name, address))")
                .eq("user_id", value: userId)
                .eq("dish_id", value: dish.id)
                .execute()
                .value

            if let existing = rows.first(where: { $0.deletedAt == nil }) {
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

    // MARK: - Save

    func save() async -> Bool {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let userId = try await supabase.auth.session.user.id

            var photoPath: String? = existingPhotoPath
            if let image = selectedPhoto {
                photoPath = try await uploadPhoto(image, userId: userId)
            }

            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanNotes: String? = trimmedNotes.isEmpty ? nil : trimmedNotes

            if let editingId = editingRatingId {
                try await supabase
                    .from("ratings")
                    .update(RatingUpdate(
                        score: score,
                        notes: cleanNotes,
                        photo_path: photoPath,
                        updated_at: ISO8601DateFormatter().string(from: Date())
                    ))
                    .eq("id", value: editingId)
                    .eq("user_id", value: userId)
                    .execute()
            } else {
                guard let restaurantId = pickedRestaurantId else { return false }

                let dishId: UUID
                if let picked = pickedDish {
                    dishId = picked.id
                } else {
                    let cuisine = newDishCuisine.trimmingCharacters(in: .whitespaces)
                    let inserted: IDOnly = try await supabase
                        .from("dishes")
                        .insert(NewDish(
                            restaurant_id: restaurantId.uuidString,
                            display_name: newDishName.trimmingCharacters(in: .whitespaces),
                            cuisine: cuisine.isEmpty ? nil : cuisine,
                            added_by: userId.uuidString
                        ))
                        .select("id")
                        .single()
                        .execute()
                        .value
                    dishId = inserted.id
                }

                try await supabase
                    .from("ratings")
                    .insert(NewRating(
                        user_id: userId.uuidString,
                        dish_id: dishId.uuidString,
                        score: score,
                        notes: cleanNotes,
                        photo_path: photoPath
                    ))
                    .execute()
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
