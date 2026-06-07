import Foundation
import Supabase

/// Reads against the `dish_photos` table (the gallery shown on dish detail).
struct DishPhotosRepository {
    static let shared = DishPhotosRepository()

    /// Photos for a dish, newest first.
    func photos(forDish dishID: UUID) async throws -> [DishPhoto] {
        try await supabase
            .from("dish_photos")
            .select("id, photo_path, user_id, created_at")
            .eq("dish_id", value: dishID)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
