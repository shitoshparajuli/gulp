import SwiftUI
import GoogleSignIn

@main
struct gulpApp: App {
    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isInitializing {
                    Color(Theme.background).ignoresSafeArea()
                } else if auth.isSignedIn {
                    AppRoot(auth: auth)
                } else {
                    LoginView(auth: auth)
                }
            }
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .task {
                auth.startSessionListener()
            }
        }
    }
}
