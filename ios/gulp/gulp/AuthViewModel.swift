import Foundation
import UIKit
import Observation
import GoogleSignIn
import Supabase

@MainActor
@Observable
class AuthViewModel {
    var isSignedIn = false
    var username: String = ""
    var errorMessage: String?

    private struct Profile: Decodable {
        let username: String?
    }

    func signInWithGoogle() async {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else { return }

        errorMessage = nil
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else { return }

            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: idToken)
            )

            let profile = try? await supabase
                .from("profiles")
                .select("username")
                .eq("id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value as Profile

            username = profile?.username ?? session.user.email ?? "user"
            isSignedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
            isSignedIn = false
            username = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
