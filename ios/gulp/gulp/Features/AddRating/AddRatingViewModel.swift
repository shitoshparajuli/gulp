import Foundation
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
}

@MainActor
@Observable
final class AddRatingViewModel {
    var pickedRestaurant: PlaceResult?
    var pickedRestaurantId: UUID?
    var existingDishes: [DishOption] = []
    var pickedDish: DishOption?
    var newDishName: String = ""
    var newDishCuisine: String = ""
    var score: Int = 8
    var notes: String = ""
    var isWorking = false
    var errorMessage: String?

    var canProceedToDish: Bool { pickedRestaurantId != nil }
    var canProceedToScore: Bool {
        pickedDish != nil || !newDishName.trimmingCharacters(in: .whitespaces).isEmpty
    }

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

    private func loadDishes() async {
        guard let restaurantId = pickedRestaurantId else { return }
        do {
            existingDishes = try await supabase
                .from("dishes")
                .select("id, display_name, cuisine")
                .eq("restaurant_id", value: restaurantId)
                .order("display_name")
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async -> Bool {
        guard let restaurantId = pickedRestaurantId else { return false }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let userId = try await supabase.auth.session.user.id

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

            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            try await supabase
                .from("ratings")
                .insert(NewRating(
                    user_id: userId.uuidString,
                    dish_id: dishId.uuidString,
                    score: score,
                    notes: trimmedNotes.isEmpty ? nil : trimmedNotes
                ))
                .execute()

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
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
