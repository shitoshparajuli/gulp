import SwiftUI
import GoogleSignIn

@main
struct gulpApp: App {
    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    AppRoot(auth: auth)
                } else {
                    LoginView(auth: auth)
                }
            }
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
