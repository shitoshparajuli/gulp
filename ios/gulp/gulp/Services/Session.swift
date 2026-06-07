import Foundation
import Supabase

/// Thin convenience around the current auth session so view models and
/// repositories don't each reach into `supabase.auth` directly.
enum Session {
    /// The signed-in user's id. Throws if there is no active session.
    static func currentUserID() async throws -> UUID {
        try await supabase.auth.session.user.id
    }
}
