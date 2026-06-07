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

            let fetchedUsername = try? await ProfilesRepository.shared.username(for: session.user.id)
            username = (fetchedUsername ?? nil) ?? session.user.email ?? "user"
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
