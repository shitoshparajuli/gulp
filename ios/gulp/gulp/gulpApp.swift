import SwiftUI
import GoogleSignIn

@main
struct gulpApp: App {
    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    VStack(spacing: 16) {
                        Text("Signed in as \(auth.username)")
                            .font(.headline)
                        Button("Sign Out") {
                            Task { await auth.signOut() }
                        }
                        .foregroundStyle(.red)
                    }
                } else {
                    LoginView(auth: auth)
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
