import SwiftUI
import GoogleSignIn

@main
struct gulpApp: App {
    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    TabView {
                        RatingsView()
                            .tabItem { Label("Ratings", systemImage: "star.fill") }
                        ProfileView(auth: auth)
                            .tabItem { Label("Profile", systemImage: "person.fill") }
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
