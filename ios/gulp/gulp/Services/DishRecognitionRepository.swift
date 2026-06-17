import Foundation
import UIKit
import Supabase

/// Suggests likely dish names from a photo by calling the `suggest-dish-names`
/// Supabase Edge Function (which holds the Anthropic key server-side). Stateless,
/// matching the other repositories. Best-effort: the caller treats an empty
/// result or a throw as "no suggestions".
struct DishRecognitionRepository {
    static let shared = DishRecognitionRepository()

    private struct Request: Encodable {
        let image: String
        let restaurantName: String?
        let existingDishNames: [String]?
    }

    private struct Response: Decodable {
        let suggestions: [String]
    }

    func suggestNames(
        image: UIImage,
        restaurantName: String?,
        existingDishNames: [String]
    ) async throws -> [String] {
        // A small image is plenty to identify a dish and keeps the vision call
        // cheap/fast — smaller than the 1280px used when storing the photo.
        let small = image.downscaled(maxDimension: 512)
        guard let data = small.jpegData(compressionQuality: 0.6) else { return [] }

        let body = Request(
            image: data.base64EncodedString(),
            restaurantName: restaurantName,
            existingDishNames: existingDishNames.isEmpty ? nil : existingDishNames
        )

        let response: Response = try await supabase.functions.invoke(
            "suggest-dish-names",
            options: FunctionInvokeOptions(body: body)
        )
        return response.suggestions
    }
}
